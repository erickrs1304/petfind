const path = require('path');
// Faz o Express 4 encaminhar rejeições de handlers `async` para o middleware de
// erro. Sem isso, qualquer falha de banco dentro de uma rota async vira uma
// unhandled rejection e derruba o processo inteiro. Precisa vir antes do express.
require('express-async-errors');
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const animalRoutes = require('./routes/animals');
const sightingRoutes = require('./routes/sightings');
const notificationRoutes = require('./routes/notifications');
const deviceRoutes = require('./routes/devices');
const paginasRoutes = require('./routes/paginas');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.use('/', paginasRoutes);

app.use('/auth', authRoutes);
app.use('/animals', animalRoutes);
app.use('/sightings', sightingRoutes);
app.use('/notifications', notificationRoutes);
app.use('/devices', deviceRoutes);

app.use((err, req, res, next) => {
  // Em teste, vários casos disparam este handler de propósito (arquivo inválido,
  // tamanho excedido, JSON malformado) — logar o erro ali só faz ruído na saída
  // do Jest sem ajudar em nada. Em dev/produção o log continua normal.
  if (process.env.NODE_ENV !== 'test') console.error(err);
  if (err.message && err.message.includes('imagem')) {
    return res.status(400).json({ error: err.message });
  }
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ error: 'A imagem deve ter no máximo 5MB.' });
  }
  return res.status(500).json({ error: 'Erro interno do servidor.' });
});

module.exports = app;
