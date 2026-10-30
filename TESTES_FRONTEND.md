# Roteiro de Testes do Frontend — Administra+

Este documento apresenta um roteiro de testes para validar o frontend Flutter Web do sistema Administra+ integrado ao backend FastAPI.

O objetivo dos testes é demonstrar que o frontend consegue:

- Realizar login.
- Consumir a API do backend.
- Utilizar token JWT.
- Exibir dados reais do dashboard.
- Listar organizações.
- Listar eventos.
- Listar lançamentos financeiros.
- Navegar pelo menu lateral.
- Realizar logout.

---

## 1. Pré-requisitos

Antes de iniciar os testes, é necessário ter:

- Backend FastAPI funcionando.
- Banco local `administra.db` criado.
- Dados iniciais criados pelo `seed_data.py`.
- Frontend Flutter com dependências instaladas.
- Navegador Chrome disponível.

---

## 2. Subir o backend

Abrir um terminal na pasta principal do projeto:

```text
C:\Users\ester\OneDrive\Documentos\Administra+_api
```

Executar:

```bash
uvicorn main:app --reload
```

Resultado esperado:

```text
Uvicorn running on http://127.0.0.1:8000
```

O backend deve permanecer rodando durante os testes do frontend.

---

## 3. Validar Swagger do backend

Com o backend rodando, acessar:

```text
http://127.0.0.1:8000/docs
```

Resultado esperado:

- Swagger deve abrir normalmente.
- Rotas principais devem estar disponíveis.
- A API deve permitir autenticação pelo botão `Authorize`.

Rotas importantes para o frontend:

```http
POST /users/login
GET /dashboard/
GET /organizations/
GET /events/
GET /finance/
```

---

## 4. Criar dados iniciais, se necessário

Caso o banco local ainda não tenha dados, abrir um terminal na pasta principal do projeto e executar:

```bash
python seed_data.py
```

Resultado esperado:

```text
Organização inicial já existe.
Usuário admin já existe.
Usuário Maria já existe.
Permissões verificadas/criadas.
Permissões da Maria verificadas/criadas.
```

Ou mensagens informando que os dados foram criados.

---

## 5. Subir o frontend Flutter Web

Abrir outro terminal na pasta do frontend:

```text
C:\Users\ester\OneDrive\Documentos\Administra+_api\administra_app
```

Executar:

```bash
flutter run -d chrome
```

Resultado esperado:

- O Flutter deve compilar o projeto.
- O navegador Chrome deve abrir automaticamente.
- A tela de login do Administra+ deve ser exibida.

---

## 6. Teste da tela de login

### Tela esperada

A tela inicial deve apresentar:

- Nome do sistema: `Administra+`
- Campo de e-mail.
- Campo de senha.
- Botão `Entrar`.

### Dados de teste

```text
E-mail: admin@email.com
Senha: 123456
```

### Resultado esperado

Ao clicar em `Entrar`, o sistema deve autenticar o usuário e abrir a tela principal com o dashboard.

---

## 7. Teste de login inválido

### Ação

Informar uma senha incorreta.

Exemplo:

```text
E-mail: admin@email.com
Senha: senhaerrada
```

### Resultado esperado

O sistema deve exibir mensagem de erro, como:

```text
Erro no login. Verifique e-mail e senha.
```

O usuário não deve acessar o dashboard.

---

## 8. Teste do dashboard

### Ação

Fazer login com o usuário administrador.

### Tela esperada

O dashboard deve exibir cards com os seguintes dados:

- Organizações.
- Usuários.
- Eventos.
- Confirmações.
- Lançamentos.
- Entradas.
- Saídas.
- Saldo final.

### Resultado esperado

Os valores exibidos devem vir da API do backend pela rota:

```http
GET /dashboard/
```

Exemplo de informações exibidas:

```text
Organizações: 2
Usuários: 3
Eventos: 2
Confirmações: 2
Lançamentos: 2
Entradas: R$ 150.75
Saídas: R$ 25.50
Saldo final: R$ 125.25
```

Os números podem variar de acordo com os dados cadastrados no banco.

---

## 9. Teste do menu lateral

### Ação

Clicar no ícone de menu no canto superior esquerdo.

### Resultado esperado

O menu lateral deve abrir com as opções:

```text
Dashboard
Organizações
Eventos
Financeiro
Sair
```

---

## 10. Teste da tela de organizações

### Ação

No menu lateral, clicar em:

```text
Organizações
```

### Resultado esperado

A tela deve listar as organizações cadastradas no backend.

Cada card deve exibir informações como:

- Nome da organização.
- Documento.
- ID.
- Tipo.
- Cidade.
- Estado.
- Responsável.

A rota consumida pelo frontend é:

```http
GET /organizations/
```

---

## 11. Teste da tela de eventos

### Ação

No menu lateral, clicar em:

```text
Eventos
```

### Resultado esperado

A tela deve listar os eventos cadastrados no backend.

Cada card deve exibir informações como:

- Título do evento.
- Local.
- ID.
- Descrição.
- Data.
- Organização.

A rota consumida pelo frontend é:

```http
GET /events/
```

---

## 12. Teste da tela financeira

### Ação

No menu lateral, clicar em:

```text
Financeiro
```

### Resultado esperado

A tela deve listar os lançamentos financeiros cadastrados no backend.

Cada card deve exibir informações como:

- Descrição.
- Valor.
- ID.
- Tipo.
- Organização.

A rota consumida pelo frontend é:

```http
GET /finance/
```

---

## 13. Teste do botão atualizar

### Ação

Nas telas de listagem, clicar no botão:

```text
Atualizar
```

### Resultado esperado

O frontend deve buscar novamente os dados no backend e atualizar a tela.

Esse botão está disponível nas telas:

- Organizações.
- Eventos.
- Financeiro.

---

## 14. Teste de logout

### Ação

Abrir o menu lateral e clicar em:

```text
Sair
```

### Resultado esperado

O sistema deve retornar para a tela de login.

---

## 15. Teste de backend desligado

### Ação

Parar o backend e tentar realizar login no frontend.

### Resultado esperado

O frontend deve exibir mensagem de erro de conexão, como:

```text
Erro ao conectar com o backend. Verifique se a API está rodando.
```

---

## 16. Evidências para apresentação

Durante a apresentação do TCC, recomenda-se demonstrar:

1. Backend rodando no terminal.
2. Swagger aberto.
3. Frontend Flutter rodando no Chrome.
4. Login com usuário administrador.
5. Dashboard carregado com dados reais.
6. Menu lateral funcionando.
7. Tela de organizações.
8. Tela de eventos.
9. Tela financeira.
10. Tela de eventos de um viewer, exibindo somente os eventos da própria organização.
11. Logout.

---

## 17. Conclusão dos testes

Ao final dos testes, o frontend deve demonstrar:

- Interface web funcional.
- Login integrado ao backend.
- Uso de token JWT.
- Consumo de endpoints protegidos.
- Exibição de dados reais vindos do banco.
- Navegação básica por menu lateral.
- Integração entre Flutter Web e FastAPI.
- Restrição dos dados exibidos à organização do usuário viewer.

O frontend desenvolvido atende ao objetivo de apresentar uma interface mínima funcional para o sistema Administra+.