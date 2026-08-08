# HANDOFF — PetFind

## Onde parou e por quê

Ponto seguro. Backend e app mobile estão implementados por completo (todos os
RF-001 a RF-010 do TCC), compilam sem erros (`flutter analyze` limpo) e foram
validados manualmente rodando os dois juntos (backend Node.js + Flutter Web)
via Claude Browser. Um bug real foi encontrado durante o teste manual e **já
foi corrigido** (ver seção "Bugs encontrados e corrigidos"). A conversa foi
interrompida no meio de uma rodada de teste visual das telas de Notificações
e Perfil — não há nada quebrado, só faltou terminar de olhar essas duas
telas e testar no emulador Android de verdade (ainda não configurado).

Leia primeiro o plano original em
`C:\Users\Matheus\.claude\plans\c-users-matheus-documents-petfind-relat-lively-key.md`
— ele tem o contexto completo dos requisitos do TCC (RF-001 a RF-010, RNF-001
a RNF-012, entidades do diagrama de classes/ER) e as decisões de arquitetura
que o usuário aprovou. Este HANDOFF complementa o plano com o que mudou na
prática durante a implementação.

## O que já foi feito

### 1. Leitura do TCC
O PDF `Relatorio_DERS-ErickFurtadoeJoaoVictorFiuza (8).pdf` (81 páginas) foi
lido por completo com `pypdf`/`pdfplumber` (poppler não está instalado nesta
máquina, então o Read nativo de PDF não funciona — use Python se precisar
reler algo). Também extraímos as 12 imagens dos protótipos embutidas no PDF
(Figuras 2–13) com `pypdf` (`page.images`), pois elas continham o design real
das telas, não só os links do Google Photos citados no texto. As imagens
foram salvas em
`C:\Users\Matheus\AppData\Local\Temp\claude\...\scratchpad\prototipos\` (pasta
de scratchpad da sessão anterior — se não existir mais, re-extraia com o
mesmo método: `pypdf.PdfReader(...).pages[i].images`).

### 2. Decisões de arquitetura (confirmadas pelo usuário via AskUserQuestion)
- Arquitetura de 3 camadas mantida (app Flutter + API REST Node.js), mas
  **SQLite no lugar do PostgreSQL** (ambiente de teste).
- Mapa via **OpenStreetMap + `flutter_map`** (sem custo, sem API key) — não
  Google Maps.
- Notificações push reais (Firebase FCM) foram **simplificadas**: como não
  há projeto Firebase configurado, as notificações do RF-008 são persistidas
  no back-end e exibidas na tela de notificações do app. Documentado no
  `README.md` do projeto.
- Recuperação de senha (RF-003): sem serviço de e-mail configurado, o código
  de verificação é logado no console do servidor e devolvido em
  `devCode` na resposta da API (só em modo de teste). O app mostra esse
  código na tela para facilitar o teste manual.

### 3. Backend (`backend/`)
Node.js + Express + Sequelize (dialect sqlite) + bcryptjs + jsonwebtoken +
multer + zod. Banco em `backend/data/petfind.db` (criado via
`sequelize.sync()`).

- Modelos em `backend/src/models/`: `Usuario`, `Animal`, `Avistamento`,
  `Notificacao` — refletem o diagrama de classes/ER do TCC.
- Rotas em `backend/src/routes/`: `auth.js` (RF-001 a RF-003 + perfil),
  `animals.js` (RF-004 a RF-007, RF-009, RF-010), `sightings.js` (confirmar/
  excluir avistamento), `notifications.js` (RF-008).
- `backend/src/services/notificationService.js`: lógica de notificação por
  proximidade usando fórmula de Haversine (`backend/src/utils/geo.js`).
  Dispara notificação para o tutor sempre, e para outros usuários dentro do
  raio configurado por cada um (`raioNotificacaoKm`, default 5km).
- `backend/src/seed.js`: popula o banco com 4 usuários de teste (senha
  `123456` para todos: `ana@petfind.com`, `bruno@petfind.com`,
  `carla@petfind.com`, `diego@petfind.com`), 2 casos (Thor, Mimi) e alguns
  avistamentos/notificações. Rodar com `npm run seed`.
- **Vulnerabilidades do `npm audit`**: existem ~9 vulnerabilidades reportadas,
  todas em dependências transitivas de build nativo do `sqlite3`
  (`node-gyp`/`tar`/`cacache`) e do `uuid` usado internamente pelo
  `sequelize`. Decisão consciente de não fazer downgrade forçado (`npm audit
  fix --force` quebraria `sqlite3`/`sequelize`) — risco aceitável para
  back-end local de teste, não exposto à internet.
- Testado manualmente com `curl`/`Invoke-RestMethod`: registro, login,
  listagem de casos ordenada por distância, notificações — tudo funcionando.

### 4. App Flutter (`mobile/`)
Estrutura: `lib/data/` (models + repositories), `lib/providers/` (Provider/
ChangeNotifier), `lib/screens/` (uma pasta por área: `auth/`, `casos/`,
`avistamentos/`, `notificacoes/`), `lib/widgets/` (componentes
reutilizáveis), `lib/theme/`.

Todas as 11 telas do protótipo foram implementadas e depois **redesenhadas
para bater visualmente com as imagens reais extraídas do PDF** (não só a
descrição textual):
- `widgets/petfind_header.dart`: cabeçalho laranja em gradiente com cantos
  arredondados na base (padrão visual repetido em toda tela do protótipo) —
  componentes `PetFindHeader` e `PetFindScaffold`.
- `theme/app_theme.dart`: paleta laranja (`AppTheme.primary` =
  `0xFFFF7A45`), botões em pílula (`borderRadius: 30`), inputs cinza-claro
  sem borda visível, componente `SectionLabel` (rótulos de seção em caixa
  alta laranja, ex. "DADOS PESSOAIS").
- `widgets/status_chip.dart`: chip de status pílula (ex. "Desaparecido",
  "Confirmado").
- `widgets/dashed_photo_picker.dart`: área de foto com borda pontilhada
  (custom painter), como nas telas de cadastro de animal/avistamento.
- `screens/casos/close_case_screen.dart`: tela dedicada de encerramento de
  caso (RF-009) com card de sucesso em gradiente verde + resumo do caso,
  fiel à Figura 12 (antes era só um AlertDialog simples).
- `screens/avistamentos/map_screen.dart`: pins numerados (1 = última
  localização em vermelho, 2+ = avistamentos em laranja) conectados por
  linha pontilhada, legenda inferior — fiel à Figura 10.
- `screens/avistamentos/confirm_sightings_screen.dart`: cards com borda
  colorida à esquerda, badge numerado azul, botões de ação circulares
  (excluir vermelho / confirmar verde) — fiel à Figura 13.
- `screens/notificacoes/notifications_screen.dart`: cards com borda colorida
  à esquerda por tipo de notificação + seção de configurações (toggle de
  alertas por proximidade + editor de raio de alcance) — fiel à Figura 11.

Comparação visual tela a tela contra os prints reais do protótipo (login e
lista de casos) já foi feita e bateu muito bem. **Notificações e Perfil
ainda não foram comparados lado a lado** (a conversa foi interrompida nesse
ponto).

### 5. Ambiente instalado nesta máquina
- **Flutter 3.41.9** instalado via **Chocolatey** em `C:\tools\flutter`
  (não em `C:\src\flutter` — uma tentativa anterior via download direto foi
  abandonada por instabilidade de rede e o arquivo parcial foi apagado).
  Adicionar ao PATH da sessão: `$env:Path += ";C:\tools\flutter\bin"`
  (o instalador já adicionou ao PATH do usuário permanentemente, mas
  terminais já abertos precisam disso ou reabrir o terminal).
- **Android Studio** instalado via `winget install -e --id
  Google.AndroidStudio`, mas **o Android SDK ainda não foi configurado**
  (`flutter doctor` mostra `[X] Unable to locate Android SDK`). É preciso
  abrir o Android Studio pela primeira vez para baixar os componentes do SDK
  e criar um emulador (AVD) — isso ainda não foi feito.
- **Node.js LTS** (v24.19.0) já estava instalado, atualizado via winget.
- `flutter create --platforms=android,web .` já foi rodado dentro de
  `mobile/` para gerar as pastas `android/` e `web/` (preservando o
  `lib/`/`pubspec.yaml` que já existiam). O `test/widget_test.dart` padrão
  gerado foi apagado (referenciava uma classe `MyApp` que não existe no
  nosso `main.dart`).
- Aviso do `flutter create`: a versão do Java instalada (25) pode conflitar
  com a versão do Gradle (8.14) quando for buildar para Android de verdade.
  Ainda não testamos um build Android real, então isso pode precisar de
  ajuste (`flutter config --jdk-dir=<...>` ou atualizar o Gradle wrapper)
  quando chegar a hora.

### 6. Testado até agora
- `flutter analyze` → **0 issues**.
- Backend testado via `curl`: registro, login, listagem por proximidade,
  notificações.
- App testado rodando **Flutter Web** (`flutter run -d web-server
  --web-port=5050 --web-hostname=0.0.0.0`) + backend juntos, usando o Claude
  Browser (`preview_start` com `url: "http://localhost:5050"`, viewport
  mobile 375x812) — login, lista de casos, criação de caso, tela de mapa e
  tela de detalhes do caso foram abertos e bateram visualmente com o
  protótipo.

## Bugs encontrados e corrigidos durante o teste manual

1. **Botão "+" (novo caso) sem cor de fundo.** O `Ink` com `BoxDecoration`
   gradiente dentro de um `IconButton` não estava pintando (problema comum
   do widget `Ink` que depende de um `Material` ancestral pintar por baixo).
   Corrigido em `mobile/lib/screens/casos/home_screen.dart`: trocado por
   `Container` com gradiente + `Material(color: Colors.transparent) +
   InkWell` explícito.

2. **`dart:io File` usado para fotos — quebra completamente na Web.** Esse
   era o bug real por trás do erro "Não foi possível registrar o caso." que
   o usuário reportou. `image_picker` retorna um `XFile`; construir um
   `File(xfile.path)` e chamar `.length()` nele lança `UnsupportedError` no
   Flutter Web (não existe sistema de arquivos real lá — `path` é uma blob
   URL). Isso também fazia a prévia da foto falhar silenciosamente (sem
   aviso ao usuário, exatamente como relatado).
   **Correção**: criado `mobile/lib/data/models/picked_photo.dart` — uma
   classe `PickedPhoto { Uint8List bytes; String filename; }` cross-platform.
   Todos os pontos que usavam `File?` foram trocados por `PickedPhoto?`:
   - `mobile/lib/widgets/dashed_photo_picker.dart` (agora recebe
     `fotoBytes: Uint8List?` e usa `MemoryImage` em vez de `FileImage`)
   - `mobile/lib/screens/casos/create_case_screen.dart`
   - `mobile/lib/screens/avistamentos/register_sighting_screen.dart`
   - `mobile/lib/data/repositories/animal_repository.dart` (usa
     `MultipartFile.fromBytes(...)` em vez de `MultipartFile.fromFile(...)`)
   Essa correção vale tanto para Web quanto mobile (bytes em memória
   funcionam nos dois), então não há regressão para o build Android.

3. **Geolocalização bloqueada no navegador automatizado (não é bug do
   app).** O Claude Browser nega a permissão de geolocalização sem mostrar
   nenhum diálogo para aprovar (política do ambiente sandboxed). Isso por
   si só causava falha ao criar caso/avistamento durante o teste (pois o
   app depende de GPS real, corretamente, conforme RF-004/RF-006). Para
   conseguir testar os fluxos end-to-end mesmo assim, foi injetado via
   `javascript_tool` um mock de `navigator.geolocation.getCurrentPosition` /
   `watchPosition` retornando coordenadas fixas (-17.7929, -50.9188 — Rio
   Verde, GO) e um mock de `navigator.permissions.query` retornando
   `granted` para `geolocation`. **Esse mock precisa ser reinjetado toda
   vez que a página recarrega** (não é parte do código do app, é só um
   artifício de teste). Comando usado (ver histórico da conversa se
   precisar reaplicar): injeta as duas funções antes de qualquer ação que
   dependa de GPS.

## Ruído nos dados de teste

Durante o debug (cliques por coordenada que davam timeout mas ainda assim
registravam o clique, resultando em ações duplicadas/inesperadas), acabei
criando via UI um caso de teste extra chamado "Cachorro" com uma foto de
pato (imagem de teste de câmera falsa do Chrome) e alguns avistamentos
extras no caso "Thor". **Isso é só ruído no banco `backend/data/petfind.db`
local, não um problema de código.** Para limpar, rode de novo:
```bash
cd backend && npm run seed
```
(reseta o banco do zero com `sequelize.sync({ force: true })`, já configurado
no `seed.js`).

## O que falta

Em ordem sugerida:

1. **Terminar a comparação visual** das telas de Notificações e Perfil
   contra os prints do protótipo (extraídos em
   `scratchpad/prototipos/64_notificacoes_0.png` e não havia print de
   perfil isolado — Figura 3 é "edição do usuário", `35_edicao_perfil_0.png`).
   Se a pasta de scratchpad já não existir (sessão antiga), re-extrair do
   PDF com o script Python (`pypdf`, iterar `reader.pages[i].images`).
2. **Configurar o Android SDK de verdade**: abrir o Android Studio uma vez
   (`Start-Process "C:\Program Files\Android\Android Studio\bin\studio64.exe"`
   ou procurar o atalho instalado), completar o setup wizard, criar um AVD.
   Depois rodar `flutter doctor --android-licenses` e `flutter doctor` até
   ficar tudo verde.
3. **Testar no emulador Android de verdade** (não só Web) — validar que
   `geolocator`, `image_picker`, `flutter_local_notifications` e
   `flutter_map` funcionam nativamente (o teste na Web não cobre 100% do
   comportamento mobile, principalmente notificações locais).
4. Resolver o aviso de incompatibilidade Java 25 / Gradle 8.14 se o build
   Android falhar por causa disso.
5. Depois de validado no emulador, rodar `npm run seed` de novo no backend
   para garantir dados limpos antes de qualquer demonstração/gravação.

## Como verificar (comandos exatos)

**Analisar o app Flutter:**
```powershell
$env:Path += ";C:\tools\flutter\bin"
cd C:\Users\Matheus\Documents\petfind\mobile
flutter analyze
```
Esperado: `No issues found!`

**Subir o backend:**
```powershell
cd C:\Users\Matheus\Documents\petfind\backend
npm run seed   # só se quiser resetar os dados
node src/server.js
```
Esperado: `PetFind API rodando em http://localhost:3000`. Testar com
`Invoke-RestMethod http://localhost:3000/health` → `{"status":"ok"}`.

