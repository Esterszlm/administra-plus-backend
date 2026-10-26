"""Permissões do Administra+: catálogo, consultas e concessões por administrador.

Reutiliza Permission/UserPermission, sem alterar a estrutura do SQLite.
"""
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models, schemas, auth

router = APIRouter(prefix="/permissions")

# Escopos de interface que um administrador pode delegar a visualizadores.
# Não expor permissions_assign/create/remove para evitar escalada de privilégios.
MANAGED = {
    "dashboard": ["dashboard_view"],
    "organizations": [
        "organizations_view", "organizations_create",
        "organizations_edit", "organizations_delete",
    ],
    "events": ["events_view", "events_create", "events_edit", "events_delete"],
    "finance": ["finance_view", "finance_create", "finance_edit", "finance_delete"],
    "users": ["users_view", "users_create", "users_edit"],
}
ALLOWED_NAMES = set().union(*MANAGED.values())


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def require_admin(current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Apenas administradores gerenciam permissões")
    return current_user


class PermissionSelection(BaseModel):
    permissions: list[str]


@router.get("/me")
def my_permissions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    """O usuário autenticado pode consultar só suas próprias permissões."""
    if current_user.role == "admin":
        names = sorted(ALLOWED_NAMES)
    else:
        names = sorted({p.name for p in db.query(models.Permission)
                        .join(models.UserPermission,
                              models.UserPermission.permission_id == models.Permission.id)
                        .filter(models.UserPermission.user_id == current_user.id)
                        .all()})
    return {
        "user_id": current_user.id,
        "role": current_user.role,
        "organization_id": current_user.organization_id,
        "is_admin": current_user.role == "admin",
        "permissions": names,
    }


@router.get("/catalog")
def permission_catalog(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_admin),
):
    available = {p.name for p in db.query(models.Permission).filter(
        models.Permission.name.in_(ALLOWED_NAMES)).all()}
    return {
        "groups": MANAGED,
        "missing": sorted(ALLOWED_NAMES - available),
    }


@router.post("/", response_model=schemas.PermissionResponse)
def create_permission(
    permission: schemas.PermissionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_admin),
):
    name = permission.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Nome de permissão obrigatório")
    if db.query(models.Permission).filter(models.Permission.name == name).first():
        raise HTTPException(status_code=400, detail="Permissão já cadastrada")
    obj = models.Permission(name=name, description=permission.description.strip())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/", response_model=list[schemas.PermissionResponse])
def list_permissions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_admin),
):
    return db.query(models.Permission).order_by(models.Permission.name).all()


@router.post("/user", response_model=schemas.UserPermissionResponse)
def add_permission_to_user(
    user_permission: schemas.UserPermissionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_admin),
):
    user = db.query(models.User).filter(models.User.id == user_permission.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    if user.role != "viewer":
        raise HTTPException(status_code=400, detail="O administrador já possui acesso completo")
    permission = db.query(models.Permission).filter(
        models.Permission.id == user_permission.permission_id).first()
    if not permission:
        raise HTTPException(status_code=404, detail="Permissão não encontrada")
    if permission.name not in ALLOWED_NAMES:
        raise HTTPException(status_code=403, detail="Esta permissão não pode ser delegada")
    existing = db.query(models.UserPermission).filter(
        models.UserPermission.user_id == user.id,
        models.UserPermission.permission_id == permission.id,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Usuário já possui essa permissão")
    obj = models.UserPermission(user_id=user.id, permission_id=permission.id)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/user/{user_id}")
def list_user_permissions(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_admin),
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    rows = db.query(models.UserPermission, models.Permission).join(
        models.Permission, models.Permission.id == models.UserPermission.permission_id,
    ).filter(models.UserPermission.user_id == user_id).all()
    return [
        {"id": up.id, "user_id": user_id, "permission_id": p.id,
         "permission_name": p.name, "description": p.description}
        for up, p in rows
    ]


@router.put("/user/{user_id}/set")
def set_user_permissions(
    user_id: int,
    body: PermissionSelection,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_admin),
):
    """Atualiza todas as permissões delegáveis em uma transação."""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    if user.role != "viewer":
        raise HTTPException(status_code=400, detail="Apenas perfis visualizadores recebem permissões específicas")
    requested = set(body.permissions)
    if not requested <= ALLOWED_NAMES:
        raise HTTPException(status_code=400, detail="Uma ou mais permissões são inválidas ou não delegáveis")
    # Não permitir ações de cadastro/edição/exclusão sem visualizar o módulo.
    for module, names in MANAGED.items():
        view = f"{module}_view"
        if any(name in requested for name in names if name != view) and view not in requested:
            raise HTTPException(status_code=400, detail=f"Conceda {view} antes das operações de escrita")
    available = {p.name: p.id for p in db.query(models.Permission).filter(
        models.Permission.name.in_(ALLOWED_NAMES)).all()}
    missing = requested - set(available)
    if missing:
        raise HTTPException(status_code=400, detail=f"Permissões não cadastradas: {', '.join(sorted(missing))}")
    old = db.query(models.UserPermission).join(models.Permission).filter(
        models.UserPermission.user_id == user_id,
        models.Permission.name.in_(ALLOWED_NAMES),
    ).all()
    existing_ids = {item.permission_id for item in old}
    wanted_ids = {available[name] for name in requested}
    try:
        for item in old:
            if item.permission_id not in wanted_ids:
                db.delete(item)
        for permission_id in wanted_ids - existing_ids:
            db.add(models.UserPermission(user_id=user_id, permission_id=permission_id))
        db.commit()
    except Exception:
        db.rollback()
        raise
    return {"user_id": user_id, "permissions": sorted(requested)}


@router.delete("/user/{user_id}/{permission_id}")
def remove_permission_from_user(
    user_id: int,
    permission_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_admin),
):
    obj = db.query(models.UserPermission).filter(
        models.UserPermission.user_id == user_id,
        models.UserPermission.permission_id == permission_id,
    ).first()
    if obj is None:
        raise HTTPException(status_code=404, detail="Permissão do usuário não encontrada")
    db.delete(obj)
    db.commit()
    return {"message": "Permissão removida com sucesso"}
