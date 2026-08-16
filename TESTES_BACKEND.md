# Roteiro de Testes do Backend — Administra+

Este documento apresenta um roteiro de testes para validar as principais funcionalidades do backend do sistema Administra+.

Os testes devem ser realizados pelo Swagger, acessando:

```text
http://127.0.0.1:8000/docs
```

Antes dos testes, execute o servidor:

```bash
uvicorn main:app --reload
```

Se necessário, crie os dados iniciais:

```bash
python seed_data.py
```

---

## 1. Teste da rota inicial

### Rota

```http
GET /
```

### Resultado esperado

```json
{
  "message": "API funcionando"
}
```

### Status esperado

```text
200 OK
```

---

## 2. Teste de autenticação com admin

### Ação

No Swagger, clicar em `Authorize`.

Informar:

```text
username: admin@email.com
password: 123456
```

Deixar vazios:

```text
client_id
client_secret
```

### Resultado esperado

Login realizado com sucesso.

---

## 3. Teste de usuário autenticado

### Rota

```http
GET /me
```

### Resultado esperado

Deve retornar os dados do usuário logado.

Exemplo:

```json
{
  "id": 1,
  "name": "Administrador",
  "email": "admin@email.com",
  "role": "admin",
  "organization_id": 1
}
```

### Status esperado

```text
200 OK
```

---

## 4. Teste de listagem de organizações

### Rota

```http
GET /organizations/
```

### Resultado esperado

Deve retornar a lista de organizações cadastradas.

### Status esperado

```text
200 OK
```

---

## 5. Teste de bloqueio de documento duplicado em organizações

### Rota

```http
POST /organizations/
```

### Corpo de exemplo

Usar um `document` que já existe no banco.

```json
{
  "name": "Organização Duplicada",
  "type": "empresa",
  "document": "12345678900000",
  "address": "Rua Teste",
  "city": "Curitiba",
  "state": "PR",
  "responsible_name": "Responsável Teste"
}
```

### Resultado esperado

```json
{
  "detail": "Documento já cadastrado"
}
```

### Status esperado

```text
400 Bad Request
```

---

## 6. Teste de criação de organização válida

### Rota

```http
POST /organizations/
```

### Corpo de exemplo

```json
{
  "name": "Organização Teste",
  "type": "empresa",
  "document": "99999999000199",
  "address": "Rua Teste",
  "city": "São Paulo",
  "state": "SP",
  "responsible_name": "Responsável Teste"
}
```

### Resultado esperado

Deve cadastrar a organização com sucesso.

### Status esperado

```text
200 OK
```

---

## 7. Teste de listagem de usuários

### Rota

```http
GET /users/
```

### Resultado esperado

Deve retornar a lista de usuários cadastrados.

### Status esperado

```text
200 OK
```

---

## 8. Teste de bloqueio de email duplicado

### Rota

```http
POST /users/
```

### Corpo de exemplo

Usar um e-mail que já existe.

```json
{
  "name": "Usuário Duplicado",
  "email": "admin@email.com",
  "password": "123456",
  "organization_id": 1,
  "role": "viewer"
}
```

### Resultado esperado

```json
{
  "detail": "Email já cadastrado"
}
```

### Status esperado

```text
400 Bad Request
```

---

## 9. Teste de criação de usuário válido

### Rota

```http
POST /users/
```

### Corpo de exemplo

```json
{
  "name": "Usuário Teste",
  "email": "usuario.teste@email.com",
  "password": "123456",
  "organization_id": 1,
  "role": "viewer"
}
```

### Resultado esperado

Deve cadastrar o usuário com sucesso.

### Status esperado

```text
200 OK
```

---

## 10. Teste de criação de evento com organização inexistente

### Rota

```http
POST /events/
```

### Corpo de exemplo

```json
{
  "title": "Evento Organização Inexistente",
  "description": "Teste de validação",
  "date": "2026-07-10T19:00:00",
  "location": "Local Teste",
  "organization_id": 99999
}
```

### Resultado esperado

```json
{
  "detail": "Organização não encontrada"
}
```

### Status esperado

```text
404 Not Found
```

---

## 11. Teste de criação de evento válido

### Rota

```http
POST /events/
```

### Corpo de exemplo

```json
{
  "title": "Evento Teste",
  "description": "Evento criado para teste",
  "date": "2026-07-10T19:00:00",
  "location": "Auditório Principal",
  "organization_id": 1
}
```

### Resultado esperado

Deve criar o evento com sucesso e retornar o nome da organização.

### Status esperado

```text
200 OK
```

---

## 12. Teste de confirmação válida

### Rota

```http
POST /confirmations/
```

