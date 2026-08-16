# Administra+

O Administra+ é um sistema administrativo web/mobile desenvolvido como projeto acadêmico de TCC do curso de Engenharia da Computação.

O objetivo do sistema é centralizar a gestão administrativa de organizações, permitindo controlar usuários, organizações, eventos, confirmações de presença, lançamentos financeiros, permissões e dashboard.

Inicialmente, o projeto foi pensado para igrejas, mas sua estrutura foi desenvolvida de forma genérica para também atender empresas, associações, ONGs e organizações comunitárias.

---

## Tecnologias utilizadas

### Backend

* Python
* FastAPI
* SQLAlchemy
* SQLite
* JWT
* Passlib
* Swagger/OpenAPI

### Frontend

* Flutter

O foco atual do projeto está no backend, com testes realizados pelo Swagger.

---

## Estrutura principal do backend

```text
main.py
database.py
models.py
schemas.py
auth.py
requirements.txt
administra.db
routers/
```

Arquivos da pasta `routers`:

```text
users.py
organizations.py
events.py
finance.py
confirmations.py
permissions.py
dashboard.py
```

---

## Como instalar as dependências

Dentro da pasta do backend, execute:

```bash
pip install -r requirements.txt
```
---

## Como criar os dados iniciais

Como o banco local `administra.db` não é enviado para o GitHub, o projeto possui um script para criar os dados iniciais do sistema.

Dentro da pasta do backend, execute:

```bash
python seed_data.py
```

Esse comando cria ou verifica:

- Organização inicial
- Usuário administrador
- Usuário viewer de teste
- Permissões principais do sistema
- Permissões iniciais da usuária Maria

Usuário administrador de teste:

```text
username: admin@email.com
password: 123456
```

Usuário viewer de teste:

```text
username: maria@email.com
password: 123456
```
Se os dados já existirem, o script apenas informa que eles já foram criados.

---

## Como rodar o projeto

Dentro da pasta do backend, execute:

```bash
uvicorn main:app --reload
```

Depois acesse no navegador:

```text
http://127.0.0.1:8000/docs
```

---

## Rota inicial

```http
GET /
```

Resposta esperada:

```json
{
  "message": "API funcionando"
}
```

---

## Autenticação

O sistema utiliza autenticação com JWT.

A rota de login é:

```http
POST /users/login
```

No Swagger, o login é feito pelo botão `Authorize`.

Usuário administrador de teste:

```text
username: admin@email.com
password: 123456
```

Usuário viewer de teste:

```text
username: maria@email.com
password: 123456
```

Os campos `client_id` e `client_secret` devem ficar vazios.

---

## Módulos existentes

O backend possui os seguintes módulos:

* Usuários
* Organizações
* Eventos
* Confirmações
* Financeiro
* Permissões
* Dashboard

---

## Principais rotas

### Usuários

```http
POST /users/
GET /users/
PUT /users/{user_id}
DELETE /users/{user_id}
POST /users/login
```

### Organizações

```http
POST /organizations/
GET /organizations/
PUT /organizations/{organization_id}
DELETE /organizations/{organization_id}
```

### Eventos

```http
POST /events/
GET /events/
PUT /events/{event_id}
DELETE /events/{event_id}
```

### Confirmações

```http
POST /confirmations/
GET /confirmations/
```

### Financeiro

```http
POST /finance/
GET /finance/
PUT /finance/{finance_id}
DELETE /finance/{finance_id}
```

### Permissões

```http
POST /permissions/
GET /permissions/
POST /permissions/user
GET /permissions/user/{user_id}
DELETE /permissions/user/{user_id}/{permission_id}
```

### Dashboard

```http
GET /dashboard/
```

---

## Permissões principais

O sistema possui controle de acesso por permissões.

Algumas permissões existentes:

```text
users_create
users_view
users_edit
users_delete

organizations_create
organizations_view
organizations_edit
organizations_delete

events_create
events_view
events_edit
events_delete

finance_create
finance_view
finance_edit
finance_delete

confirmations_create
confirmations_view

permissions_view
permissions_create
permissions_assign
permissions_remove

dashboard_view
```

