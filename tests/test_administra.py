"""Suite de verificacao do Administra+.
Cada teste declara o comportamento ESPERADO (seguro / conforme requisito).
Teste que falha = comportamento do sistema diverge do esperado."""
from datetime import datetime, timedelta
from jose import jwt
from conftest import tok
import auth


# ---------- A. Autenticacao ----------
def test_T01_sem_token_401(client, ctx):
    assert client.get("/organizations/").status_code == 401

def test_T02_token_invalido_401(client, ctx):
    assert client.get("/organizations/", headers={"Authorization": "Bearer abc.def.ghi"}).status_code == 401

def test_T03_token_expirado_401(client, ctx):
    t = jwt.encode({"user_id": ctx["admin"], "exp": datetime.utcnow() - timedelta(minutes=1)},
                   auth.SECRET_KEY, algorithm="HS256")
    assert client.get("/organizations/", headers={"Authorization": f"Bearer {t}"}).status_code == 401

def test_T04_senha_incorreta_401(client, ctx):
    r = client.post("/users/login", data={"username": "admin@t.com", "password": "errada"})
    assert r.status_code == 401

def test_T05_login_valido_200(client, ctx):
    r = client.post("/users/login", data={"username": "admin@t.com", "password": "Senha@123"})
    assert r.status_code == 200 and "access_token" in r.json()

def test_T06_login_usuario_desativado_bloqueado(client, ctx):
    r = client.post("/users/login", data={"username": "inativo@t.com", "password": "Senha@123"})
    assert r.status_code == 403

def test_T07_token_de_usuario_desativado_401(client, ctx):
    assert client.get("/organizations/", headers=tok(ctx["inactive"])).status_code == 401

def test_T08_token_forjado_com_chave_publicada(client, ctx):
    # A chave "administra_secret" esta escrita no codigo-fonte publico (auth.py).
    forjado = jwt.encode({"user_id": ctx["admin"], "exp": datetime.utcnow() + timedelta(hours=1)},
                         "administra_secret", algorithm="HS256")
    r = client.get("/permissions/", headers={"Authorization": f"Bearer {forjado}"})
    assert r.status_code == 401, f"token forjado aceito como administrador (HTTP {r.status_code})"


# ---------- B. Autorizacao por funcionalidade ----------
def test_T09_viewer_sem_permissao_403(client, ctx):
    assert client.get("/organizations/", headers=tok(ctx["vNone"])).status_code == 403

def test_T10_permissao_de_modulo_nao_libera_outro(client, ctx):
    assert client.get("/events/", headers=tok(ctx["vOrgOnly"])).status_code == 403

def test_T11_leitura_nao_libera_escrita(client, ctx):
    body = dict(name="X", type="t", document="999", address="a", city="c", state="PR", responsible_name="r")
    assert client.post("/organizations/", json=body, headers=tok(ctx["vOrgOnly"])).status_code == 403

def test_T12_viewer_nao_gerencia_permissoes(client, ctx):
    assert client.get("/permissions/catalog", headers=tok(ctx["vA"])).status_code == 403

def test_T13_viewer_nao_cria_administrador(client, ctx):
    body = dict(name="hack", email="hack@t.com", password="x", organization_id=ctx["A"], role="admin")
    assert client.post("/users/", json=body, headers=tok(ctx["vA"])).status_code == 403

def test_T14_viewer_nao_se_promove(client, ctx):
    body = dict(name="viewerA", email="viewerA@t.com", organization_id=ctx["A"], role="admin")
    assert client.put(f"/users/{ctx['vA']}", json=body, headers=tok(ctx["vA"])).status_code == 403


# ---------- C. Isolamento entre organizacoes ----------
def test_T15_financeiro_lista_propria_org(client, ctx):
    r = client.get("/finance/", headers=tok(ctx["vA"]))
    assert r.status_code == 200 and all(f["organization_id"] == ctx["A"] for f in r.json())

def test_T16_financeiro_resumo_outra_org_403(client, ctx):
    assert client.get(f"/finance/users/{ctx['vB']}/summary", headers=tok(ctx["vA"])).status_code == 403

def test_T17_financeiro_editar_outra_org_403(client, ctx):
    body = dict(type="entrada", amount=1.0, description="x", organization_id=ctx["B"])
    assert client.put(f"/finance/{ctx['fB']}", json=body, headers=tok(ctx["vA"])).status_code == 403

