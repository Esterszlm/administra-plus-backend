from decimal import Decimal, ROUND_HALF_UP
from math import isfinite

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
    if normalized_type not in ("entrada", "saida"):
        raise HTTPException(
            status_code=400,
            detail="Tipo financeiro inválido. Use 'entrada' ou 'saida'",
        )
    return normalized_type


def validate_finance_amount(amount: float):
    if not isfinite(amount) or amount <= 0:
        raise HTTPException(
            status_code=400,
            detail="O valor do lançamento deve ser um número finito maior que zero",
        )


def get_organization_name(db: Session, organization_id: int | None):
    if organization_id is None:
        return None
    organization = db.query(models.Organization).filter(
        models.Organization.id == organization_id
    ).first()
    if not organization:
        raise HTTPException(status_code=404, detail="Organização não encontrada")
    return organization.name


def check_organization_access(current_user: models.User, organization_id: int | None):
    """Administradores têm acesso geral; outros usuários somente à sua organização."""
    if current_user.role != "admin":
        if current_user.organization_id is None or current_user.organization_id != organization_id:
            raise HTTPException(
                status_code=403,
                detail="Sem permissão para acessar finanças desta organização",
            )


def validate_linked_user(db: Session, user_id: int | None, organization_id: int | None, *, allow_inactive: bool = False):
    if user_id is None:
        return None
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="Usuário vinculado não encontrado")
    if not user.is_active and not allow_inactive:
        raise HTTPException(status_code=400, detail="Não é possível criar novos vínculos financeiros com usuário desativado")
    if user.organization_id != organization_id:
        raise HTTPException(
            status_code=400,
            detail="O usuário vinculado deve pertencer à mesma organização do lançamento",
        )
    return user


def serialize_finance(db: Session, entry: models.Finance):
    organization = (
        db.query(models.Organization).filter(models.Organization.id == entry.organization_id).first()
        if entry.organization_id is not None else None
    )
    user = (
        db.query(models.User).filter(models.User.id == entry.user_id).first()
        if entry.user_id is not None else None
    )
    return {
        "id": entry.id,
        "type": entry.type,
        "amount": entry.amount,
        "description": entry.description,
        "date": entry.date,
        "organization_id": entry.organization_id,
        "organization_name": organization.name if organization else None,
        "user_id": entry.user_id,
        "user_name": user.name if user else None,
    }


@router.post("/", response_model=schemas.FinanceResponse)
def create(
    entry: schemas.FinanceCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("finance_create")),
):
    finance_type = validate_finance_type(entry.type)
    validate_finance_amount(entry.amount)
    get_organization_name(db, entry.organization_id)
    check_organization_access(current_user, entry.organization_id)
    validate_linked_user(db, entry.user_id, entry.organization_id)
    if not entry.description.strip():
        raise HTTPException(status_code=400, detail="Descrição não pode ficar vazia")

    db_entry = models.Finance(
        type=finance_type,
        amount=entry.amount,
        description=entry.description.strip(),
        organization_id=entry.organization_id,
        user_id=entry.user_id,
    )
    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)
    return serialize_finance(db, db_entry)


@router.get("/", response_model=list[schemas.FinanceResponse])
def list_all(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("finance_view")),
):
    query = db.query(models.Finance)
    if current_user.role != "admin":
        if current_user.organization_id is None:
            return []
        query = query.filter(models.Finance.organization_id == current_user.organization_id)
    return [serialize_finance(db, entry) for entry in query.all()]


@router.get("/users/{user_id}/summary")
def user_finance_summary(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("finance_view")),
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    check_organization_access(current_user, user.organization_id)

    query = db.query(models.Finance).filter(models.Finance.user_id == user_id)
    if current_user.role != "admin":
        query = query.filter(models.Finance.organization_id == current_user.organization_id)
    entries = query.order_by(models.Finance.date.desc(), models.Finance.id.desc()).all()

    total_entradas = Decimal("0.00")
    total_saidas = Decimal("0.00")
    for entry in entries:
        amount = Decimal(str(entry.amount))
        if entry.type == "entrada":
            total_entradas += amount
        elif entry.type in ("saida", "saída"):
            total_saidas += amount

    two_decimals = Decimal("0.01")
    def as_money(value: Decimal) -> float:
        return float(value.quantize(two_decimals, rounding=ROUND_HALF_UP))

    return {
        "user_id": user.id,
        "user_name": user.name,
        "organization_id": user.organization_id,
        "total_entradas": as_money(total_entradas),
        "total_saidas": as_money(total_saidas),
        "saldo": as_money(total_entradas - total_saidas),
        "quantidade_lancamentos": len(entries),
        "lancamentos": [serialize_finance(db, entry) for entry in entries],
    }


@router.put("/{finance_id}", response_model=schemas.FinanceResponse)
def update_finance(
    finance_id: int,
    finance_data: schemas.FinanceUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("finance_edit")),
):
    finance = db.query(models.Finance).filter(models.Finance.id == finance_id).first()
    if not finance:
        raise HTTPException(status_code=404, detail="Lançamento financeiro não encontrado")
    check_organization_access(current_user, finance.organization_id)

    finance_type = validate_finance_type(finance_data.type)
    validate_finance_amount(finance_data.amount)
    get_organization_name(db, finance_data.organization_id)
    check_organization_access(current_user, finance_data.organization_id)

    # Compatibilidade: o formulário Flutter antigo ainda não envia user_id.
    # Campo ausente => mantém vínculo; user_id: null => remove vínculo.
    provided_fields = getattr(finance_data, "model_fields_set", None)
    if provided_fields is None:
        provided_fields = getattr(finance_data, "__fields_set__", set())
    linked_user_id = (
        finance_data.user_id if "user_id" in provided_fields else finance.user_id
    )
    validate_linked_user(
        db, linked_user_id, finance_data.organization_id,
        allow_inactive=(linked_user_id == finance.user_id),
    )
    if not finance_data.description.strip():
        raise HTTPException(status_code=400, detail="Descrição não pode ficar vazia")

    finance.type = finance_type
    finance.amount = finance_data.amount
    finance.description = finance_data.description.strip()
    finance.organization_id = finance_data.organization_id
    finance.user_id = linked_user_id
    db.commit()
    db.refresh(finance)
    return serialize_finance(db, finance)


@router.delete("/{finance_id}")
def delete_finance(
    finance_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("finance_delete")),
):
    finance = db.query(models.Finance).filter(models.Finance.id == finance_id).first()
    if not finance:
        raise HTTPException(status_code=404, detail="Lançamento financeiro não encontrado")
    check_organization_access(current_user, finance.organization_id)
    db.delete(finance)
    db.commit()
    return {"message": "Lançamento financeiro excluído com sucesso"}
