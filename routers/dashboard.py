from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import SessionLocal
import models, auth

router = APIRouter(prefix="/dashboard")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/")
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("dashboard_view"))
):
    is_admin = current_user.role == "admin"
    org_id = current_user.organization_id

    def scoped(query, column):
        return query if is_admin else query.filter(column == org_id)

    total_organizations = scoped(db.query(models.Organization), models.Organization.id).count()
    total_users = scoped(db.query(models.User), models.User.organization_id).count()
    total_events = scoped(db.query(models.Event), models.Event.organization_id).count()
    confirmations_query = db.query(models.Confirmation)
    if not is_admin:
        confirmations_query = confirmations_query.join(
            models.Event, models.Event.id == models.Confirmation.event_id
        ).filter(models.Event.organization_id == org_id)
    total_confirmations = confirmations_query.count()
    total_finance_entries = scoped(db.query(models.Finance), models.Finance.organization_id).count()

    total_entradas = scoped(db.query(
        func.coalesce(func.sum(models.Finance.amount), 0)
    ).filter(models.Finance.type == "entrada"), models.Finance.organization_id).scalar()

    total_saidas = scoped(db.query(
        func.coalesce(func.sum(models.Finance.amount), 0)
    ).filter(models.Finance.type == "saida"), models.Finance.organization_id).scalar()

    saldo_final = total_entradas - total_saidas

    return {
        "totais": {
            "organizacoes": total_organizations,
            "usuarios": total_users,
            "eventos": total_events,
            "confirmacoes": total_confirmations,
            "lancamentos_financeiros": total_finance_entries
        },
        "financeiro": {
            "total_entradas": total_entradas,
            "total_saidas": total_saidas,
            "saldo_final": saldo_final
        }
    }