"""Migração idempotente do cadastro de usuários para SQLite.

Pare o Uvicorn e faça backup antes de executar.
Execute da raiz do projeto: python migrar_status_usuarios.py
Não preenche created_at em usuários anteriores: a data real é desconhecida.
"""
from datetime import datetime
from pathlib import Path
import sqlite3

ROOT = Path(__file__).resolve().parent
DB = ROOT / "administra.db"
BACKUP_DIR = ROOT.parent / "Backup_Administra_TCC"


def main():
    if not DB.exists():
        raise SystemExit(f"ERRO: banco de dados não encontrado em {DB}")

    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    backup = BACKUP_DIR / f"administra_antes_status_{datetime.now():%Y%m%d_%H%M%S_%f}.db"

    # A API deve estar parada. Backup SQLite consistente, inclusive em WAL.
    with sqlite3.connect(str(DB), timeout=10) as db, sqlite3.connect(str(backup)) as copy:
        db.backup(copy)

    changes = {
        "is_active": "INTEGER NOT NULL DEFAULT 1",
        "created_at": "DATETIME",
        "deactivated_at": "DATETIME",
        "deactivation_reason": "VARCHAR(500)",
    }
    with sqlite3.connect(str(DB), timeout=10) as db:
        found = db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='users'").fetchone()
        if not found:
            raise SystemExit("ERRO: tabela users não encontrada; não foi feita alteração")
        columns = {row[1] for row in db.execute('PRAGMA table_info("users")')}
        for column, definition in changes.items():
            if column not in columns:
                db.execute(f'ALTER TABLE "users" ADD COLUMN "{column}" {definition}')
                print(f"Coluna adicionada: users.{column}")
            else:
                print(f"Já existente: users.{column}")
        db.commit()
        integrity = db.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            raise SystemExit(f"ATENÇÃO: integridade SQLite retornou: {integrity}")
        n = db.execute("SELECT count(*) FROM users").fetchone()[0]
        inactive = db.execute("SELECT count(*) FROM users WHERE is_active=0").fetchone()[0]
        print(f"Integridade: {integrity}; usuários: {n}; desativados: {inactive}")
    print(f"Backup criado: {backup}")
    print("Migração concluída. Usuários antigos mantêm created_at = NULL (data original desconhecida).")


if __name__ == "__main__":
    main()
