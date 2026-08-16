from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models, schemas, auth

router = APIRouter(prefix="/permissions")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/", response_model=schemas.PermissionResponse)
def create_permission(
    permission: schemas.PermissionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("permissions_create"))
):
    existing_permission = db.query(models.Permission).filter(
        models.Permission.name == permission.name
    ).first()

    if existing_permission:
        raise HTTPException(
            status_code=400,
            detail="Permissão já cadastrada"
        )

    db_permission = models.Permission(
        name=permission.name.strip(),
        description=permission.description.strip()
    )

    db.add(db_permission)
    db.commit()
    db.refresh(db_permission)

    return db_permission


@router.get("/", response_model=list[schemas.PermissionResponse])
def list_permissions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("permissions_view"))
):
    return db.query(models.Permission).all()


@router.post("/user", response_model=schemas.UserPermissionResponse)
def add_permission_to_user(
    user_permission: schemas.UserPermissionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("permissions_assign"))
):
    user = db.query(models.User).filter(
        models.User.id == user_permission.user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Usuário não encontrado"
        )

    permission = db.query(models.Permission).filter(
        models.Permission.id == user_permission.permission_id
    ).first()

    if not permission:
        raise HTTPException(
            status_code=404,
            detail="Permissão não encontrada"
        )

    existing_user_permission = db.query(models.UserPermission).filter(
        models.UserPermission.user_id == user_permission.user_id,
        models.UserPermission.permission_id == user_permission.permission_id
    ).first()

    if existing_user_permission:
        raise HTTPException(
            status_code=400,
            detail="Usuário já possui essa permissão"
        )

    db_user_permission = models.UserPermission(
        user_id=user_permission.user_id,
        permission_id=user_permission.permission_id
    )

    db.add(db_user_permission)
    db.commit()
    db.refresh(db_user_permission)

    return db_user_permission


@router.get("/user/{user_id}")
def list_user_permissions(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("permissions_view"))
):
    user = db.query(models.User).filter(
        models.User.id == user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Usuário não encontrado"
        )

    user_permissions = db.query(models.UserPermission).filter(
        models.UserPermission.user_id == user_id
    ).all()

    result = []

    for item in user_permissions:
        permission = db.query(models.Permission).filter(
            models.Permission.id == item.permission_id
        ).first()

        if permission:
            result.append({
                "id": item.id,
                "user_id": item.user_id,
                "permission_id": permission.id,
                "permission_name": permission.name,
                "description": permission.description
            })

    return result


@router.delete("/user/{user_id}/{permission_id}")
def remove_permission_from_user(
    user_id: int,
    permission_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("permissions_remove"))
):
    user_permission = db.query(models.UserPermission).filter(
        models.UserPermission.user_id == user_id,
        models.UserPermission.permission_id == permission_id
    ).first()

    if not user_permission:
        raise HTTPException(
            status_code=404,
            detail="Permissão do usuário não encontrada"
        )

    db.delete(user_permission)
    db.commit()

    return {"message": "Permissão removida com sucesso"}