Usuários com `role = admin` possuem acesso total.

Usuários com `role = viewer` dependem das permissões vinculadas.

---

## Validações implementadas

### Organizações

* Bloqueia documento duplicado no cadastro.
* Bloqueia documento duplicado na edição.
* Retorna erro quando a organização não existe.

### Usuários

* Bloqueia email duplicado no cadastro.
* Bloqueia email duplicado na edição.
* Valida organização vinculada.
* Valida role.
* Bloqueia exclusão do próprio usuário logado.
* Bloqueia exclusão do último administrador.
* Bloqueia remoção do último administrador.

### Eventos

* Valida se a organização informada existe.
* Bloqueia exclusão de evento com confirmação vinculada.

### Financeiro

* Valida se a organização informada existe.
* Bloqueia valor zero.
* Bloqueia valor negativo.
* Aceita somente tipo `entrada` ou `saida`.
* Aceita `saída` com acento, mas salva como `saida`.

### Confirmações

* Valida se o evento existe.
* Bloqueia confirmação duplicada do mesmo usuário no mesmo evento.
* Aceita somente os status:

  * confirmado
  * recusado
  * talvez

### Permissões

* Bloqueia criação de permissão duplicada.
* Bloqueia vincular a mesma permissão duas vezes ao mesmo usuário.
* Protege rotas administrativas de permissões.

### Dashboard

* Exibe resumo geral do sistema.
* Exibe totais financeiros.
* Protegido por permissão `dashboard_view`.

---

## Dashboard

A rota:

```http
GET /dashboard/
```

Retorna um resumo do sistema com:

```text
total de organizações
total de usuários
total de eventos
total de confirmações
total de lançamentos financeiros
total de entradas
total de saídas
saldo final
```

Exemplo de resposta:

```json
{
  "totais": {
    "organizacoes": 2,
    "usuarios": 3,
    "eventos": 2,
    "confirmacoes": 2,
    "lancamentos_financeiros": 2
  },
  "financeiro": {
    "total_entradas": 150.75,
    "total_saidas": 50.0,
    "saldo_final": 100.75
  }
}
```

Os valores podem mudar conforme os dados cadastrados no banco.

---

## Banco de dados

O projeto utiliza SQLite para desenvolvimento local.

Arquivo atual:

```text
administra.db
```

Para uma versão comercial ou produção, recomenda-se evoluir para PostgreSQL.

---

## GitHub Student Developer Pack

Como evolução e apoio ao desenvolvimento, o projeto pode aproveitar benefícios do GitHub Student Developer Pack, como:

* GitHub Pro para melhor organização do repositório.
* GitHub Codespaces para ambiente de desenvolvimento em nuvem.
* Heroku ou Azure para testes de deploy.
* Domínio gratuito para apresentação do projeto.
* Sentry para monitoramento futuro de erros.
* 1Password para armazenamento seguro de senhas, tokens e chaves.

Esses benefícios ajudam a reduzir custos durante a construção e apresentação do projeto.

---

## Status atual

O backend está em estágio funcional avançado para protótipo acadêmico.

Funcionalidades já concluídas:

* API FastAPI estruturada.
* Banco SQLite configurado.
* Autenticação JWT.
* Hash de senha.
* CRUD de usuários.
* CRUD de organizações.
* CRUD de eventos.
* CRUD financeiro.
* Criação e listagem de confirmações.
* Sistema de permissões.
* Dashboard.
* Validações principais de segurança e regra de negócio.

---

## Próximos passos

Próximas evoluções recomendadas:

* Conectar o frontend Flutter ao backend.
* Criar tela de login.
* Criar tela de dashboard.
* Criar listagens no frontend.
* Criar documentação final do TCC.
* Preparar roteiro de apresentação.
* Avaliar deploy em ambiente cloud usando benefício estudantil.
* Futuramente migrar SQLite para PostgreSQL.
* Futuramente criar logs de auditoria.
* Futuramente implementar recuperação de senha.
* Futuramente implementar LGPD, backup, monitoramento e autenticação corporativa.