**Rodar o app na Web (mais rápido para iterar sem emulador Android):**
```powershell
$env:Path += ";C:\tools\flutter\bin"
cd C:\Users\Matheus\Documents\petfind\mobile
flutter run -d web-server --web-port=5050 --web-hostname=0.0.0.0
```
Depois abrir `http://localhost:5050` no Claude Browser
(`preview_start` com `url`), redimensionar para `mobile` preset, e — se for
testar qualquer fluxo com GPS — reinjetar o mock de geolocalização via
`javascript_tool` (ver seção de bugs acima) antes de clicar em qualquer
botão que capture localização.

**Quirk do Claude Browser**: os cliques por coordenada em apps Flutter Web
(renderizados em `<canvas>` via CanvasKit) são pouco confiáveis — o
`computer{action:"left_click"}` frequentemente estoura o timeout de 30s
mesmo quando o clique é entregue com sucesso. Sempre tirar um screenshot
novo logo antes de calcular a coordenada do próximo clique (o tamanho do
screenshot retornado varia entre 375x812 e 750x1624 dependendo do momento —
usar sempre as coordenadas do último screenshot, nunca reaproveitar de um
anterior).

**Login de teste (após `npm run seed`):** `ana@petfind.com` / `123456`
(tutora do caso "Thor").

## Como retomar

1. Ler o plano em
   `C:\Users\Matheus\.claude\plans\c-users-matheus-documents-petfind-relat-lively-key.md`.
2. Ler este `HANDOFF.md` inteiro.
3. Rodar a checklist da seção "Como verificar" acima para confirmar que o
   estado descrito ainda bate com a realidade antes de mexer em qualquer
   código.
4. Seguir a lista "O que falta", em ordem.

Apague este arquivo quando o app estiver validado no emulador Android e
pronto para entrega (não antes).
