from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Float, Boolean, text
from datetime import datetime, timezone
from database import Base


def utc_now_naive():
    """SQLite armazena estes DATETIME em UTC sem fuso horário."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    name = Column(String)
    email = Column(String, unique=True)
    password = Column(String)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=True)
    role = Column(String, default="viewer")
    # Para novos usuários, registra a data real de cadastro. Cadastros antigos
    # permanecem NULL após a migração: não é correto inventar datas históricas.
    created_at = Column(DateTime, nullable=True, default=utc_now_naive)
    is_active = Column(Boolean, nullable=False, default=True, server_default=text("1"))
    deactivated_at = Column(DateTime, nullable=True)
    deactivation_reason = Column(String(500), nullable=True)


class Event(Base):
    __tablename__ = "events"
    id = Column(Integer, primary_key=True)
    title = Column(String)
    description = Column(String)
    date = Column(DateTime)
    location = Column(String)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=True)


class Confirmation(Base):
    __tablename__ = "confirmations"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    event_id = Column(Integer, ForeignKey("events.id"))
    status = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)


class Finance(Base):
    __tablename__ = "finance"
    id = Column(Integer, primary_key=True)
    type = Column(String)
    amount = Column(Float)
    description = Column(String)
    date = Column(DateTime, default=datetime.utcnow)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=True)
    # Novo: pessoa associada ao lançamento (não quem digitou o registro).
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)


class Organization(Base):
    __tablename__ = "organizations"
    id = Column(Integer, primary_key=True)
    name = Column(String)
    type = Column(String)
    document = Column(String)
    address = Column(String)
    city = Column(String)
    state = Column(String)
    responsible_name = Column(String)


class Permission(Base):
    __tablename__ = "permissions"
    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)
    description = Column(String)


class UserPermission(Base):
    __tablename__ = "user_permissions"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    permission_id = Column(Integer, ForeignKey("permissions.id"))
