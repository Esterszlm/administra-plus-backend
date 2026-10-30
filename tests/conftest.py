import os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT); sys.path.insert(0, ROOT)
if os.path.exists("administra.db"):
    os.remove("administra.db")

from datetime import datetime
import pytest
from fastapi.testclient import TestClient
import main, models, auth
from database import SessionLocal
from routers.permissions import ALLOWED_NAMES

EXTRA = {"confirmations_view", "confirmations_create"}


@pytest.fixture(scope="session")
def ctx():
    db = SessionLocal()
    perms = {}
    for n in sorted(ALLOWED_NAMES | EXTRA):
        p = models.Permission(name=n, description=n)
        db.add(p); db.flush(); perms[n] = p.id
    A = models.Organization(name="Org A", type="igreja", document="111", address="x",
                            city="c", state="PR", responsible_name="a")
    B = models.Organization(name="Org B", type="associacao", document="222", address="x",
                            city="c", state="PR", responsible_name="b")
    db.add_all([A, B]); db.flush()

    def user(name, role, org, plist=(), active=True):
        u = models.User(name=name, email=f"{name}@t.com", password=auth.hash_password("Senha@123"),
                        organization_id=org, role=role, is_active=active)
        db.add(u); db.flush()
        for pn in plist:
            db.add(models.UserPermission(user_id=u.id, permission_id=perms[pn]))
        return u

    admin = user("admin", "admin", None)
    full = sorted(ALLOWED_NAMES | EXTRA)
    vA = user("viewerA", "viewer", A.id, full)
    vB = user("viewerB", "viewer", B.id, ["finance_view"])
    vOrgOnly = user("soorg", "viewer", A.id, ["organizations_view"])
    vNone = user("semperm", "viewer", A.id, [])
    inactive = user("inativo", "viewer", A.id, ["organizations_view"], active=False)

    evA = models.Event(title="Culto A", description="d", date=datetime(2026, 11, 1), location="l", organization_id=A.id)
    evB = models.Event(title="Reuniao B", description="d", date=datetime(2026, 11, 2), location="l", organization_id=B.id)
    db.add_all([evA, evB]); db.flush()
    fA = models.Finance(type="entrada", amount=100.0, description="oferta A", organization_id=A.id, user_id=vA.id)
    fB = models.Finance(type="entrada", amount=999.0, description="doacao B", organization_id=B.id, user_id=vB.id)
    db.add_all([fA, fB]); db.flush()
    db.add(models.Confirmation(user_id=vB.id, event_id=evB.id, status="confirmado"))
    db.commit()
    ids = dict(A=A.id, B=B.id, admin=admin.id, vA=vA.id, vB=vB.id, vOrgOnly=vOrgOnly.id,
               vNone=vNone.id, inactive=inactive.id, evA=evA.id, evB=evB.id, fA=fA.id, fB=fB.id)
    db.close()
    return ids


@pytest.fixture(scope="session")
def client():
    return TestClient(main.app)


def tok(uid):
    return {"Authorization": f"Bearer {auth.create_token({'user_id': uid})}"}
