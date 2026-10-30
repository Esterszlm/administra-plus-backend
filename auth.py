
from passlib.context import CryptContext
from jose import jwt, JWTError
from datetime import datetime, timedelta
import os, secrets
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from database import SessionLocal
import models


# ==========================================================
# CONFIGURAÇÕES DE AUTENTICAÇÃO JWT
# ==========================================================

# Chave lida do ambiente; sem variável definida, gera chave aleatória por execução.
SECRET_KEY = os.environ.get("ADMINISTRA_SECRET_KEY") or secrets.token_urlsafe(64)
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60


# ==========================================================
# CRIPTOGRAFIA DE SENHAS
# ==========================================================

pwd_context = CryptContext(
    schemes=["pbkdf2_sha256"],
    deprecated="auto"
)

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/users/login"
)


def hash_password(password: str):
    return pwd_context.hash(password)


def verify_password(password, hashed):
    return pwd_context.verify(password, hashed)


# ==========================================================
# GERAÇÃO DO TOKEN JWT
# ==========================================================

def create_token(data: dict):
    to_encode = data.copy()

    expire = datetime.utcnow() + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    to_encode.update({
        "exp": expire
    })

    return jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM
    )


# ==========================================================
# CONEXÃO COM O BANCO DE DADOS
# ==========================================================

def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


# ==========================================================
# AUTENTICAÇÃO DO USUÁRIO
# VALIDA JWT, EXISTÊNCIA E STATUS ATIVO
# ==========================================================

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido ou expirado",
        headers={
            "WWW-Authenticate": "Bearer"
        },
    )

    # ------------------------------------------------------
    # 1. Validar token JWT
    # ------------------------------------------------------

    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )

        user_id = payload.get("user_id")

        if user_id is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    # ------------------------------------------------------
    # 2. Consultar usuário no banco
    # ------------------------------------------------------

    user = db.query(models.User).filter(
        models.User.id == user_id
    ).first()

    # ------------------------------------------------------
    # 3. Bloquear usuário inexistente
    # ------------------------------------------------------

    if user is None:
        raise credentials_exception

    # ------------------------------------------------------
    # 4. Bloquear usuário desativado
    # ------------------------------------------------------

    if user.is_active is not True:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                "Usuário desativado. "
                "Entre em contato com o administrador."
            ),
            headers={
                "WWW-Authenticate": "Bearer"
            },
        )

    # ------------------------------------------------------
    # 5. Permitir acesso ao usuário ativo
    # ------------------------------------------------------

    return user


# ==========================================================
# VERIFICAÇÃO DE PERMISSÕES
# ==========================================================

def user_has_permission(
    user,
    permission_name: str,
    db: Session
):
    # Administrador ativo possui todas as permissões.
    # O status ativo já foi validado em get_current_user.

    if user.role == "admin":
        return True

    user_permissions = db.query(
        models.UserPermission
    ).filter(
        models.UserPermission.user_id == user.id
    ).all()

    for user_permission in user_permissions:
        permission = db.query(
            models.Permission
        ).filter(
            models.Permission.id == user_permission.permission_id
        ).first()

        if permission and permission.name == permission_name:
            return True

    return False


# ==========================================================
# PROTEÇÃO DOS ENDPOINTS POR PERMISSÃO
# ==========================================================

def require_permission(permission_name: str):

    def permission_checker(
        current_user=Depends(get_current_user),
        db: Session = Depends(get_db)
    ):

        # Usuários desativados já são bloqueados antes
        # desta etapa pela função get_current_user.

        if current_user.role == "admin":
            return current_user

        has_permission = user_has_permission(
            current_user,
            permission_name,
            db
        )

        if not has_permission:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permissão insuficiente"
            )

        return current_user

    return permission_checker


# ==========================================================
# ISOLAMENTO ENTRE ORGANIZAÇÕES
# ==========================================================

def ensure_same_organization(current_user, organization_id):
    """Administrador acessa tudo; demais usuários apenas a própria organização."""
    if current_user.role == "admin":
        return
    if current_user.organization_id is None or current_user.organization_id != organization_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para acessar dados de outra organização",
        )
