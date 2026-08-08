# PetFind

Plataforma colaborativa com geolocalização e notificações por proximidade para busca de animais perdidos, desenvolvida como projeto de aplicação prática do TCC de Erick Furtado da Silva e João Victor Fiuza Santos (UniRV).

Este repositório contém:

- **`backend/`** — API REST em Node.js + Express, usando SQLite (via Sequelize) como banco de dados, adequado para ambiente de teste local.
- **`mobile/`** — Aplicativo Flutter (Android) que consome a API.

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (canal stable) + Android SDK/emulador (Android Studio)
- [Node.js](https://nodejs.org/) 18+

## Rodando o back-end

```bash
cd backend
npm install
npm run seed   # popula o banco com usuários, casos e avistamentos de exemplo
npm run dev    # inicia em http://localhost:3000
```

Usuários de teste criados pelo seed (senha `123456` para todos):

| E-mail | Papel |
|---|---|
| ana@petfind.com | Tutora do caso "Thor" |
| bruno@petfind.com | Tutor do caso "Mimi" |
| carla@petfind.com | Colaboradora (já registrou avistamentos) |
| diego@petfind.com | Usuário fora do raio de notificação (para testar filtro por proximidade) |

## Rodando o app Flutter

```bash
cd mobile
flutter pub get
flutter run
```

Por padrão o app aponta para `http://10.0.2.2:3000`, que é como o **emulador Android** enxerga o `localhost` da máquina host (veja `mobile/lib/utils/constants.dart`). Se for testar em um celular físico na mesma rede Wi-Fi, troque `kApiBaseUrl` pelo IP da máquina (ex.: `http://192.168.0.10:3000`).

## Simplificações do ambiente de teste

Este projeto segue a arquitetura de 3 camadas definida no TCC (app mobile + API REST + banco de dados), mas com adaptações para viabilizar testes locais sem custos de infraestrutura:

- **Banco de dados**: SQLite no lugar do PostgreSQL especificado no documento original.
- **Notificações**: como o Firebase Cloud Messaging (citado no TCC) exige projeto configurado, as notificações por proximidade (RF-008) são persistidas no back-end e exibidas na tela de notificações do app. Não há push nativo quando o app está fechado.
- **Recuperação de senha**: como não há serviço de e-mail configurado, o código de verificação (RF-003) é logado no console do servidor e devolvido na resposta da API em modo de teste (`devCode`), em vez de enviado por e-mail real.
- **Fotos**: armazenadas em disco no servidor (`backend/uploads/`) e servidas como arquivo estático.

## Requisitos funcionais implementados

RF-001 (Manter Usuário), RF-002 (Login), RF-003 (Recuperar Senha), RF-004 (Manter Animal Perdido), RF-005 (Listar Casos Ativos), RF-006 (Registrar Avistamento), RF-007 (Visualizar Mapa), RF-008 (Notificações por Proximidade), RF-009 (Encerrar Caso) e RF-010 (Confirmar/Excluir Avistamento) — conforme especificado no relatório de DERS do TCC.
