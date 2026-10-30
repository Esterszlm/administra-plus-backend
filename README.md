# Administra+

**Protótipo acadêmico de sistema de gestão administrativa** desenvolvido para o Trabalho de Conclusão de Curso (TCC) de Engenharia da Computação.

O Administra+ centraliza o cadastro de organizações, usuários, eventos, confirmações de presença e movimentações financeiras. A aplicação inclui autenticação, painel de indicadores e controle de acesso por permissões. Embora tenha sido inicialmente concebida para o contexto de igrejas, a proposta também se aplica a associações e outras organizações comunitárias.

> **Estado do projeto:** versão funcional para demonstração acadêmica, com backend FastAPI e frontend Flutter Web integrados. Não é uma solução homologada para produção.
>
> **Versão de entrega:** branch `tcc-versao-final`. A branch `tcc-finalizacao` preserva a versão anterior às correções de segurança, usada como base de comparação na avaliação experimental do TCC.

## Tecnologias

| Camada | Tecnologias |
| --- | --- |
| Backend | Python, FastAPI, SQLAlchemy |
| Banco de dados local | SQLite |
| Autenticação | JWT e armazenamento de senhas com hash (Passlib) |
| Interface | Flutter Web (Dart) |
| Documentação e testes de API | Swagger / OpenAPI, disponibilizado pelo FastAPI |
| Testes automatizados | pytest e cliente de testes do FastAPI |
| Versionamento | Git e GitHub |

## Funcionalidades implementadas

- **Autenticação:** login e identificação do usuário autenticado; bloqueio de autenticação para contas desativadas.
- **Dashboard:** indicadores administrativos e resumo financeiro, mediante autorização.
- **Organizações:** cadastro, consulta, atualização e operações administrativas disponíveis na API e na interface.
- **Eventos:** cadastro, consulta, edição e exclusão conforme as regras de negócio; proteção de exclusão quando há confirmações vinculadas.
- **Confirmações de presença:** registro e consulta por meio da API; validações de duplicidade e situação.
- **Usuários:** cadastro, consulta e edição; status ativo/desativado, data e motivo de desativação, com preservação do histórico relacionado.
- **Financeiro:** lançamentos de entrada e saída, associação opcional a usuários, consulta de histórico e resumo financeiro individual.
- **Permissões:** administrador define os módulos e as ações autorizadas para usuários do perfil `viewer`; telas e ações não autorizadas são ocultadas na interface. A API também utiliza validações de autorização.
- **Isolamento entre organizações:** usuários do perfil `viewer` consultam e alteram somente dados da própria organização em todos os módulos (organizações, eventos, confirmações, financeiro, usuários e dashboard). O administrador acessa todas as organizações.
- **Produtividade na interface:** pesquisa, filtros e exportação CSV nas telas em que esses recursos foram implementados.

A interface Flutter Web possui login, menu lateral, dashboard e telas de organizações, eventos, financeiro e usuários. O gerenciamento de permissões é acessível ao administrador no menu de ações dos usuários com perfil Visualizador.

## Estrutura principal

```text
Administra+_api/
├── main.py
├── database.py
├── models.py
├── schemas.py
├── auth.py
├── requirements.txt
├── seed_data.py
├── migrar_catalogo_permissoes.py
├── benchmark_desempenho.py
├── tests/
│   ├── conftest.py
│   └── test_administra.py
├── routers/
│   ├── users.py
│   ├── organizations.py
│   ├── events.py
│   ├── confirmations.py
│   ├── finance.py
│   ├── permissions.py
│   └── dashboard.py
├── administra_app/
│   ├── pubspec.yaml
│   └── lib/
│       ├── app/
│       ├── core/
│       ├── screens/
│       ├── services/
│       └── widgets/
└── README.md
```

O banco local `administra.db` é gerado ou mantido no ambiente de desenvolvimento e **não deve ser enviado ao GitHub**. Também não devem ser publicados backups, arquivos `.env`, tokens ou credenciais privadas.

## Pré-requisitos

- Python e `pip`, compatíveis com as dependências de `requirements.txt`.
- Flutter SDK com suporte a Web, Dart e navegador Chrome.
- Git, caso o projeto seja obtido pelo repositório.

Os exemplos seguintes usam **PowerShell no Windows** e partem da pasta raiz `Administra+_api`.

## Executar o backend

### 1. Preparar o ambiente

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Se as dependências já estiverem instaladas em um ambiente virtual existente, reutilize-o. Se o Python do computador já tiver as dependências instaladas, a ativação do ambiente virtual pode ser dispensada.

### 2. Preparar o banco de dados

