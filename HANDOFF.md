# HANDOFF — PetFind (V&V / Entrega 1)

> Handoff gerado em 27/09/2026 a partir de uma sessão de diagnóstico + configuração de V&V. Substitui o `HANDOFF.md` anterior (datado de 24-25/08), que tratava da implementação inicial das telas — aquele trabalho está confirmado concluído (ver seção 1). Este arquivo documenta o que foi feito **depois** disso: diagnóstico de prontidão para a Entrega 1 do TCC e configuração das ferramentas de Verificação e Validação (V&V).

## 0. Contexto do projeto

TCC de Erick Furtado da Silva e João Victor Fiuza Santos (UniRV), orientador Prof. Julio Cesar Gomes. Relatório de DERS completo em `Relatorio_DERS-ErickFurtadoeJoaoVictorFiuza (8).pdf` (81 páginas, na raiz do repo) — é a fonte de verdade para requisitos (RF-001 a RF-010, cap. 2.8; RNF-001 a RNF-012, cap. 2.9).

O professor pediu: **Entrega 1** = finalizar a implementação + definir as ferramentas de V&V. **Entrega 2** = executar a V&V + iniciar a redação do relatório final.

Stack: backend Node.js/Express/Sequelize (SQLite) em `backend/`, app Flutter em `mobile/`.

## 1. Status da implementação — confirmado, não precisa refazer

Os 10 requisitos funcionais (RF-001 a RF-010) estão implementados nos dois lados (API + app), verificados linha a linha nesta sessão:

| RF | Onde está (backend) | Onde está (mobile) |
|---|---|---|
| RF-001 Manter Usuário | `routes/auth.js` (`/register`, `/me`) | `screens/auth/register_screen.dart`, `profile_screen.dart` |
| RF-002 Realizar Login | `routes/auth.js` (`/login`) — JWT + bloqueio após 3 tentativas falhas | `login_screen.dart` |
| RF-003 Recuperar Senha | `routes/auth.js` (`/forgot-password`, `/reset-password`) | `forgot_password_screen.dart` |
| RF-004 Manter Animal Perdido | `routes/animals.js` (`POST/GET/PUT /:id`), inclui edição | `create_case_screen.dart` (modo edição) |
| RF-005 Listar Casos Ativos | `routes/animals.js` (`GET /`) — proximidade, filtro, busca, fallback GPS | `home_screen.dart` |
| RF-006 Registrar Avistamento | `routes/animals.js` (`POST /:id/sightings`) | `register_sighting_screen.dart` |
| RF-007 Visualizar Mapa | `routes/animals.js` (`GET /:id/sightings`) — OpenStreetMap, não Google Maps | `map_screen.dart` |
| RF-008 Notificações por Proximidade | `services/notificationService.js` (Haversine em `utils/geo.js`) — in-app/pull, não push FCM | `notifications_screen.dart` |
| RF-009 Encerrar Caso | `routes/animals.js` (`POST /:id/close`) | `close_case_screen.dart` |
| RF-010 Confirmar/Excluir Avistamento | `routes/sightings.js` (`/confirm`, `/reject`) | `confirm_sightings_screen.dart` |

`flutter analyze` → 0 issues (última execução registrada em 25/08). Testado manualmente via Flutter Web + curl, funcionando.

**Não refazer a implementação dos RFs** — o gap real está em validação/teste, não em código faltando.

## 2. Divergências conhecidas em relação ao DERS — decisão já tomada

Decisão do usuário em 23/09: **manter como estão, documentar no relatório, não bloquear a entrega por causa disso.**

- Banco **SQLite** em vez de PostgreSQL (documentado no `README.md`, seção "Simplificações do ambiente de teste"). Migração para Postgres é trivial via Sequelize (só trocar `dialect` em `backend/src/database.js`) se algum dia for preciso.
- Notificações **in-app (pull via `GET /notifications`)** em vez de push real via Firebase Cloud Messaging. `flutter_local_notifications` está no `pubspec.yaml` mas **não é usado** em nenhum lugar do código — se sobrar tempo, ligar isso para pelo menos notificação local seria uma melhoria de baixo custo.
- Recuperação de senha por **código devolvido na resposta da API** (`devCode`) em vez de e-mail real.

## 3. Pendência real #1 — nunca validado em Android nativo

Só foi testado via Flutter Web num navegador automatizado. O Android SDK nunca foi configurado nesta máquina (`flutter doctor` acusava `Unable to locate Android SDK`). **Decisão do usuário em 23/09: adiado para a Entrega 2** (é tratado como parte da execução de V&V, não como item de implementação da Entrega 1).

Quando for fazer: abrir o Android Studio, completar o setup do SDK, criar um AVD (ou usar celular físico via USB), rodar `flutter run`, e então validar especificamente GPS (`geolocator`), câmera (`image_picker`), mapa (`flutter_map`) e notificação local — nenhum desses foi exercitado fora do navegador.

## 4. Pendência real #2 — ferramentas de V&V: parcialmente configuradas, precisa continuar

### O que já está pronto e verificado

Foi montada a base de testes automatizados do **backend** (não mexi no mobile ainda):

