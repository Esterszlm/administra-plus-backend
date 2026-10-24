"""Migra o SQLite Administra+ sem apagar lançamentos existentes.

Executar UMA VEZ com FastAPI e Flutter parados:
    python migrar_vinculo_financeiro.py

Cria backup fora do repositório antes de alterar a tabela.
"""

import sqlite3
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "administra.db"
BACKUP_DIR = ROOT.parent / "Backup_Administra_TCC"


def main():
    if not DB_PATH.is_file():
        raise SystemExit(f"ERRO: banco não encontrado em {DB_PATH}. Nada foi alterado.")

    with sqlite3.connect(DB_PATH) as db:
        table_exists = db.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='finance'"
        ).fetchone()
        users_exists = db.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='users'"
        ).fetchone()
        if not table_exists or not users_exists:
            raise SystemExit("ERRO: tabelas finance/users ausentes. Nada foi alterado.")

        columns = [row[1] for row in db.execute("PRAGMA table_info(finance)")]
        if "user_id" in columns:
            print("A coluna finance.user_id já existe. Migração não foi repetida.")
            print("Registros financeiros:", db.execute("SELECT COUNT(*) FROM finance").fetchone()[0])
            return

        BACKUP_DIR.mkdir(exist_ok=True)
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = BACKUP_DIR / f"administra_pre_vinculo_{stamp}.db"
        if backup_path.exists():
            raise SystemExit("ERRO: nome de backup já existe. Tente novamente.")
        with sqlite3.connect(backup_path) as backup:
            db.backup(backup)
        print("Backup de segurança:", backup_path)
        original_count = db.execute("SELECT COUNT(*) FROM finance").fetchone()[0]
        print("Lançamentos antes:", original_count)

        db.execute("PRAGMA foreign_keys = ON")
        db.execute("ALTER TABLE finance ADD COLUMN user_id INTEGER REFERENCES users(id)")
        db.commit()

        after_columns = [row[1] for row in db.execute("PRAGMA table_info(finance)")]
        after_count = db.execute("SELECT COUNT(*) FROM finance").fetchone()[0]
        foreign_keys = list(db.execute("PRAGMA foreign_key_list(finance)"))
        if "user_id" not in after_columns or after_count != original_count:
            raise SystemExit("ERRO: verificação da migração falhou. Preserve o backup.")

        print("OK: finance.user_id adicionada e registros preservados:", after_count)
        print("Chave estrangeira user_id registrada:", any(fk[3] == "user_id" and fk[2] == "users" for fk in foreign_keys))
        print("Lançamentos antigos continuam sem usuário vinculado (user_id NULL).")


if __name__ == "__main__":
    main()
