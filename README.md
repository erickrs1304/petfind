# PetFind

Plataforma colaborativa com geolocalização e notificações por proximidade para busca de animais perdidos, desenvolvida como projeto de aplicação prática do TCC de Erick Furtado da Silva e João Victor Fiuza Santos (UniRV).

Este repositório contém:

- **`backend/`** — API REST em Node.js + Express, usando SQLite (via Sequelize) como banco de dados, adequado para ambiente de teste local.
- **`mobile/`** — Aplicativo Flutter (Android/Web) que consome a API.

---

## Passo a passo — rodando o projeto do zero

Este guia assume uma máquina **sem nada instalado** ainda. Se você já tem Node.js/Flutter instalados, pule direto para [Rodando o back-end](#rodando-o-back-end).

### 1. Obter o projeto

Este repositório é local (sem remoto configurado). Copie a pasta `petfind` inteira para a máquina onde você vai rodar o projeto (zip, pendrive, rede, etc.) — ou, se em algum momento um remoto Git for configurado, use `git clone <url>`.

### 2. Instalar os pré-requisitos

| Ferramenta | Para que serve | Como instalar |
|---|---|---|
| **Node.js 18+** | Rodar o back-end | [nodejs.org](https://nodejs.org/) (baixe a versão LTS) — no Windows também dá para usar `winget install -e --id OpenJS.NodeJS.LTS` |
| **Flutter SDK** (canal stable) | Rodar o app mobile | [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) — no Windows também dá para usar `winget install -e --id Google.Flutter` |
| **Git** (opcional) | Versionamento | [git-scm.com](https://git-scm.com/) |
| **Google Chrome** | Rodar o app como **Flutter Web** (caminho mais rápido, não precisa de Android SDK) | Provavelmente já instalado |
| **Android Studio** (opcional) | Rodar o app num **emulador/dispositivo Android** | [developer.android.com/studio](https://developer.android.com/studio) — só necessário se for testar em Android de verdade |

Depois de instalar, confirme que tudo está no `PATH` abrindo um terminal novo e rodando:

```bash
node --version
flutter --version
flutter doctor
```

O `flutter doctor` vai listar o que falta (ex.: licenças do Android SDK, se você for usar emulador Android). Para o caminho mais rápido — **Flutter Web**, sem emulador — você pode ignorar os itens marcados com `[✗]` relacionados a Android/iOS.

### 3. Rodando o back-end

```bash
cd backend
npm install
npm run seed   # cria o banco SQLite do zero e popula com usuários/casos de exemplo
npm run dev    # inicia em http://localhost:3000 (reinicia sozinho a cada alteração)
```

Não é necessário criar um arquivo `.env` — o servidor já tem valores padrão de desenvolvimento. Se quiser customizar (porta, segredo do JWT etc.), copie `backend/.env.example` para `backend/.env` e ajuste os valores.

Confirme que subiu corretamente:

```bash
curl http://localhost:3000/health
# esperado: {"status":"ok"}
```

Usuários de teste criados pelo seed (senha `123456` para todos):

| E-mail | Papel |
|---|---|
| ana@petfind.com | Tutora do caso "Thor" |
| bruno@petfind.com | Tutor do caso "Mimi" |
| carla@petfind.com | Colaboradora (já registrou avistamentos) |
| diego@petfind.com | Usuário fora do raio de notificação (para testar filtro por proximidade) |

### 4. Rodando o app — caminho rápido (Flutter Web, sem Android SDK)

Com o back-end já rodando (passo anterior), em outro terminal:

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

Isso abre o app direto no Chrome, já apontando para `http://localhost:3000`. É o jeito mais rápido de ver o projeto funcionando sem instalar Android Studio.

> **Nota sobre geolocalização na Web**: o navegador vai pedir permissão de localização quando o app tentar capturar o GPS (ex.: ao cadastrar um caso ou registrar um avistamento) — permita para o fluxo funcionar normalmente.

### 5. Rodando o app — emulador ou celular Android

1. Abra o Android Studio, complete o assistente de instalação do SDK (uma vez) e crie um emulador (**Device Manager → Create device**).
2. Rode `flutter doctor --android-licenses` e aceite as licenças.
3. Com o emulador aberto (ou um celular Android conectado via USB com depuração ativada):
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```
   Se houver mais de um dispositivo disponível, rode `flutter devices` primeiro e depois `flutter run -d <id-do-dispositivo>`.

Por padrão, no **emulador Android** o app já aponta para `http://10.0.2.2:3000` (o jeito que o emulador enxerga o `localhost` da máquina host) — não precisa configurar nada.

### 6. Rodando o app num celular físico (Android ou iPhone) na mesma rede Wi-Fi

Como o celular não enxerga `localhost` da máquina onde o back-end roda, é preciso apontar o app para o **IP da máquina na rede local**:

1. Descubra o IP da máquina (Windows: `ipconfig`; Mac/Linux: `ifconfig`) — algo como `192.168.1.38`.
2. Garanta que o celular está na **mesma rede Wi-Fi** do roteador ao qual essa máquina está conectada.
3. Rode o app passando esse IP via `--dart-define`:
   ```bash
   # Android físico (build nativo, via cabo USB)
   flutter run --dart-define=API_BASE_URL=http://192.168.1.38:3000

   # iPhone (ou qualquer navegador na rede) via Flutter Web
   flutter run -d web-server --web-port=5050 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=http://192.168.1.38:3000
   ```
   No caso do Web, depois abra `http://192.168.1.38:5050` no navegador do celular (ex.: Safari no iPhone) e permita o acesso à localização quando solicitado.
4. Se a conexão não for possível, o Firewall do Windows pode estar bloqueando a porta — libere manualmente (PowerShell como Administrador):
   ```powershell
   New-NetFirewallRule -DisplayName "PetFind Backend Dev" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
   New-NetFirewallRule -DisplayName "PetFind Flutter Web Dev" -Direction Inbound -Protocol TCP -LocalPort 5050 -Action Allow
   ```

> Não há como compilar um app iOS nativo sem um Mac com Xcode — o caminho acima (Flutter Web pelo navegador do iPhone) é a forma de testar em iPhone a partir de Windows/Linux.

### Solução de problemas comuns

- **`Failed to bind ... address already in use`** ao rodar o back-end ou o Flutter Web: já existe um processo usando a porta (3000 ou 5050). Encerre o processo antigo antes de subir um novo (Windows: `netstat -ano | findstr :3000` para achar o PID, depois `taskkill /PID <pid> /F`).
- **`flutter doctor` mostra `[✗] Android toolchain`**: só é um problema se você for rodar num emulador/dispositivo Android — para Flutter Web pode ignorar.
- **App não conecta na API**: confira se o back-end está rodando (`curl http://localhost:3000/health`) e se o `kApiBaseUrl` (ou o `--dart-define=API_BASE_URL=...`) aponta para o endereço certo a partir de onde o app está rodando (ver passos 4–6 acima).

---

## Simplificações do ambiente de teste

Este projeto segue a arquitetura de 3 camadas definida no TCC (app mobile + API REST + banco de dados), mas com adaptações para viabilizar testes locais sem custos de infraestrutura:

- **Banco de dados**: SQLite no lugar do PostgreSQL especificado no documento original.
- **Notificações**: como o Firebase Cloud Messaging (citado no TCC) exige projeto configurado, as notificações por proximidade (RF-008) são persistidas no back-end e exibidas na tela de notificações do app. Não há push nativo quando o app está fechado.
- **Recuperação de senha**: como não há serviço de e-mail configurado, o código de verificação (RF-003) é logado no console do servidor e devolvido na resposta da API em modo de teste (`devCode`), em vez de enviado por e-mail real.
- **Fotos**: armazenadas em disco no servidor (`backend/uploads/`) e servidas como arquivo estático.

## Requisitos funcionais implementados

RF-001 (Manter Usuário), RF-002 (Login), RF-003 (Recuperar Senha), RF-004 (Manter Animal Perdido), RF-005 (Listar Casos Ativos), RF-006 (Registrar Avistamento), RF-007 (Visualizar Mapa), RF-008 (Notificações por Proximidade), RF-009 (Encerrar Caso) e RF-010 (Confirmar/Excluir Avistamento) — conforme especificado no relatório de DERS do TCC.

Os fluxos alternativos do DERS também estão cobertos. Os menos óbvios, e onde encontrá-los no app:

| Fluxo do DERS | Onde está |
|---|---|
| RF-004 (3.2) — edição do caso pelo tutor | "Meus Casos" (ícone no topo da Home ou aba Perfil) → **Editar**; também em Detalhes do caso |
| RF-005 A1 — "Ampliar busca" quando não há casos no raio | Estado vazio da Home: dobra o raio (padrão 5 km) e mostra dicas de como ajudar |
| RF-005 A2 — GPS negado cai para a região do perfil | Aviso na Home: "Usando região do seu perfil. Ative o GPS para resultados mais precisos." |
| RF-005 A3 — busca por nome em tempo real | Campo de busca da Home (com *debounce* de 400 ms) |
| RF-007 A1 — "Compartilhar caso" | Tela do mapa e ícone de compartilhar nos detalhes do caso |
| RF-007 A2 — avistamentos no mesmo local agrupados | Mapa: marcador único com contador; ao tocar, lista os avistamentos daquele ponto |
| RF-009 (pós-condição) — "Meus Casos Encerrados" | "Meus Casos" → aba **Encerrados** (histórico preservado, não editável) |
| RF-009 (passo 8) — "Compartilhar boa notícia" | Diálogo exibido logo após encerrar o caso |
| RF-010 A2 — tutor confirmou por engano | Confirmar/excluir avistamentos → aba **Confirmados** → "Remover da trajetória" |

Ao encerrar um caso, os colaboradores que registraram avistamentos recebem uma notificação `CASO_ENCERRADO` avisando que o animal foi encontrado.

Regra adicional (não documentada no DERS original): o tutor de um animal não pode registrar um avistamento do próprio animal — se ele o encontrou, deve encerrar o caso (RF-009) em vez de "avistar" e aguardar confirmação de si mesmo.
