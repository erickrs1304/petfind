const express = require('express');

// Páginas públicas exigidas pela Google Play: política de privacidade e instruções de
// exclusão de conta (o conteúdo segue o Quadro 24 do relatório — dados tratados pelo PetFind).
const router = express.Router();

const CONTATO = 'erickrodriguessousa2016@gmail.com';

function pagina(titulo, corpo) {
  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${titulo} — PetFind</title>
<style>
  body { font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; margin: 0; background: #f7f3ef; color: #2b2522; line-height: 1.6; }
  main { max-width: 760px; margin: 0 auto; padding: 24px 16px 48px; }
  h1 { color: #a83d0d; font-size: 1.6rem; margin-bottom: 4px; }
  h2 { font-size: 1.15rem; margin-top: 28px; }
  .data { color: #6b625c; font-size: .9rem; margin-top: 0; }
  li { margin-bottom: 6px; }
  a { color: #a83d0d; }
</style>
</head>
<body><main>
<h1>${titulo}</h1>
${corpo}
</main></body>
</html>`;
}

const privacidade = pagina('Política de Privacidade', `
<p class="data">Última atualização: outubro de 2026</p>
<p>O PetFind é um aplicativo colaborativo para ajudar a encontrar animais perdidos, desenvolvido como Trabalho
Final de Curso. Esta política explica quais dados pessoais o aplicativo trata, para quê, onde ficam guardados e
quando são apagados, conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018).</p>

<h2>Dados que tratamos e para quê</h2>
<ul>
  <li><strong>Nome, e-mail e senha:</strong> identificar você e permitir o login. A senha é guardada apenas
    de forma criptografada (hash bcrypt).</li>
  <li><strong>Telefone e região (bairro/cidade):</strong> referência de contato e da sua região. O telefone
    não é exibido a outros usuários.</li>
  <li><strong>Localização do perfil:</strong> usada para avisar sobre animais perdidos perto de você. Só é
    guardada se você ativar os "Alertas por proximidade" (a opção vem desligada) e é apagada quando você
    os desativa.</li>
  <li><strong>Localização do aparelho na lista de casos:</strong> usada apenas para ordenar os casos por
    distância, sem ser guardada.</li>
  <li><strong>Casos de animais perdidos:</strong> nome e características do animal, foto, data e o ponto do
    desaparecimento marcado por você no mapa. Esses dados ficam visíveis para os usuários do aplicativo,
    porque servem para divulgar o desaparecimento.</li>
  <li><strong>Avistamentos:</strong> a posição do aparelho no momento do registro, data, hora, comentário e
    foto opcional. O tutor do caso vê o avistamento; se ele o confirmar, o avistamento aparece no mapa do
    caso para os demais usuários, com o seu nome.</li>
  <li><strong>Identificador do aparelho:</strong> usado para enviar notificações push. É removido quando
    você sai da conta.</li>
  <li><strong>Código de recuperação de senha:</strong> enviado ao seu e-mail, expira em 15 minutos e é
    apagado após o uso.</li>
</ul>

<h2>Com quem os dados são compartilhados</h2>
<p>Não vendemos nem compartilhamos seus dados para publicidade. Eles são processados apenas pelos serviços
que mantêm o aplicativo funcionando: Supabase (banco de dados e armazenamento das fotos), Vercel
(hospedagem do servidor), Google Firebase Cloud Messaging (notificações push) e Gmail (envio do código de
recuperação de senha). Os mapas são carregados do OpenStreetMap.</p>

<h2>Segurança</h2>
<p>Toda a comunicação entre o aplicativo e o servidor usa HTTPS, as senhas são guardadas apenas como hash e
a sessão fica no armazenamento seguro do aparelho.</p>

<h2>Por quanto tempo guardamos e como excluir</h2>
<p>Os dados ficam guardados enquanto a sua conta existir. Você pode excluir um caso a qualquer momento, e
excluir a conta pelo próprio aplicativo: isso apaga na hora o cadastro, os seus casos (com avistamentos e
fotos), os avistamentos que você registrou, as notificações e os aparelhos cadastrados. Veja os passos em
<a href="/excluir-conta">Exclusão de conta</a>.</p>

<h2>Seus direitos</h2>
<p>Você pode consultar e corrigir seus dados na tela de perfil, desativar o uso da localização a qualquer
momento e pedir a eliminação dos seus dados (art. 18 da LGPD), pelo aplicativo ou pelo e-mail abaixo.</p>

<h2>Público</h2>
<p>O PetFind é destinado a maiores de 18 anos.</p>

<h2>Contato</h2>
<p>Dúvidas ou pedidos sobre seus dados: <a href="mailto:${CONTATO}">${CONTATO}</a>.</p>
`);

const exclusao = pagina('Exclusão de conta', `
<p class="data">PetFind — como excluir sua conta e seus dados</p>

<h2>Pelo aplicativo</h2>
<ol>
  <li>Abra o PetFind e entre na sua conta.</li>
  <li>Toque em <strong>Perfil</strong>, na barra inferior.</li>
  <li>Toque em <strong>Excluir conta</strong>.</li>
  <li>Digite sua senha e confirme em <strong>Excluir conta</strong>.</li>
</ol>

<h2>Sem acesso ao aplicativo</h2>
<p>Envie um e-mail para <a href="mailto:${CONTATO}">${CONTATO}</a>, a partir do e-mail cadastrado, com o
assunto "Excluir conta PetFind". A exclusão é feita em até 15 dias e você recebe a confirmação por e-mail.</p>

<h2>O que é apagado</h2>
<ul>
  <li>Seu cadastro: nome, e-mail, telefone, região, senha e localização.</li>
  <li>Os casos que você cadastrou, com os avistamentos e as fotos de cada caso.</li>
  <li>Os avistamentos que você registrou em casos de outras pessoas.</li>
  <li>Suas notificações e os aparelhos cadastrados para notificações push.</li>
</ul>
<p>A exclusão é definitiva e imediata; nenhum dado da conta é mantido depois dela.</p>
`);

router.get('/privacidade', (req, res) => res.type('html').send(privacidade));
router.get('/excluir-conta', (req, res) => res.type('html').send(exclusao));

module.exports = router;