- `backend/package.json`: scripts novos — `npm test` (Jest + Supertest via `cross-env NODE_ENV=test`), `npm run test:coverage`, `npm run lint` (ESLint). `devDependencies` adicionadas: `jest@29.7.0`, `supertest@7.3.0`, `cross-env@7.0.3`, `eslint@8.57.1`.
- `backend/src/database.js`: agora usa SQLite **em memória** quando `NODE_ENV=test` (isolado do banco real `data/petfind.db`).
- `backend/.eslintrc.json`: config `eslint:recommended` + `no-unused-vars` com `ignoreRestSiblings: true` (evita falso-positivo em destructuring tipo `const { senhaHash, ...resto } = usuario`).
- `backend/tests/health.test.js` e `backend/tests/auth.test.js`: **8 testes** cobrindo RF-001 (cadastro: válido, senhas diferentes, e-mail inválido, e-mail duplicado) e RF-002 (login: válido, senha incorreta, bloqueio após 3 tentativas falhas — RNF-008).
- **Dependências já instaladas de verdade na máquina do usuário** (`npm install` já rodado, não precisa rodar de novo) — confirmado: `jest`, `supertest`, `cross-env`, `eslint` presentes em `node_modules`. Binário nativo do `sqlite3` (`build/Release/node_sqlite3.node`, é uma DLL Windows) conferido por checksum antes/depois — **intacto, não foi tocado**.
- `npm run lint` rodado na máquina real do usuário: **0 erros** (1 warning irrelevante pré-existente em `seed.js`, variável `diego` do seed não usada depois de criada — não mexer, é proposital).
- Os 8 testes foram verificados **passando 100%** (`Tests: 8 passed, 8 total`) — mas isso foi confirmado rodando o mesmo código num sandbox Linux isolado, não na máquina Windows real do usuário. O agente que ler este handoff não tinha como executar binário Windows a partir do ambiente Linux disponível, então **isso ainda precisa ser confirmado rodando `npm test` direto na máquina Windows do usuário** (comando único, dependências já instaladas).

### O que falta fazer (nesta ordem)

1. **Confirmar que `cd backend && npm test` passa na máquina real do usuário.** Se não passar, o erro provavelmente não é dos testes em si (já validados em Linux) — investigar diferença de ambiente antes de mexer na lógica dos testes.
2. **Escrever os testes automatizados que faltam no backend**, seguindo o mesmo padrão de `tests/auth.test.js` (Supertest contra `app` diretamente, sem subir servidor; `sequelize.sync({ force: true })` em `beforeAll`):
   - RF-003 (recuperar senha) — `POST /auth/forgot-password`, `POST /auth/reset-password`, incluindo código expirado/inválido.
   - RF-004/RF-009 (criar, editar, encerrar caso) — `routes/animals.js`.
   - RF-005 (listar/buscar casos) — ordenação por proximidade, filtro por espécie, busca por nome.
   - RF-006 (registrar avistamento) — incluir o caso de regra de negócio "tutor não pode avistar o próprio caso".
   - RF-007/RF-010 (avistamentos do mapa, confirmar/excluir) — `routes/sightings.js`.
   - RF-008 (notificações) — vale testar `utils/geo.js` (fórmula de Haversine) isolado como teste unitário puro, além do fluxo via `routes/notifications.js`.
   - Meta de cobertura sugerida: ≥70% nas rotas críticas (`npm run test:coverage`).
3. **Expandir os testes do Flutter** (`mobile/test/`). Hoje só existe `telas_novas_test.dart`, cobrindo um recorte de RF-004/RF-009/RF-010 (13 casos). RF-001, RF-002, RF-003, RF-005, RF-006, RF-007 e RF-008 não têm nenhum teste de widget. Seguir o padrão já usado (`helpers/fake_api.dart` como fake da API).
4. **Montar a planilha/roteiro de teste de aceitação** a partir dos Quadros 2–11 do DERS (cap. 2.8.3, páginas ~30-70 do PDF) — o DERS já define os critérios de aceite por RF, é só formatar como planilha de execução (Passo / Entrada / Resultado esperado / Resultado obtido / Status). Ainda não foi feito.
5. Ferramentas de V&V ainda só definidas no plano, não configuradas: `integration_test` (Flutter, para rodar no emulador Android real), coleção Postman/Insomnia da API, `autocannon` para benchmark de tempo de resposta (RNF-003, meta <3s), checklist de segurança/LGPD (RNF-008/009/012), matriz de compatibilidade Android (RNF-005).

## 5. Comandos úteis

```bash
# Backend — dependências já instaladas, só rodar:
cd backend
npm test              # roda os 8 testes atuais (Jest + Supertest)
npm run test:coverage # com relatório de cobertura
npm run lint           # ESLint (0 erros esperado)
npm run seed           # reseta o banco com dados de exemplo
npm run dev             # sobe a API em http://localhost:3000

# Mobile
cd mobile
flutter analyze
flutter test            # roda mobile/test/telas_novas_test.dart
flutter run -d chrome    # ou -d <device-id> num Android real
```

Login de teste (após `npm run seed`): `ana@petfind.com` / `123456` (tutora do caso "Thor").

## 6. Onde estão os detalhes completos

O diagnóstico completo (tabela de status por RF/RNF, matriz de rastreabilidade requisito→ferramenta→evidência, análise das divergências) está num documento à parte, criado durante a sessão que gerou este handoff: **PetFind — Diagnóstico e Plano de V&V (Entrega 1)**. Peça ao usuário o link se precisar do detalhamento completo — este handoff resume o essencial para continuar o trabalho sem precisar reabrir aquele documento.

## 7. Cuidado ao rodar `npm install` em ambiente diferente de Windows

O `sqlite3` do backend usa um binário nativo pré-compilado (`node_modules/sqlite3/build/Release/node_sqlite3.node`), especificamente para Windows (PE32+ DLL). Se algum agente for rodar `npm install` a partir de um ambiente Linux/Mac (ex.: WSL, container, CI), **cheque antes se esse binário continua um DLL Windows depois do install** (`file node_modules/sqlite3/build/Release/node_sqlite3.node`) — em teoria o `npm install` não deveria mexer nele se já satisfaz o lockfile (confirmado nesta sessão via checksum), mas vale a checagem, e um backup rápido da pasta `node_modules/sqlite3` antes de qualquer `npm install` fora do Windows é uma precaução barata.
