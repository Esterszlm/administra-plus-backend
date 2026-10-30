from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models, schemas, auth

router = APIRouter(prefix="/organizations")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/", response_model=schemas.OrganizationResponse)
def create_organization(
    organization: schemas.OrganizationCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("organizations_create"))
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Somente administradores cadastram organizações")
    document = organization.document.strip()

    existing_organization = db.query(models.Organization).filter(
        models.Organization.document == document
    ).first()

    if existing_organization:
        raise HTTPException(
            status_code=400,
            detail="Documento já cadastrado"
        )

    db_organization = models.Organization(
        name=organization.name.strip(),
        type=organization.type.strip(),
        document=document,
        address=organization.address.strip(),
        city=organization.city.strip(),
        state=organization.state.strip(),
        responsible_name=organization.responsible_name.strip()
    )

    db.add(db_organization)
    db.commit()
    db.refresh(db_organization)

    return db_organization


@router.get("/", response_model=list[schemas.OrganizationResponse])
def list_organizations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("organizations_view"))
):
    query = db.query(models.Organization)
    if current_user.role != "admin":
        query = query.filter(models.Organization.id == current_user.organization_id)
    return query.all()


@router.put("/{organization_id}", response_model=schemas.OrganizationResponse)
def update_organization(
    organization_id: int,
    organization_data: schemas.OrganizationUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("organizations_edit"))
):
    auth.ensure_same_organization(current_user, organization_id)
    organization = db.query(models.Organization).filter(
        models.Organization.id == organization_id
    ).first()

    if not organization:
        raise HTTPException(
            status_code=404,
            detail="Organização não encontrada"
        )

    document = organization_data.document.strip()

    existing_organization = db.query(models.Organization).filter(
        models.Organization.document == document,
        models.Organization.id != organization_id
    ).first()

    if existing_organization:
        raise HTTPException(
            status_code=400,
            detail="Documento já está em uso por outra organização"
        )

    organization.name = organization_data.name.strip()
    organization.type = organization_data.type.strip()
    organization.document = document
    organization.address = organization_data.address.strip()
    organization.city = organization_data.city.strip()
    organization.state = organization_data.state.strip()
    organization.responsible_name = organization_data.responsible_name.strip()

    db.commit()
    db.refresh(organization)

    return organization


@router.delete("/{organization_id}")
def delete_organization(
    organization_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("organizations_delete"))
):
    auth.ensure_same_organization(current_user, organization_id)
    organization = db.query(models.Organization).filter(
        models.Organization.id == organization_id
    ).first()

    if not organization:
        raise HTTPException(
            status_code=404,
            detail="Organização não encontrada"
        )

    db.delete(organization)
    db.commit()

    return {"message": "Organização excluída com sucesso"}