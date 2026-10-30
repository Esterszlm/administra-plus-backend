# Checklist Final do TCC — Administra+

Este documento apresenta a checklist final do projeto Administra+, com os principais itens que devem ser conferidos antes da entrega e apresentação do TCC.

---

## 1. Código-fonte

- [ ] O backend está salvo na pasta principal do projeto.
- [ ] O frontend Flutter está salvo na pasta `administra_app`.
- [ ] O arquivo `main.py` está funcionando.
- [ ] O arquivo `auth.py` está funcionando.
- [ ] O arquivo `database.py` está funcionando.
- [ ] O arquivo `models.py` está funcionando.
- [ ] O arquivo `schemas.py` está funcionando.
- [ ] A pasta `routers/` contém os módulos principais da API.
- [ ] O arquivo `seed_data.py` está funcionando.
- [ ] O arquivo `requirements.txt` possui as dependências do backend.
- [ ] O arquivo `pubspec.yaml` possui as dependências do frontend Flutter.

---

## 2. Git e GitHub

- [ ] O projeto está versionado com Git.
- [ ] O repositório remoto está no GitHub.
- [ ] O último `git status` mostra `nothing to commit, working tree clean`.
- [ ] O arquivo `administra.db` não foi enviado ao GitHub.
- [ ] Arquivos de cache não foram enviados ao GitHub.
- [ ] O backend foi enviado ao GitHub.
- [ ] O frontend foi enviado ao GitHub.
- [ ] A documentação foi enviada ao GitHub.
- [ ] A branch de entrega é `tcc-versao-final`.
- [ ] A branch `tcc-finalizacao` foi preservada como versão anterior às correções.
- [ ] Os scripts auxiliares `aplicar_*.py` não foram enviados ao GitHub.
- [ ] Nenhuma chave, senha real ou arquivo `.env` foi enviado ao GitHub.

Tags criadas:

- [ ] `v1.0-backend`
- [ ] `v1.0-administra-plus`
- [ ] `v1.1-administra-plus-documentado`

---

## 3. Backend FastAPI

- [ ] O backend inicia com o comando:

```bash
uvicorn main:app --reload
```

- [ ] A API abre corretamente em:

```text
http://127.0.0.1:8000
```

- [ ] O Swagger abre corretamente em:

```text
http://127.0.0.1:8000/docs
```

- [ ] A rota inicial `GET /` retorna mensagem de API funcionando.
- [ ] A rota `/me` retorna o usuário autenticado.
- [ ] A autenticação JWT está funcionando.
- [ ] O botão `Authorize` do Swagger funciona com o usuário administrador.

---

## 4. Dados iniciais

- [ ] O script `seed_data.py` executa sem erro.
- [ ] O usuário administrador é criado ou verificado.
- [ ] A usuária Maria é criada ou verificada.
- [ ] As permissões principais são criadas ou verificadas.
- [ ] As permissões iniciais da Maria são criadas ou verificadas.

Usuário administrador:

```text
username: admin@email.com
password: 123456
```

Usuária Maria:

```text
username: maria@email.com
password: 123456
```

---

## 5. Organizações

- [ ] É possível listar organizações.
- [ ] É possível criar organização válida.
- [ ] O sistema bloqueia documento duplicado.
- [ ] O sistema valida organização inexistente quando necessário.
- [ ] O sistema retorna nome da organização nas respostas esperadas.

---

## 6. Usuários

- [ ] É possível listar usuários.
- [ ] É possível criar usuário válido.
- [ ] O sistema bloqueia e-mail duplicado.
- [ ] O sistema valida organização vinculada ao usuário.
- [ ] O sistema bloqueia exclusão do próprio usuário.
- [ ] O sistema bloqueia exclusão do último administrador.
- [ ] O sistema bloqueia alteração que remova o último administrador.

---

## 7. Eventos

- [ ] É possível listar eventos.
- [ ] É possível criar evento válido.
- [ ] O sistema bloqueia evento com organização inexistente.
- [ ] O sistema permite editar evento válido.
- [ ] O sistema bloqueia exclusão de evento com confirmações vinculadas.
- [ ] O sistema permite excluir evento sem confirmações vinculadas.

---

## 8. Confirmações

- [ ] É possível registrar confirmação válida.
- [ ] É possível listar confirmações.
- [ ] O sistema bloqueia confirmação para evento inexistente.
- [ ] O sistema bloqueia confirmação duplicada do mesmo usuário no mesmo evento.
- [ ] O sistema valida status permitido.

Status permitidos:

```text
confirmado
recusado
talvez
```

---

## 9. Financeiro

- [ ] É possível listar lançamentos financeiros.
- [ ] É possível criar lançamento financeiro válido.
- [ ] O sistema bloqueia valor zero.
- [ ] O sistema bloqueia valor negativo.
- [ ] O sistema bloqueia tipo financeiro inválido.
- [ ] O sistema aceita entrada.
- [ ] O sistema aceita saida.
- [ ] O sistema aceita saída com acento e normaliza corretamente.
- [ ] O sistema valida organização inexistente.

Tipos financeiros permitidos:

```text
entrada
saida
saída
```

---

## 10. Permissões

- [ ] O administrador possui acesso total.
- [ ] Usuários viewer dependem de permissões específicas.
- [ ] Rotas administrativas de permissões estão protegidas.
- [ ] Maria sem permissão administrativa recebe erro 403.
- [ ] Admin consegue listar permissões.
- [ ] Admin consegue atribuir permissões.
- [ ] Admin consegue remover permissões.

---

