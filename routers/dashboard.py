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
    total_organizations = db.query(models.Organization).count()
    total_users = db.query(models.User).count()
    total_events = db.query(models.Event).count()
    total_confirmations = db.query(models.Confirmation).count()
    total_finance_entries = db.query(models.Finance).count()

    total_entradas = db.query(
        func.coalesce(func.sum(models.Finance.amount), 0)
    ).filter(
        models.Finance.type == "entrada"
    ).scalar()

    total_saidas = db.query(
        func.coalesce(func.sum(models.Finance.amount), 0)
    ).filter(
        models.Finance.type == "saida"
    ).scalar()

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