### Corpo de exemplo

Usar um `event_id` existente.

```json
{
  "event_id": 1,
  "status": "confirmado"
}
```

### Resultado esperado

```json
{
  "message": "Confirmação registrada com sucesso"
}
```

### Status esperado

```text
200 OK
```

---

## 13. Teste de confirmação duplicada

### Rota

```http
POST /confirmations/
```

### Corpo de exemplo

Enviar novamente a mesma confirmação para o mesmo evento.

```json
{
  "event_id": 1,
  "status": "confirmado"
}
```

### Resultado esperado

```json
{
  "detail": "Você já confirmou presença nesse evento"
}
```

### Status esperado

```text
400 Bad Request
```

---

## 14. Teste de status inválido na confirmação

### Rota

```http
POST /confirmations/
```

### Corpo de exemplo

```json
{
  "event_id": 1,
  "status": "sim"
}
```

### Resultado esperado

```json
{
  "detail": "Status inválido. Use 'confirmado', 'recusado' ou 'talvez'"
}
```

### Status esperado

```text
400 Bad Request
```

---

## 15. Teste financeiro com organização inexistente

### Rota

```http
POST /finance/
```

### Corpo de exemplo

```json
{
  "type": "entrada",
  "amount": 100,
  "description": "Teste organização inexistente",
  "organization_id": 99999
}
```

### Resultado esperado

```json
{
  "detail": "Organização não encontrada"
}
```

### Status esperado

```text
404 Not Found
```

---

## 16. Teste financeiro com valor zero

### Rota

```http
POST /finance/
```

### Corpo de exemplo

```json
{
  "type": "entrada",
  "amount": 0,
  "description": "Teste valor zero",
  "organization_id": 1
}
```

### Resultado esperado

```json
{
  "detail": "O valor do lançamento deve ser maior que zero"
}
```

### Status esperado

```text
400 Bad Request
```

---

## 17. Teste financeiro com tipo inválido

### Rota

```http
POST /finance/
```

### Corpo de exemplo

```json
{
  "type": "receita",
  "amount": 100,
  "description": "Teste tipo inválido",
  "organization_id": 1
}
```

### Resultado esperado

```json
{
  "detail": "Tipo financeiro inválido. Use 'entrada' ou 'saida'"
}
```

### Status esperado

```text
400 Bad Request
```

---

## 18. Teste financeiro válido

### Rota

```http
POST /finance/
```

### Corpo de exemplo

```json
{
  "type": "entrada",
  "amount": 150.75,
  "description": "Oferta mensal",
  "organization_id": 1
}
```

### Resultado esperado

Deve cadastrar o lançamento financeiro com sucesso.

### Status esperado

```text
200 OK
```

---

## 19. Teste de dashboard com admin

### Rota

```http
GET /dashboard/
```

### Resultado esperado

Deve retornar os totais do sistema.

Exemplo:

```json
{
  "totais": {
    "organizacoes": 1,
    "usuarios": 2,
    "eventos": 1,
    "confirmacoes": 1,
    "lancamentos_financeiros": 1
  },
  "financeiro": {
    "total_entradas": 150.75,
    "total_saidas": 0,
    "saldo_final": 150.75
  }
}
```

### Status esperado

```text
200 OK
```

---

## 20. Teste de bloqueio do dashboard com Maria

### Ação

Fazer logout do admin e login com:

```text
username: maria@email.com
password: 123456
```

### Rota

```http
GET /dashboard/
```

### Resultado esperado

Se a Maria não possuir a permissão `dashboard_view`, deve retornar:

```json
{
  "detail": "Permissão insuficiente"
}
```

### Status esperado

```text
403 Forbidden
```

---

## 21. Teste de permissões com Maria

### Ação

Logar com a Maria.

### Rota

```http
GET /permissions/
```

### Resultado esperado

Como a Maria não deve possuir permissão administrativa, deve retornar:

```json
{
  "detail": "Permissão insuficiente"
}
```

### Status esperado

```text
403 Forbidden
```

---

## 22. Teste de permissões com admin

### Ação

Fazer login novamente como admin.

### Rota

```http
GET /permissions/
```

### Resultado esperado

Deve retornar a lista de permissões cadastradas.

### Status esperado

```text
200 OK
```

---

## Conclusão dos testes

Ao final dos testes, o backend deve demonstrar:

- API funcionando.
- Login com JWT funcionando.
- Rotas protegidas por permissão.
- Admin com acesso total.
- Viewer com acesso limitado.
- Validações de organização.
- Validações de usuário.
- Validações de evento.
- Validações de confirmação.
- Validações financeiras.
- Dashboard funcional.
- Permissões administrativas protegidas.