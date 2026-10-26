"""Cadastra permissões padrão faltantes, preservando vínculos atuais.
Execute com o FastAPI parado e a partir de Administra+_api.
"""
from pathlib import Path
from shutil import copy2
from datetime import datetime
from database import SessionLocal, engine
import models

CATALOG = {
    "dashboard_view": "Visualizar painel de indicadores",
    "organizations_view": "Visualizar organizações",
    "organizations_create": "Cadastrar organizações",
    "organizations_edit": "Editar organizações",
    "organizations_delete": "Excluir organizações",
    "events_view": "Visualizar eventos",
    "events_create": "Cadastrar eventos",
    "events_edit": "Editar eventos",
    "events_delete": "Excluir eventos",
    "finance_view": "Visualizar lançamentos financeiros",
    "finance_create": "Cadastrar lançamentos financeiros",
    "finance_edit": "Editar lançamentos financeiros",
    "finance_delete": "Excluir lançamentos financeiros",
    "users_view": "Visualizar usuários",
    "users_create": "Cadastrar usuários",
    "users_edit": "Editar cadastros de usuários",
}

if engine.url.get_backend_name() != "sqlite":
    raise RuntimeError("Este script de backup foi preparado apenas para SQLite")
db_path = Path(engine.url.database)
if not db_path.is_absolute():
    db_path = (Path.cwd() / db_path).resolve()
if not db_path.is_file():
    raise RuntimeError(f"Banco não encontrado: {db_path}")
backup_dir = db_path.parent.parent / "Backup_Administra_TCC"
backup_dir.mkdir(parents=True, exist_ok=True)
backup_file = backup_dir / f"administra_antes_catalogo_{datetime.now():%Y%m%d_%H%M%S}.db"
copy2(db_path, backup_file)
print(f"Backup: {backup_file}")

with SessionLocal() as db:
    existing = {p.name for p in db.query(models.Permission).all()}
    created = 0
    for name, description in CATALOG.items():
        if name not in existing:
            db.add(models.Permission(name=name, description=description))
            created += 1
    db.commit()
    print(f"Permissões novas: {created}; catálogo disponível: {len(CATALOG)}")
