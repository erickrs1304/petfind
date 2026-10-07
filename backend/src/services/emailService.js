const nodemailer = require('nodemailer');

// Envio por SMTP (ex.: Gmail com senha de app). Sem SMTP_USER/SMTP_PASS o envio
// fica desativado e a recuperação de senha continua em "modo teste" (devCode).
function emailConfigurado() {
  return Boolean(process.env.SMTP_USER && process.env.SMTP_PASS);
}

function criarTransporte() {
  const porta = Number(process.env.SMTP_PORT || 465);
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: porta,
    secure: porta === 465,
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });
}

function escaparHtml(texto) {
  return String(texto).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}

// RF-003 - código de 6 dígitos válido por 15 minutos.
async function enviarCodigoRecuperacao(destinatario, nome, codigo) {
  const remetente = process.env.SMTP_FROM || `PetFind <${process.env.SMTP_USER}>`;
  await criarTransporte().sendMail({
    from: remetente,
    to: destinatario,
    subject: 'PetFind - código para redefinir sua senha',
    text: `Olá, ${nome}!\n\nSeu código de recuperação de senha é: ${codigo}\n\nEle vale por 15 minutos. Se você não pediu a redefinição, ignore este e-mail.\n\nEquipe PetFind`,
    html: `<p>Olá, ${escaparHtml(nome)}!</p><p>Seu código de recuperação de senha é:</p><p style="font-size:28px;font-weight:bold;letter-spacing:4px">${codigo}</p><p>Ele vale por 15 minutos. Se você não pediu a redefinição, ignore este e-mail.</p><p>Equipe PetFind</p>`,
  });
}

module.exports = { emailConfigurado, enviarCodigoRecuperacao };
