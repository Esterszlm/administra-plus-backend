# Roteiro de Apresentação — Administra+

Este documento apresenta um roteiro para demonstrar o sistema Administra+ durante a apresentação do TCC.

O objetivo é explicar o problema, a solução desenvolvida, as tecnologias utilizadas, as funcionalidades implementadas e demonstrar o sistema funcionando.

---

## 1. Apresentação inicial do projeto

O Administra+ é um sistema administrativo desenvolvido para auxiliar organizações na gestão de informações internas.

O sistema foi pensado para atender organizações como:

- Igrejas.
- Associações.
- Pequenas empresas.
- Organizações comunitárias.
- Instituições que precisam controlar eventos, usuários, permissões e lançamentos financeiros.

A proposta do sistema é centralizar informações administrativas em uma única plataforma, permitindo maior organização, controle e segurança no acesso aos dados.

---

## 2. Problema identificado

Muitas organizações pequenas ou comunitárias ainda controlam suas informações de forma manual, usando:

- Planilhas.
- Cadernos.
- Grupos de mensagens.
- Anotações separadas.
- Controles financeiros sem padronização.

Isso pode gerar problemas como:

- Perda de informações.
- Dificuldade para consultar dados.
- Falta de controle de permissões.
- Falta de organização em eventos.
- Falta de visão consolidada do financeiro.
- Dependência de poucas pessoas para acessar informações importantes.

---

## 3. Solução proposta

Como solução, foi desenvolvido o Administra+, uma aplicação com backend em FastAPI e frontend em Flutter Web.

O sistema permite:

- Gerenciar organizações.
- Gerenciar usuários.
- Controlar permissões.
- Cadastrar e listar eventos.
- Registrar confirmações de presença.
- Registrar lançamentos financeiros.
- Exibir um dashboard com informações consolidadas.
- Proteger rotas com autenticação JWT.
- Aplicar controle de acesso baseado em permissões.

---

## 4. Tecnologias utilizadas

O projeto foi desenvolvido utilizando as seguintes tecnologias:

### Backend

- Python.
- FastAPI.
- SQLAlchemy.
- SQLite.
- JWT para autenticação.
- Passlib para hash de senhas.
- Swagger para documentação e testes da API.
- pytest para testes automatizados.

### Frontend

- Flutter.
- Dart.
- Flutter Web.
- Biblioteca HTTP para consumo da API.

### Versionamento

- Git.
- GitHub.

---

## 5. Arquitetura geral do sistema

O sistema foi dividido em duas partes principais:

### Backend

Responsável pelas regras de negócio, banco de dados, autenticação, permissões e disponibilização das rotas da API.

Principais módulos do backend:

- Usuários.
- Organizações.
- Eventos.
- Confirmações.
- Financeiro.
- Permissões.
- Dashboard.

### Frontend

Responsável pela interface visual utilizada pelo usuário.

Funcionalidades implementadas no frontend:

- Tela de login.
- Consumo da API.
- Armazenamento temporário do token JWT durante a navegação.
- Dashboard.
- Listagem de organizações.
- Listagem de eventos.
- Listagem financeira.
- Menu lateral.
- Logout.

---

## 6. Autenticação e segurança

O sistema utiliza autenticação baseada em JWT.

O funcionamento é o seguinte:

1. O usuário informa e-mail e senha.
2. O backend valida as credenciais.
3. Se estiver correto, o backend retorna um token JWT.
4. O frontend utiliza esse token para acessar rotas protegidas.
5. O backend verifica o token antes de permitir o acesso aos dados.

A chave usada para assinar os tokens é lida de uma variável de ambiente e não fica escrita no código-fonte. Sem a variável, o sistema gera uma chave aleatória a cada inicialização.

Além disso, o sistema possui controle de permissões.

O usuário administrador possui acesso total ao sistema.

Usuários do tipo viewer possuem acesso limitado, de acordo com as permissões atribuídas.

---

## 7. Controle de permissões

O Administra+ possui permissões específicas para controlar o acesso às funcionalidades.

Exemplos de permissões:

- `organizations_view`
- `organizations_create`
- `organizations_edit`
- `organizations_delete`
- `events_view`
- `events_create`
- `events_edit`
- `events_delete`
- `finance_view`
- `finance_create`
- `finance_edit`
- `finance_delete`
- `users_view`
- `users_create`
- `permissions_view`
- `permissions_assign`
- `dashboard_view`

Esse modelo permite que o sistema tenha maior controle sobre quais usuários podem acessar ou executar determinadas ações.

Além da permissão de módulo, a API verifica se cada registro pertence à organização do usuário. Assim, um usuário viewer consulta e altera apenas dados da própria organização, enquanto o administrador acessa todas.

---

## 8. Funcionalidades implementadas no backend

O backend possui as seguintes funcionalidades implementadas:

