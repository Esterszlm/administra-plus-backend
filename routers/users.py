from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models, schemas, auth
from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter(prefix="/users")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def validate_role(role: str):
    normalized_role = role.strip().lower()

    if normalized_role not in ["admin", "viewer"]:
        raise HTTPException(
            status_code=400,
            detail="Role inválida. Use 'admin' ou 'viewer'"
        )

    return normalized_role


def get_organization_name(db: Session, organization_id: int | None):
    if not organization_id:
        return None

    organization = db.query(models.Organization).filter(
        models.Organization.id == organization_id
    ).first()

    if not organization:
        raise HTTPException(
            status_code=404,
            detail="Organização não encontrada"
        )

    return organization.name


def count_admin_users(db: Session):
    return db.query(models.User).filter(
        models.User.role == "admin"
    ).count()


@router.post("/", response_model=schemas.UserResponse)
def create_user(
    user: schemas.UserCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_create"))
):
    existing_user = db.query(models.User).filter(
        models.User.email == user.email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email já cadastrado"
        )

    role = validate_role(user.role)
    organization_name = get_organization_name(db, user.organization_id)

    hashed_password = auth.hash_password(user.password)

    db_user = models.User(
        name=user.name.strip(),
        email=user.email.strip().lower(),
        password=hashed_password,
        organization_id=user.organization_id,
        role=role
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return {
        "id": db_user.id,
        "name": db_user.name,
        "email": db_user.email,
        "organization_id": db_user.organization_id,
        "organization_name": organization_name,
        "role": db_user.role
    }


@router.get("/", response_model=list[schemas.UserResponse])
def list_users(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_view"))
):
    users = db.query(models.User).all()

    result = []

    for user in users:
        organization_name = None

        if user.organization_id:
            organization = db.query(models.Organization).filter(
                models.Organization.id == user.organization_id
            ).first()

            if organization:
                organization_name = organization.name

        result.append({
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "organization_id": user.organization_id,
            "organization_name": organization_name,
            "role": user.role
        })

    return result


@router.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(
        models.User.email == form_data.username
    ).first()

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Usuário não encontrado"
        )

    if not auth.verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=401,
            detail="Senha inválida"
        )

    token = auth.create_token({"user_id": user.id})

    return {
        "access_token": token,
        "token_type": "bearer"
    }


@router.put("/{user_id}", response_model=schemas.UserResponse)
def update_user(
    user_id: int,
    user_data: schemas.UserUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_edit"))
):
    user = db.query(models.User).filter(
        models.User.id == user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Usuário não encontrado"
        )

    existing_email_user = db.query(models.User).filter(
        models.User.email == user_data.email,
        models.User.id != user_id
    ).first()

    if existing_email_user:
        raise HTTPException(
            status_code=400,
            detail="Email já está em uso por outro usuário"
        )

    role = validate_role(user_data.role)

    if user.role == "admin" and role != "admin":
        total_admins = count_admin_users(db)

        if total_admins <= 1:
            raise HTTPException(
                status_code=400,
                detail="Não é possível remover o último administrador do sistema"
            )

    organization_name = get_organization_name(db, user_data.organization_id)

    user.name = user_data.name.strip()
    user.email = user_data.email.strip().lower()
    user.organization_id = user_data.organization_id
    user.role = role

    db.commit()
    db.refresh(user)

    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "organization_id": user.organization_id,
        "organization_name": organization_name,
        "role": user.role
    }


@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("users_delete"))
):
    if current_user.id == user_id:
        raise HTTPException(
            status_code=400,
            detail="Você não pode excluir o próprio usuário logado"
        )

    user = db.query(models.User).filter(
        models.User.id == user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Usuário não encontrado"
        )

    if user.role == "admin":
        total_admins = count_admin_users(db)

        if total_admins <= 1:
            raise HTTPException(
                status_code=400,
                detail="Não é possível excluir o último administrador do sistema"
            )

    db.delete(user)
    db.commit()

    return {"message": "Usuário excluído com sucesso"}