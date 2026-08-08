const path = require('path');
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const animalRoutes = require('./routes/animals');
const sightingRoutes = require('./routes/sightings');
const notificationRoutes = require('./routes/notifications');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/auth', authRoutes);
app.use('/animals', animalRoutes);
app.use('/sightings', sightingRoutes);
app.use('/notifications', notificationRoutes);

app.use((err, req, res, next) => {
  console.error(err);
  if (err.message && err.message.includes('imagem')) {
    return res.status(400).json({ error: err.message });
  }
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ error: 'A imagem deve ter no máximo 5MB.' });
  }
  return res.status(500).json({ error: 'Erro interno do servidor.' });
});

module.exports = app;
