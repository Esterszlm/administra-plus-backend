from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from database import Base, engine
from routers import users, events, confirmations, finance, organizations, permissions, dashboard
import models, auth

Base.metadata.create_all(bind=engine)

app = FastAPI()

# LIBERAR ACESSO WEB/MOBILE
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router)
app.include_router(events.router)
app.include_router(confirmations.router)
app.include_router(finance.router)
app.include_router(organizations.router)
app.include_router(permissions.router)
app.include_router(dashboard.router)

@app.get("/")
def root():
    return {"message": "API funcionando"}

@app.get("/me")
def read_me(current_user: models.User = Depends(auth.get_current_user)):
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "role": current_user.role,
        "organization_id": current_user.organization_id
    }