Para a **primeira execução**, inicialize os dados de demonstração conforme o script existente:

```powershell
python seed_data.py
```

O repositório possui também um script para cadastrar permissões padronizadas ainda ausentes:

```powershell
python migrar_catalogo_permissoes.py
```

**Importante:** execute o script de catálogo apenas após existir um banco SQLite inicializado, com as tabelas necessárias. Ele cria backup antes de inserir permissões faltantes, mas **não substitui migrações de estrutura** nem recupera o banco de desenvolvimento original.

Em um banco preexistente, preserve uma cópia de segurança e confirme previamente se as migrações de status de usuários e vínculos financeiros já foram aplicadas. Evite executar scripts de alteração de dados indiscriminadamente.

Os acessos de demonstração eventualmente definidos no `seed_data.py` destinam-se somente ao ambiente local. Não utilize essas credenciais em produção nem publique dados reais.

### 3. Iniciar a API

```powershell
uvicorn main:app --reload
```

Sem ambiente virtual, use `python -m uvicorn main:app --reload`.

**Chave de assinatura dos tokens:** a chave JWT é lida da variável de ambiente `ADMINISTRA_SECRET_KEY`. Se a variável não estiver definida, o sistema gera uma chave aleatória a cada inicialização; nesse caso, ao reiniciar o backend, é necessário fazer login novamente. Para manter a sessão entre reinícios no ambiente local:

```powershell
$env:ADMINISTRA_SECRET_KEY = "uma-chave-longa-e-aleatoria"
uvicorn main:app --reload
```

Nunca escreva a chave no código-fonte nem a envie ao GitHub.

Documentação interativa: <http://127.0.0.1:8000/docs>

A documentação OpenAPI expõe os endpoints disponíveis na versão efetivamente executada, sendo a referência para parâmetros e esquemas das requisições.

## Executar o frontend Flutter Web

**Mantenha a API em execução** e abra um segundo terminal na pasta raiz do projeto:

```powershell
cd administra_app
flutter pub get
flutter run -d chrome
```

Para realizar a análise estática do aplicativo:

```powershell
flutter analyze
```

O endereço do backend é definido em `lib/screens/login_page.dart` (`http://127.0.0.1:8000`). Em execução local, verifique o endereço e a porta utilizados pela API.

## Controle de acesso

Existem dois perfis básicos:

| Perfil | Comportamento |
| --- | --- |
| `admin` | Acesso administrativo aos módulos e gerenciamento das permissões dos visualizadores. |
| `viewer` | Acesso apenas às funcionalidades concedidas pelo administrador. |

O catálogo delegável utilizado na interface administrativa contempla:

| Módulo | Permissões disponíveis |
| --- | --- |
| Dashboard | `dashboard_view` |
| Organizações | `organizations_view`, `organizations_create`, `organizations_edit`, `organizations_delete` |
| Eventos | `events_view`, `events_create`, `events_edit`, `events_delete` |
| Financeiro | `finance_view`, `finance_create`, `finance_edit`, `finance_delete` |
| Usuários | `users_view`, `users_create`, `users_edit` |

As permissões de administração do próprio catálogo não são delegadas pelo painel de permissões dos visualizadores. Esconder menus no Flutter é um recurso de usabilidade: a restrição efetiva precisa ser conferida também nos endpoints do FastAPI.

**Isolamento por organização:** além da permissão de módulo, a API verifica se o registro pertence à organização do usuário (função `ensure_same_organization`, em `auth.py`). Esse comportamento é verificado pelos testes automatizados. Cada usuário pertence a uma única organização; o vínculo a várias organizações permanece como melhoria futura.

## Testes automatizados

A pasta `tests/` contém 33 casos de teste do backend, organizados em quatro categorias: autenticação (8), autorização por funcionalidade (6), isolamento entre organizações (11) e regras de negócio (8). Os testes criam um banco temporário próprio e **não alteram** o `administra.db` de desenvolvimento.

```powershell
python -m pip install pytest httpx
python -m pytest tests -v
```

Resultado esperado: `33 passed`.

Na versão anterior às correções (branch `tcc-finalizacao`), 25 dos 33 casos eram aprovados. As falhas correspondiam à chave JWT fixa no código-fonte e à falta de isolamento entre organizações nos módulos de eventos, organizações, confirmações e dashboard.

O script `benchmark_desempenho.py` compara o tempo de resposta de rotas da API em uma base de testes também temporária:

```powershell
python benchmark_desempenho.py . resultado.json
```

## Principais endpoints

Algumas rotas utilizadas na aplicação e na documentação existente:

