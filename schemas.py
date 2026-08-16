from pydantic import BaseModel
from datetime import datetime

class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    organization_id: int | None = None
    role: str = "viewer"

class UserUpdate(BaseModel):
    name: str
    email: str
    organization_id: int | None = None
    role: str

class UserPasswordUpdate(BaseModel):
    password: str

class EventCreate(BaseModel):
    title: str
    description: str
    date: datetime
    location: str
    organization_id: int | None = None

class EventUpdate(BaseModel):
    title: str
    description: str
    date: datetime
    location: str
    organization_id: int | None = None

class EventResponse(BaseModel):
    id: int
    title: str
    description: str
    date: datetime
    location: str
    organization_id: int | None = None
    organization_name: str | None = None

    class Config:
        from_attributes = True

class ConfirmationCreate(BaseModel):
    event_id: int
    status: str

class FinanceCreate(BaseModel):
    type: str
    amount: float
    description: str
    organization_id: int | None = None

class FinanceResponse(BaseModel):
    id: int
    type: str
    amount: float
    description: str
    date: datetime
    organization_id: int | None = None
    organization_name: str | None = None

    class Config:
        from_attributes = True

class FinanceUpdate(BaseModel):
    type: str
    amount: float
    description: str
    organization_id: int | None = None

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    organization_id: int | None = None
    organization_name: str | None = None
    role: str

    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    email: str
    password: str

class OrganizationCreate(BaseModel):
    name: str
    type: str
    document: str
    address: str
    city: str
    state: str
    responsible_name: str

class OrganizationResponse(BaseModel):
    id: int
    name: str
    type: str
    document: str
    address: str
    city: str
    state: str
    responsible_name: str

    class Config:
        from_attributes = True

class OrganizationUpdate(BaseModel):
    name: str
    type: str
    document: str
    address: str
    city: str
    state: str
    responsible_name: str

class PermissionCreate(BaseModel):
    name: str
    description: str


class PermissionResponse(BaseModel):
    id: int
    name: str
    description: str

    class Config:
        from_attributes = True


class UserPermissionCreate(BaseModel):
    user_id: int
    permission_id: int


class UserPermissionResponse(BaseModel):
    id: int
    user_id: int
    permission_id: int

    class Config:
        from_attributes = True