### Usuários

- Cadastro de usuários.
- Listagem de usuários.
- Edição de usuários.
- Exclusão de usuários.
- Validação de e-mail duplicado.
- Validação de organização vinculada.
- Bloqueio para impedir exclusão do próprio usuário.
- Bloqueio para impedir remoção do último administrador.

### Organizações

- Cadastro de organizações.
- Listagem de organizações.
- Edição de organizações.
- Exclusão de organizações.
- Validação de documento duplicado.
- Validação de organização inexistente.

### Eventos

- Cadastro de eventos.
- Listagem de eventos.
- Edição de eventos.
- Exclusão de eventos.
- Validação de organização inexistente.
- Bloqueio de exclusão de evento com confirmações vinculadas.

### Confirmações

- Registro de confirmação de presença.
- Listagem de confirmações.
- Validação de evento inexistente.
- Bloqueio de confirmação duplicada pelo mesmo usuário.
- Validação de status permitido.

### Financeiro

- Cadastro de lançamentos financeiros.
- Listagem de lançamentos financeiros.
- Edição de lançamentos financeiros.
- Exclusão de lançamentos financeiros.
- Validação de valor maior que zero.
- Validação de tipo financeiro.
- Validação de organização vinculada.

### Dashboard

- Total de organizações.
- Total de usuários.
- Total de eventos.
- Total de confirmações.
- Total de lançamentos financeiros.
- Total de entradas.
- Total de saídas.
- Saldo final.

---

## 9. Funcionalidades implementadas no frontend

O frontend foi desenvolvido em Flutter Web e possui uma interface simples para demonstrar a integração com o backend.

Funcionalidades implementadas:

- Tela de login.
- Autenticação com usuário administrador.
- Acesso ao dashboard.
- Exibição dos dados consolidados do backend.
- Menu lateral de navegação.
- Tela de organizações.
- Tela de eventos.
- Tela financeira.
- Botão de atualizar dados.
- Botão de sair.

---

## 10. Demonstração prática do sistema

Durante a apresentação, seguir a sequência abaixo.

### Passo 1 — Mostrar o backend rodando

Abrir o terminal na pasta principal do projeto e executar:

```bash
uvicorn main:app --reload
```

Explicar que o backend é responsável pela API, regras de negócio, autenticação, permissões e banco de dados.

---

### Passo 2 — Mostrar o Swagger

Acessar:

```text
http://127.0.0.1:8000/docs
```

Mostrar que a API possui rotas organizadas para:

- Usuários.
- Organizações.
- Eventos.
- Confirmações.
- Financeiro.
- Permissões.
- Dashboard.

Explicar que o Swagger foi utilizado para testar as rotas durante o desenvolvimento.

---

### Passo 3 — Mostrar o frontend rodando

Abrir outro terminal na pasta do frontend:

```text
C:\Users\ester\OneDrive\Documentos\Administra+_api\administra_app
```

Executar:

```bash
flutter run -d chrome
```

Explicar que o Flutter Web foi utilizado para criar a interface visual do sistema.

---

### Passo 4 — Fazer login

Na tela de login, usar:

```text
E-mail: admin@email.com
Senha: 123456
```

Explicar que o login envia as credenciais para o backend e recebe um token JWT.

---

### Passo 5 — Mostrar o dashboard

Após o login, demonstrar os cards do dashboard:

- Organizações.
- Usuários.
- Eventos.
- Confirmações.
- Lançamentos.
- Entradas.
- Saídas.
- Saldo final.

Explicar que esses dados são buscados diretamente do backend.

---

### Passo 6 — Mostrar o menu lateral

Abrir o menu lateral e mostrar as opções:

- Dashboard.
- Organizações.
- Eventos.
- Financeiro.
- Sair.

---

### Passo 7 — Mostrar organizações

Clicar em `Organizações`.

Explicar que o frontend consome a rota:

```http
GET /organizations/
```

Mostrar os cards com os dados das organizações cadastradas.

---

### Passo 8 — Mostrar eventos

Clicar em `Eventos`.

Explicar que o frontend consome a rota:

```http
GET /events/
```

Mostrar os eventos cadastrados e seus dados principais.

Em seguida, entrar com um usuário viewer que tenha permissão de eventos e mostrar que ele visualiza somente os eventos da própria organização.

---

### Passo 9 — Mostrar financeiro

Clicar em `Financeiro`.

Explicar que o frontend consome a rota:

```http
GET /finance/
```

Mostrar os lançamentos financeiros cadastrados.

---

### Passo 10 — Mostrar logout

Clicar em `Sair`.

Explicar que o usuário retorna para a tela de login.

---

## 11. Dados de teste

O sistema possui um script para criar dados iniciais:

```bash
python seed_data.py
```

Usuário administrador:

```text
username: admin@email.com
password: 123456
```

