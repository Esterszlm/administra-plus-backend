from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models, schemas, auth

router = APIRouter(prefix="/events")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/", response_model=schemas.EventResponse)
def create_event(
    event: schemas.EventCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("events_create"))
):
    auth.ensure_same_organization(current_user, event.organization_id)
    organization_name = None

    if event.organization_id:
        organization = db.query(models.Organization).filter(
            models.Organization.id == event.organization_id
        ).first()

        if not organization:
            raise HTTPException(
                status_code=404,
                detail="Organização não encontrada"
            )

        organization_name = organization.name

    db_event = models.Event(**event.dict())
    db.add(db_event)
    db.commit()
    db.refresh(db_event)

    return {
        "id": db_event.id,
        "title": db_event.title,
        "description": db_event.description,
        "date": db_event.date,
        "location": db_event.location,
        "organization_id": db_event.organization_id,
        "organization_name": organization_name
    }


@router.get("/", response_model=list[schemas.EventResponse])
def list_events(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("events_view"))
):
    query = db.query(models.Event)
    if current_user.role != "admin":
        query = query.filter(models.Event.organization_id == current_user.organization_id)
    events = query.all()

    result = []

    for event in events:
        organization_name = None

        if event.organization_id:
            organization = db.query(models.Organization).filter(
                models.Organization.id == event.organization_id
            ).first()

            if organization:
                organization_name = organization.name

        result.append({
            "id": event.id,
            "title": event.title,
            "description": event.description,
            "date": event.date,
            "location": event.location,
            "organization_id": event.organization_id,
            "organization_name": organization_name
        })

    return result


@router.put("/{event_id}", response_model=schemas.EventResponse)
def update_event(
    event_id: int,
    event_data: schemas.EventUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("events_edit"))
):
    event = db.query(models.Event).filter(
        models.Event.id == event_id
    ).first()

    if not event:
        raise HTTPException(
            status_code=404,
            detail="Evento não encontrado"
        )

    auth.ensure_same_organization(current_user, event.organization_id)
    auth.ensure_same_organization(current_user, event_data.organization_id)

    organization_name = None

    if event_data.organization_id:
        organization = db.query(models.Organization).filter(
            models.Organization.id == event_data.organization_id
        ).first()

        if not organization:
            raise HTTPException(
                status_code=404,
                detail="Organização não encontrada"
            )

        organization_name = organization.name

    event.title = event_data.title
    event.description = event_data.description
    event.date = event_data.date
    event.location = event_data.location
    event.organization_id = event_data.organization_id

    db.commit()
    db.refresh(event)

    return {
        "id": event.id,
        "title": event.title,
        "description": event.description,
        "date": event.date,
        "location": event.location,
        "organization_id": event.organization_id,
        "organization_name": organization_name
    }


@router.delete("/{event_id}")
def delete_event(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_permission("events_delete"))
):
    event = db.query(models.Event).filter(
        models.Event.id == event_id
    ).first()

    if not event:
        raise HTTPException(
            status_code=404,
            detail="Evento não encontrado"
        )

    auth.ensure_same_organization(current_user, event.organization_id)

    existing_confirmation = db.query(models.Confirmation).filter(
        models.Confirmation.event_id == event_id
    ).first()

    if existing_confirmation:
        raise HTTPException(
            status_code=400,
            detail="Não é possível excluir evento com confirmações vinculadas"
        )

    db.delete(event)
    db.commit()

    return {"message": "Evento excluído com sucesso"}