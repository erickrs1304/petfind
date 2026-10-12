const fs = require('fs');

// Push via Firebase Cloud Messaging (RF-008). A credencial vem de
// FIREBASE_SERVICE_ACCOUNT (JSON em uma linha, usado no Vercel) ou de
// FIREBASE_SERVICE_ACCOUNT_FILE (caminho do arquivo, uso local). Sem nenhuma das
// duas o push fica desativado e as notificações continuam só dentro do app.
let appFirebase = null;

function lerCredencial() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  const arquivo = process.env.FIREBASE_SERVICE_ACCOUNT_FILE;
  if (arquivo && fs.existsSync(arquivo)) return JSON.parse(fs.readFileSync(arquivo, 'utf8'));
  return null;
}

function pushConfigurado() {
  return Boolean(process.env.FIREBASE_SERVICE_ACCOUNT || process.env.FIREBASE_SERVICE_ACCOUNT_FILE);
}

function obterMessaging() {
  if (!appFirebase) {
    const { initializeApp, cert } = require('firebase-admin/app');
    const credencial = lerCredencial();
    if (!credencial) return null;
    appFirebase = initializeApp({ credential: cert(credencial) });
  }
  return require('firebase-admin/messaging').getMessaging(appFirebase);
}

const ERROS_TOKEN_INVALIDO = ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'];

// Recebe as notificações recém-criadas ({ usuarioId, titulo, mensagem, referenciaAnimalId, tipo })
// e envia um push para cada celular dos destinatários. Nunca lança erro: uma falha
// de push não pode derrubar o cadastro do caso ou do avistamento.
async function enviarPush(notificacoes) {
  if (!pushConfigurado() || !notificacoes || !notificacoes.length) return;
  try {
    const { Usuario, Dispositivo } = require('../models');
    const ids = [...new Set(notificacoes.map((n) => n.usuarioId))];

    // RF-008 A1: quem desativou as notificações não recebe push (o contador no app permanece).
    const ativos = await Usuario.findAll({ where: { id: ids, notificacoesAtivas: true }, attributes: ['id'] });
    const idsAtivos = ativos.map((u) => u.id);
    if (!idsAtivos.length) return;

    const dispositivos = await Dispositivo.findAll({ where: { usuarioId: idsAtivos } });
    if (!dispositivos.length) return;

    const mensagens = [];
    for (const notificacao of notificacoes) {
      for (const dispositivo of dispositivos.filter((d) => d.usuarioId === notificacao.usuarioId)) {
        mensagens.push({
          token: dispositivo.token,
          notification: { title: notificacao.titulo, body: notificacao.mensagem },
          data: {
            tipo: String(notificacao.tipo || ''),
            animalId: notificacao.referenciaAnimalId != null ? String(notificacao.referenciaAnimalId) : '',
          },
          android: { priority: 'high', notification: { channelId: 'petfind_alertas', sound: 'default' } },
        });
      }
    }
    if (!mensagens.length) return;

    const messaging = obterMessaging();
    if (!messaging) return;
    const resposta = await messaging.sendEach(mensagens);

    const invalidos = [];
    resposta.responses.forEach((r, i) => {
      if (!r.success && r.error && ERROS_TOKEN_INVALIDO.includes(r.error.code)) invalidos.push(mensagens[i].token);
    });
    if (invalidos.length) await Dispositivo.destroy({ where: { token: invalidos } });
  } catch (err) {
    console.error('Falha ao enviar push:', err);
  }
}

module.exports = { enviarPush, pushConfigurado };
