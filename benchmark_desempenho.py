"""Comparação de desempenho. Uso: python benchmark_desempenho.py . resultado.json
Roda em pasta temporária: o banco real (administra.db) nunca é tocado."""
import os, sys, time, json, tempfile
ROOT=os.path.abspath(sys.argv[1]); OUT=os.path.abspath(sys.argv[2])
sys.path.insert(0,ROOT); os.chdir(tempfile.mkdtemp(prefix="administra_bench_"))
from datetime import datetime
from fastapi.testclient import TestClient
import main, models, auth
from database import SessionLocal
db=SessionLocal()
names=["events_view","events_edit","dashboard_view","finance_view"]
perms={}
for n in names:
    p=models.Permission(name=n,description=n); db.add(p); db.flush(); perms[n]=p.id
orgs=[]
for i in range(5):
    o=models.Organization(name=f"Org{i}",type="t",document=str(i),address="a",city="c",state="PR",responsible_name="r"); db.add(o); db.flush(); orgs.append(o.id)
v=models.User(name="v",email="v@t.com",password="x",organization_id=orgs[0],role="viewer",is_active=True); db.add(v); db.flush()
for n in names: db.add(models.UserPermission(user_id=v.id,permission_id=perms[n]))
ev_own=None
for o in orgs:
    for k in range(200):
        e=models.Event(title=f"e{k}",description="d",date=datetime(2026,11,1),location="l",organization_id=o); db.add(e)
        if ev_own is None: db.flush(); ev_own=e.id
    for k in range(500):
        db.add(models.Finance(type="entrada" if k%2 else "saida",amount=10.0,description="f",organization_id=o))
db.commit(); vid=v.id; db.close()
c=TestClient(main.app); h={"Authorization":f"Bearer {auth.create_token({'user_id':vid})}"}
body=dict(title="x",description="d",date="2026-11-01T00:00:00",location="l",organization_id=orgs[0])
cases={"GET /events/":lambda:c.get("/events/",headers=h),
       "GET /dashboard/":lambda:c.get("/dashboard/",headers=h),
       "PUT /events/{id}":lambda:c.put(f"/events/{ev_own}",json=body,headers=h)}
out={}
for name,f in cases.items():
    for _ in range(20): f()
    ts=[];n=0
    for _ in range(300):
        t=time.perf_counter(); r=f(); ts.append((time.perf_counter()-t)*1000); assert r.status_code==200
    n=len(r.json()) if name=="GET /events/" else None
    out[name]=dict(samples=ts,rows=n)
json.dump(out,open(OUT,"w"))
for k,v in out.items():
    s=sorted(v["samples"]); print(f"{k}: mediana {s[len(s)//2]:.1f} ms")