## 11. Dashboard

- [ ] A rota `GET /dashboard/` funciona com admin.
- [ ] O dashboard retorna total de organizações.
- [ ] O dashboard retorna total de usuários.
- [ ] O dashboard retorna total de eventos.
- [ ] O dashboard retorna total de confirmações.
- [ ] O dashboard retorna total de lançamentos financeiros.
- [ ] O dashboard retorna total de entradas.
- [ ] O dashboard retorna total de saídas.
- [ ] O dashboard retorna saldo final.
- [ ] Usuário sem permissão recebe erro 403.

---

## 12. Frontend Flutter Web

- [ ] O frontend inicia com o comando:

```bash
flutter run -d chrome
```

- [ ] O Chrome abre a aplicação.
- [ ] A tela de login aparece corretamente.
- [ ] O login com admin funciona.
- [ ] O frontend recebe o token JWT.
- [ ] O frontend acessa rotas protegidas usando o token.
- [ ] O dashboard aparece após o login.
- [ ] O menu lateral abre corretamente.
- [ ] A tela de organizações funciona.
- [ ] A tela de eventos funciona.
- [ ] A tela financeira funciona.
- [ ] O botão atualizar funciona.
- [ ] O botão sair retorna para o login.
- [ ] A acentuação dos textos aparece corretamente.

---

## 13. Documentação do projeto

- [ ] `README.md` explica o projeto.
- [ ] `README.md` explica como instalar dependências.
- [ ] `README.md` explica como rodar o backend.
- [ ] `README.md` explica como criar dados iniciais.
- [ ] `TESTES_BACKEND.md` possui roteiro de testes do backend.
- [ ] `TESTES_FRONTEND.md` possui roteiro de testes do frontend.
- [ ] `ROTEIRO_APRESENTACAO.md` possui roteiro para apresentar o projeto.
- [ ] `CHECKLIST_FINAL_TCC.md` foi criado para revisão final.
- [ ] `README.md` explica como rodar os testes automatizados.

---

## 13.1 Testes automatizados

- [ ] `python -m pytest tests -v` termina com `33 passed`.
- [ ] Os testes não alteraram o `administra.db` de desenvolvimento.
- [ ] Um viewer com permissão de eventos vê somente os eventos da própria organização.
- [ ] O administrador vê os eventos de todas as organizações.
- [ ] A tela de eventos abre para um viewer sem permissão de organizações.

---

## 14. Evidências para apresentação

Antes da apresentação, separar evidências como:

- [ ] Print do GitHub com os arquivos do projeto.
- [ ] Print do Swagger aberto.
- [ ] Print do backend rodando no terminal.
- [ ] Print do frontend rodando no Chrome.
- [ ] Print da tela de login.
- [ ] Print do dashboard.
- [ ] Print da tela de organizações.
- [ ] Print da tela de eventos.
- [ ] Print da tela financeira.
- [ ] Print das tags do GitHub.
- [ ] Print do terminal com `33 passed`.
- [ ] Print da tela de eventos de um viewer mostrando apenas a própria organização.

---

## 15. Sequência recomendada para demonstrar

Durante a apresentação, seguir esta ordem:

1. Explicar o problema.
2. Explicar a proposta do Administra+.
3. Mostrar as tecnologias usadas.
4. Mostrar o GitHub.
5. Rodar o backend.
6. Abrir o Swagger.
7. Fazer login pelo Swagger, se necessário.
8. Rodar o Flutter Web.
9. Fazer login no frontend.
10. Mostrar o dashboard.
11. Mostrar organizações.
12. Mostrar eventos.
13. Mostrar financeiro.
14. Mostrar logout.
15. Explicar segurança, permissões e isolamento entre organizações.
16. Mostrar os testes automatizados (`33 passed`).
17. Explicar limitações.
18. Explicar trabalhos futuros.

---

## 16. Limitações assumidas

- [ ] O projeto é um protótipo acadêmico.
- [ ] O banco utilizado é SQLite local.
- [ ] A confirmação de presença ainda não possui fluxo completo na interface.
- [ ] Os testes automatizados cobrem apenas o backend.
- [ ] O sistema ainda não possui deploy em produção.
- [ ] O sistema ainda não possui recuperação de senha.
- [ ] O sistema ainda não possui relatórios PDF.
- [ ] O sistema ainda não possui notificações automáticas.
- [ ] O sistema ainda não possui aplicativo publicado em loja.

---

## 17. Trabalhos futuros

- [ ] Migrar banco para PostgreSQL.
- [ ] Fazer deploy em nuvem.
- [ ] Criar fluxo de confirmação de presença na interface.
- [ ] Otimizar as consultas da listagem de eventos.
- [ ] Guardar a chave JWT em um serviço de gerenciamento de segredos.
- [ ] Criar recuperação de senha.
- [ ] Criar relatórios exportáveis.
- [ ] Criar notificações por e-mail ou WhatsApp.
- [ ] Melhorar layout visual.
- [ ] Implementar auditoria de ações.
- [ ] Implementar backup automático.
- [ ] Evoluir adequação à LGPD.
- [ ] Implementar autenticação em dois fatores.

---

## 18. Conclusão da checklist

O projeto Administra+ está pronto para ser apresentado quando:

- O backend estiver funcionando.
- O frontend estiver funcionando.
- O GitHub estiver atualizado.
- Os testes principais tiverem sido executados, incluindo os testes automatizados.
- A documentação estiver revisada.
- A apresentação estiver ensaiada.

Esta checklist deve ser usada como conferência final antes da entrega do TCC.