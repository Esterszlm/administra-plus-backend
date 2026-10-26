from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from database import SessionLocal
from models import utc_now_naive
import models, schemas, auth

router = APIRouter(prefix="/users")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def validate_role(role: str):
    value = role.strip().lower()
    if value not in ("admin", "viewer"):
        raise HTTPException(status_code=400, detail="Role inválida. Use 'admin' ou 'viewer'")
    return value


def find_user(db: Session, user_id: int):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return user


def get_organization_name(db: Session, organization_id: int | None):
    if organization_id is None:
        return None
    org = db.query(models.Organization).filter(
        models.Organization.id == organization_id
    ).first()
    if org is None:
        raise HTTPException(status_code=404, detail="Organização não encontrada")
    return org.name


def count_active_admins(db: Session):
    return db.query(models.User).filter(
        models.User.role == "admin", models.User.is_active.is_(True)
    ).count()


def serialize_user(db: Session, user: models.User):
    org = (
        db.query(models.Organization)
        .filter(models.Organization.id == user.organization_id).first()
        if user.organization_id is not None else None
    )
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "role": user.role,
        "organization_id": user.organization_id,
        "organization_name": org.name if org else None,
        "is_active": bool(user.is_active),
        "created_at": user.created_at,
        "deactivated_at": user.deactivated_at,
        "deactivation_reason": user.deactivation_reason,
    }


@router.post("/", response_model=schemas.UserResponse)
def create_user(
    user: schemas.UserCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_create")),
):
    email = user.email.strip().lower()
    if not user.name.strip() or not email or not user.password:
        raise HTTPException(status_code=400, detail="Nome, e-mail e senha são obrigatórios")
    if db.query(models.User).filter(models.User.email == email).first():
        raise HTTPException(status_code=400, detail="E-mail já cadastrado")
    role = validate_role(user.role)
    # Permissão users_create não autoriza promover ninguém a administrador.
    if current_user.role != "admin":
        if role != "viewer":
            raise HTTPException(status_code=403, detail="Somente administradores criam administradores")
        if current_user.organization_id is None or user.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Organização não autorizada")
    get_organization_name(db, user.organization_id)
    db_user = models.User(
        name=user.name.strip(),
        email=email,
        password=auth.hash_password(user.password),
        organization_id=user.organization_id,
        role=role,
        is_active=True,
        created_at=utc_now_naive(),
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return serialize_user(db, db_user)


@router.get("/", response_model=list[schemas.UserResponse])
def list_users(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_view")),
):
    query = db.query(models.User)
    if current_user.role != "admin":
        # Não expor todos os usuários de outras organizações.
        if current_user.organization_id is None:
            query = query.filter(models.User.id == current_user.id)
        else:
            query = query.filter(models.User.organization_id == current_user.organization_id)
    return [serialize_user(db, user) for user in query.order_by(models.User.id).all()]


@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        models.User.email == form_data.username.strip().lower()
    ).first()
    if not user or not auth.verify_password(form_data.password, user.password):
        raise HTTPException(status_code=401, detail="Credenciais inválidas")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Conta desativada. Contate o administrador")
    return {"access_token": auth.create_token({"user_id": user.id}), "token_type": "bearer"}


@router.put("/{user_id}", response_model=schemas.UserResponse)
def update_user(
    user_id: int,
    user_data: schemas.UserUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_edit")),
):
    user = find_user(db, user_id)
    email = user_data.email.strip().lower()
    if not user_data.name.strip() or not email:
        raise HTTPException(status_code=400, detail="Nome e e-mail são obrigatórios")
    if db.query(models.User).filter(
        models.User.email == email, models.User.id != user_id
    ).first():
        raise HTTPException(status_code=400, detail="E-mail já está em uso")

    new_role = validate_role(user_data.role)
    if current_user.role != "admin":
        # Impede elevação de privilégio por quem possui users_edit.
        if user.role != "viewer" or new_role != "viewer":
            raise HTTPException(status_code=403, detail="Somente administradores alteram perfis administrativos")
        if (current_user.organization_id is None
                or user.organization_id != current_user.organization_id
                or user_data.organization_id != current_user.organization_id):
            raise HTTPException(status_code=403, detail="Organização não autorizada")
    if user.is_active and user.role == "admin" and new_role != "admin":
        if count_active_admins(db) <= 1:
            raise HTTPException(status_code=400, detail="Não é possível remover o último administrador ativo")

    if user.organization_id != user_data.organization_id:
        if db.query(models.Finance).filter(models.Finance.user_id == user_id).first():
            raise HTTPException(status_code=400, detail="Usuário com financeiro vinculado não pode mudar de organização")

    get_organization_name(db, user_data.organization_id)
    user.name = user_data.name.strip()
    user.email = email
    user.role = new_role
    user.organization_id = user_data.organization_id
    db.commit()
    db.refresh(user)
    return serialize_user(db, user)


@router.patch("/{user_id}/deactivate", response_model=schemas.UserResponse)
def deactivate_user(
    user_id: int,
    data: schemas.UserDeactivationRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_edit")),
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Somente administradores podem ativar ou desativar usuários")
    user = find_user(db, user_id)
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Você não pode desativar a própria conta")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Usuário já está desativado")
    reason = data.reason.strip()
    if len(reason) < 3:
        raise HTTPException(status_code=400, detail="Informe um motivo com pelo menos 3 caracteres")
    if user.role == "admin" and count_active_admins(db) <= 1:
        raise HTTPException(status_code=400, detail="Não é possível desativar o último administrador ativo")

    user.is_active = False
    user.deactivated_at = utc_now_naive()
    user.deactivation_reason = reason
    db.commit()
    db.refresh(user)
    return serialize_user(db, user)


@router.patch("/{user_id}/reactivate", response_model=schemas.UserResponse)
def reactivate_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_edit")),
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Somente administradores podem ativar ou desativar usuários")
    user = find_user(db, user_id)
    if user.is_active:
        raise HTTPException(status_code=400, detail="Usuário já está ativo")
    user.is_active = True
    # Mantemos a última data e motivo de desativação, mesmo após reativação,
    # para não apagar as informações históricas. Para múltiplos ciclos seria
    # necessária uma tabela separada de histórico de status.
    db.commit()
    db.refresh(user)
    return serialize_user(db, user)


@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_delete")),
):
    # Exclusão física desabilitada por decisão de preservação do histórico.
    find_user(db, user_id)
    raise HTTPException(
        status_code=409,
        detail="Exclusão definitiva desabilitada. Utilize a desativação para preservar o histórico.",
    )
