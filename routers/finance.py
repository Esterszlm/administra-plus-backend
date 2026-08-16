from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models, schemas, auth

router = APIRouter(prefix="/finance")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def validate_finance_type(finance_type: str):
    normalized_type = finance_type.strip().lower()

    if normalized_type == "saída":
        normalized_type = "saida"

    if normalized_type not in ["entrada", "saida"]:
        raise HTTPException(
            status_code=400,
            detail="Tipo financeiro inválido. Use 'entrada' ou 'saida'"
        )

    return normalized_type


def validate_finance_amount(amount: float):
    if amount <= 0:
        raise HTTPException(
            status_code=400,
            detail="O valor do lançamento deve ser maior que zero"
        )


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


@router.post("/", response_model=schemas.FinanceResponse)
def create(
    entry: schemas.FinanceCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("finance_create"))
):
    finance_type = validate_finance_type(entry.type)
    validate_finance_amount(entry.amount)

    organization_name = get_organization_name(db, entry.organization_id)

    db_entry = models.Finance(
        type=finance_type,
        amount=entry.amount,
        description=entry.description.strip(),
        organization_id=entry.organization_id
    )

    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)

    return {
        "id": db_entry.id,
        "type": db_entry.type,
        "amount": db_entry.amount,
        "description": db_entry.description,
        "date": db_entry.date,
        "organization_id": db_entry.organization_id,
        "organization_name": organization_name
    }


@router.get("/", response_model=list[schemas.FinanceResponse])
def list_all(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("finance_view"))
):
    entries = db.query(models.Finance).all()

    result = []

    for entry in entries:
        organization_name = None

        if entry.organization_id:
            organization = db.query(models.Organization).filter(
                models.Organization.id == entry.organization_id
            ).first()

            if organization:
                organization_name = organization.name

        result.append({
            "id": entry.id,
            "type": entry.type,
            "amount": entry.amount,
            "description": entry.description,
            "date": entry.date,
            "organization_id": entry.organization_id,
            "organization_name": organization_name
        })

    return result


@router.put("/{finance_id}", response_model=schemas.FinanceResponse)
def update_finance(
    finance_id: int,
    finance_data: schemas.FinanceUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("finance_edit"))
):
    finance = db.query(models.Finance).filter(
        models.Finance.id == finance_id
    ).first()

    if not finance:
        raise HTTPException(
            status_code=404,
            detail="Lançamento financeiro não encontrado"
        )

    finance_type = validate_finance_type(finance_data.type)
    validate_finance_amount(finance_data.amount)

    organization_name = get_organization_name(db, finance_data.organization_id)

    finance.type = finance_type
    finance.amount = finance_data.amount
    finance.description = finance_data.description.strip()
    finance.organization_id = finance_data.organization_id

    db.commit()
    db.refresh(finance)

    return {
        "id": finance.id,
        "type": finance.type,
        "amount": finance.amount,
        "description": finance.description,
        "date": finance.date,
        "organization_id": finance.organization_id,
        "organization_name": organization_name
    }


@router.delete("/{finance_id}")
def delete_finance(
    finance_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("finance_delete"))
):
    finance = db.query(models.Finance).filter(
        models.Finance.id == finance_id
    ).first()

    if not finance:
        raise HTTPException(
            status_code=404,
            detail="Lançamento financeiro não encontrado"
        )

    db.delete(finance)
    db.commit()

    return {"message": "Lançamento financeiro excluído com sucesso"}