Usuário viewer:

```text
username: maria@email.com
password: 123456
```

O usuário administrador possui acesso total.

A usuária Maria possui acesso limitado de acordo com as permissões atribuídas.

Essas credenciais servem apenas para demonstração no ambiente local e devem ser trocadas antes de qualquer publicação do sistema.

---

## 12. Validações importantes implementadas

Durante o desenvolvimento, foram implementadas validações para evitar inconsistências.

Exemplos:

- Não permitir e-mail duplicado.
- Não permitir documento duplicado em organização.
- Não permitir evento vinculado a organização inexistente.
- Não permitir confirmação duplicada do mesmo usuário no mesmo evento.
- Não permitir lançamento financeiro com valor zero ou negativo.
- Não permitir tipo financeiro inválido.
- Não permitir exclusão física de usuários: a desativação preserva o histórico.
- Não permitir que o administrador desative a própria conta.
- Não permitir desativar ou rebaixar o último administrador ativo.
- Não permitir excluir evento com confirmações vinculadas.
- Não permitir acesso a dados de outra organização.

---

## 12.1 Avaliação experimental por testes automatizados

O controle de acesso foi avaliado com 33 casos de teste automatizados (pytest), em quatro categorias: autenticação, autorização por funcionalidade, isolamento entre organizações e regras de negócio.

| Versão | Casos aprovados |
| --- | --- |
| Original (`tcc-finalizacao`) | 25 de 33 (75,8%) |
| Corrigida (`tcc-versao-final`) | 33 de 33 (100%) |

Falhas encontradas na versão original:

- A chave de assinatura dos tokens JWT estava escrita no código-fonte público, o que permitia gerar um token de administrador sem senha.
- Os módulos de eventos, organizações, confirmações e dashboard não restringiam os dados à organização do usuário.

Após as correções, todos os casos foram aprovados. A comparação de desempenho mostrou que as verificações de isolamento não acrescentaram custo relevante ao tempo de resposta.

Para demonstrar:

```bash
python -m pytest tests -v
```

Resultado esperado: `33 passed`.

---

## 13. Evidências do projeto

O projeto possui arquivos de apoio para comprovar os testes e a organização do desenvolvimento:

- `README.md`
- `TESTES_BACKEND.md`
- `TESTES_FRONTEND.md`
- `ROTEIRO_APRESENTACAO.md`
- `requirements.txt`
- `seed_data.py`
- Pasta `tests/` com os testes automatizados.
- `benchmark_desempenho.py` com a comparação de desempenho.
- Branch `tcc-versao-final` no GitHub.
- Tags de versão no GitHub.

Tags criadas:

```text
v1.0-backend
v1.0-administra-plus
```

As tags apontam para versões anteriores às correções de segurança. A versão de entrega é a branch `tcc-versao-final`.

---

## 14. Limitações atuais

Como o projeto foi desenvolvido como um protótipo acadêmico, algumas funcionalidades ainda podem ser evoluídas futuramente.

Limitações atuais:

- Banco de dados local SQLite.
- Confirmação de presença sem fluxo completo na interface.
- Testes automatizados restritos ao backend.
- Listagem de eventos com uma consulta adicional por evento.
- Sem deploy em produção.
- Sem recuperação de senha.
- Sem autenticação por e-mail real.
- Sem integração com meios de pagamento.
- Sem envio automático de notificações.
- Sem relatórios em PDF.
- Sem aplicativo mobile publicado.

---

## 15. Trabalhos futuros

Como melhorias futuras, o sistema pode evoluir com:

- Migração para PostgreSQL.
- Deploy em nuvem.
- Confirmação de presença pela interface.
- Otimização das consultas da listagem de eventos.
- Armazenamento da chave JWT em um serviço de gerenciamento de segredos.
- Avaliação de usabilidade com usuários finais, mediante aprovação de Comitê de Ética em Pesquisa.
- Recuperação de senha.
- Controle financeiro mais detalhado.
- Relatórios exportáveis em PDF.
- Envio de notificações.
- Integração com WhatsApp ou e-mail.
- Melhorias visuais no frontend.
- Área específica para membros ou participantes.
- Auditoria de ações dos usuários.
- Backup automático.
- Adequação mais completa à LGPD.
- Autenticação em dois fatores.
- Integração com provedores externos de login.

---

## 16. Conclusão da apresentação

O Administra+ demonstra a aplicação prática dos conceitos estudados no curso, unindo backend, frontend, banco de dados, autenticação, segurança, permissões, versionamento e verificação por testes automatizados.

O sistema desenvolvido atende ao objetivo de criar uma solução administrativa funcional para organizações que precisam controlar usuários, eventos, confirmações, permissões e informações financeiras.

A solução apresenta uma base sólida que pode ser expandida futuramente para um produto mais completo.