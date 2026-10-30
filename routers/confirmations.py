from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models, schemas, auth

router = APIRouter(prefix="/confirmations")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def validate_confirmation_status(status: str):
    normalized_status = status.strip().lower()

    allowed_status = ["confirmado", "recusado", "talvez"]

    if normalized_status not in allowed_status:
        raise HTTPException(
            status_code=400,
            detail="Status inválido. Use 'confirmado', 'recusado' ou 'talvez'"
        )

    return normalized_status


@router.post("/")
def confirm(
    data: schemas.ConfirmationCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("confirmations_create"))
):
    event = db.query(models.Event).filter(
        models.Event.id == data.event_id
    ).first()

    if not event:
        raise HTTPException(
            status_code=404,
            detail="Evento não encontrado"
        )

    auth.ensure_same_organization(current_user, event.organization_id)

    existing_confirmation = db.query(models.Confirmation).filter(
        models.Confirmation.user_id == current_user.id,
        models.Confirmation.event_id == data.event_id
    ).first()

    if existing_confirmation:
        raise HTTPException(
            status_code=400,
            detail="Você já confirmou presença nesse evento"
        )

    confirmation_status = validate_confirmation_status(data.status)

    confirmation = models.Confirmation(
        user_id=current_user.id,
        event_id=data.event_id,
        status=confirmation_status
    )

    db.add(confirmation)
    db.commit()
    db.refresh(confirmation)

    return {
        "id": confirmation.id,
        "user_id": confirmation.user_id,
        "event_id": confirmation.event_id,
        "status": confirmation.status,
        "message": "Confirmação registrada com sucesso"
    }


@router.get("/")
def list_confirmations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("confirmations_view"))
):
    query = db.query(models.Confirmation)
    if current_user.role != "admin":
        query = query.join(models.Event, models.Event.id == models.Confirmation.event_id).filter(
            models.Event.organization_id == current_user.organization_id
        )
    confirmations = query.all()

    result = []

    for confirmation in confirmations:
        user = db.query(models.User).filter(
            models.User.id == confirmation.user_id
        ).first()

        event = db.query(models.Event).filter(
            models.Event.id == confirmation.event_id
        ).first()

        result.append({
            "id": confirmation.id,
            "user_id": confirmation.user_id,
            "user_name": user.name if user else None,
            "event_id": confirmation.event_id,
            "event_title": event.title if event else None,
            "status": confirmation.status
        })

    return result