def test_T18_usuarios_lista_propria_org(client, ctx):
    r = client.get("/users/", headers=tok(ctx["vA"]))
    assert r.status_code == 200 and all(u["organization_id"] == ctx["A"] for u in r.json())

def test_T19_eventos_lista_propria_org(client, ctx):
    r = client.get("/events/", headers=tok(ctx["vA"]))
    vis = {e["organization_id"] for e in r.json()}
    assert vis <= {ctx["A"]}, f"viewer da Org A visualiza eventos das orgs {vis}"

def test_T20_eventos_editar_outra_org_403(client, ctx):
    body = dict(title="ALTERADO", description="d", date="2026-11-02T00:00:00", location="l", organization_id=ctx["B"])
    r = client.put(f"/events/{ctx['evB']}", json=body, headers=tok(ctx["vA"]))
    assert r.status_code == 403, f"HTTP {r.status_code}"

def test_T21_eventos_criar_em_outra_org_403(client, ctx):
    body = dict(title="intruso", description="d", date="2026-12-01T00:00:00", location="l", organization_id=ctx["B"])
    r = client.post("/events/", json=body, headers=tok(ctx["vA"]))
    assert r.status_code == 403, f"HTTP {r.status_code}"

def test_T22_organizacoes_lista_propria(client, ctx):
    r = client.get("/organizations/", headers=tok(ctx["vA"]))
    vis = {o["id"] for o in r.json()}
    assert vis <= {ctx["A"]}, f"viewer da Org A visualiza orgs {vis}"

def test_T23_organizacoes_editar_outra_403(client, ctx):
    body = dict(name="Org B alterada", type="t", document="222", address="a", city="c", state="PR", responsible_name="r")
    r = client.put(f"/organizations/{ctx['B']}", json=body, headers=tok(ctx["vA"]))
    assert r.status_code == 403, f"HTTP {r.status_code}"

def test_T24_dashboard_restrito_propria_org(client, ctx):
    ent = client.get("/dashboard/", headers=tok(ctx["vA"])).json()["financeiro"]["total_entradas"]
    assert ent == 100.0, f"dashboard soma entradas de todas as orgs: {ent}"

def test_T25_confirmacoes_lista_propria_org(client, ctx):
    evs = {c["event_id"] for c in client.get("/confirmations/", headers=tok(ctx["vA"])).json()}
    assert ctx["evB"] not in evs, "viewer da Org A visualiza confirmacoes de evento da Org B"


# ---------- D. Regras de negocio e integridade ----------
def test_T26_valor_zero_rejeitado(client, ctx):
    b = dict(type="entrada", amount=0, description="x", organization_id=ctx["A"])
    assert client.post("/finance/", json=b, headers=tok(ctx["admin"])).status_code == 400

def test_T27_valor_negativo_rejeitado(client, ctx):
    b = dict(type="saida", amount=-5, description="x", organization_id=ctx["A"])
    assert client.post("/finance/", json=b, headers=tok(ctx["admin"])).status_code == 400

def test_T28_tipo_financeiro_invalido(client, ctx):
    b = dict(type="emprestimo", amount=5, description="x", organization_id=ctx["A"])
    assert client.post("/finance/", json=b, headers=tok(ctx["admin"])).status_code == 400

def test_T29_documento_duplicado(client, ctx):
    b = dict(name="Dup", type="t", document="111", address="a", city="c", state="PR", responsible_name="r")
    assert client.post("/organizations/", json=b, headers=tok(ctx["admin"])).status_code == 400

def test_T30_excluir_evento_com_confirmacao(client, ctx):
    assert client.delete(f"/events/{ctx['evB']}", headers=tok(ctx["admin"])).status_code == 400

def test_T31_confirmacao_duplicada(client, ctx):
    h = tok(ctx["vA"])
    client.post("/confirmations/", json={"event_id": ctx["evA"], "status": "confirmado"}, headers=h)
    r = client.post("/confirmations/", json={"event_id": ctx["evA"], "status": "confirmado"}, headers=h)
    assert r.status_code == 400

def test_T32_admin_nao_desativa_a_si_mesmo(client, ctx):
    r = client.patch(f"/users/{ctx['admin']}/deactivate", json={"reason": "teste"}, headers=tok(ctx["admin"]))
    assert r.status_code == 400

def test_T33_exclusao_fisica_de_usuario_bloqueada(client, ctx):
    assert client.delete(f"/users/{ctx['vB']}", headers=tok(ctx["admin"])).status_code == 409