| Finalidade | Endpoint |
| --- | --- |
| Login | `POST /users/login` |
| Usuário autenticado | `GET /me` |
| Usuários | `GET /users/`, `POST /users/`, `PUT /users/{user_id}` |
| Organizações | `GET /organizations/`, `POST /organizations/`, `PUT /organizations/{organization_id}` |
| Eventos | `GET /events/`, `POST /events/`, `PUT /events/{event_id}` |
| Confirmações | `GET /confirmations/`, `POST /confirmations/` |
| Financeiro | `GET /finance/`, `POST /finance/`, `PUT /finance/{finance_id}` |
| Resumo financeiro individual | `GET /finance/users/{user_id}/summary` |
| Dashboard | `GET /dashboard/` |
| Permissões do usuário logado | `GET /permissions/me` |
| Catálogo administrável | `GET /permissions/catalog` |
| Permissões atribuídas a um usuário | `GET /permissions/user/{user_id}` |
| Atualizar permissões de um usuário | `PUT /permissions/user/{user_id}/set` |

A lista é **resumida**, não exaustiva. Consulte `/docs` para confirmar as operações de exclusão, desativação/reativação, autenticação e demais endpoints da versão em execução.

## Roteiro curto de validação para apresentação

1. Iniciar backend e Flutter Web; confirmar que a interface consegue acessar a API.
2. Autenticar como administrador e abrir o dashboard.
3. Consultar os cadastros de organizações, eventos, financeiro e usuários.
4. Abrir o histórico financeiro individual de um usuário e verificar os lançamentos associados.
5. Consultar detalhes de um usuário desativado, incluindo motivo, e verificar que seu histórico financeiro foi preservado.
6. Abrir **Usuários → menu de três pontos → Gerenciar permissões** de uma conta `viewer` e liberar apenas **Organizações → Visualizar**.
7. Entrar com essa conta em uma nova sessão e confirmar que os outros módulos não aparecem; conferir em `/docs` que o endpoint de um módulo não autorizado devolve `403`.
8. Com um `viewer` que tenha permissão de eventos, confirmar que a tela de Eventos exibe somente os eventos da organização desse usuário, enquanto o administrador visualiza os eventos de todas as organizações.
9. Executar `python -m pytest tests -v` e confirmar `33 passed`.
10. Demonstrar pesquisa, filtragem e exportação CSV em uma tela compatível.

Este roteiro indica **o que deve ser testado**; não comprova que todas as verificações foram executadas na versão final.

## Documentação complementar

Conforme o material já documentado no projeto, existem roteiros e checklists destinados a apoiar a validação e a apresentação:

- `TESTES_BACKEND.md`
- `TESTES_FRONTEND.md`
- `ROTEIRO_APRESENTACAO.md`
- `CHECKLIST_FINAL_TCC.md`

A presença e a versão efetiva desses arquivos devem ser conferidas na branch destinada à entrega.

## Limitações e evolução futura

O Administra+ é um **protótipo acadêmico executado localmente**. Para uma eventual implantação comercial, seriam necessárias etapas adicionais de segurança, operação e conformidade, incluindo:

- Possibilidade de vincular um usuário a múltiplas organizações, com regras de autorização explícitas.
- Armazenamento da chave JWT em um serviço de gerenciamento de segredos.
- Otimização da listagem de eventos, que hoje executa uma consulta adicional por evento para obter o nome da organização.
- Testes automatizados do frontend, testes de carga com tráfego de rede, auditoria, monitoramento, backups e plano de recuperação.
- Troca das credenciais de demonstração do `seed_data.py` antes de qualquer publicação.
- Avaliação de usabilidade com usuários finais, mediante aprovação de Comitê de Ética em Pesquisa.
- Adequações à LGPD e políticas de privacidade e retenção.
- Avaliação de PostgreSQL e infraestrutura de implantação.
- Recuperação de senha, notificações e outras melhorias de experiência.

Esses itens **não são declarados como funcionalidades concluídas** na versão atual.

## Versionamento e entrega

Repositório: <https://github.com/Esterszlm/administra-plus-backend>

- **Branch de entrega:** `tcc-versao-final` (citada no artigo do TCC)
- **Branch anterior às correções:** `tcc-finalizacao` (base de comparação)
- **Escopo da entrega:** código-fonte do backend e do Flutter Web, testes automatizados, documentação e evidências requeridas pela instituição.

As tags antigas (`v1.0-backend`, `v1.0-administra-plus`) apontam para versões anteriores e não incluem as correções de segurança.

---

**Administra+ — TCC em Engenharia da Computação.**
