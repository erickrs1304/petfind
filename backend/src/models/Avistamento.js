const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const Avistamento = sequelize.define('Avistamento', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  animalId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  usuarioId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  lat: {
    type: DataTypes.FLOAT,
    allowNull: false,
  },
  lng: {
    type: DataTypes.FLOAT,
    allowNull: false,
  },
  dataHora: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  comentario: {
    type: DataTypes.STRING(300),
    allowNull: true,
  },
  // RF-010: comentário opcional do tutor ao confirmar; fica separado do de quem registrou.
  comentarioTutor: {
    type: DataTypes.STRING(300),
    allowNull: true,
  },
  fotoUrl: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('PENDENTE', 'CONFIRMADO', 'REJEITADO'),
    allowNull: false,
    defaultValue: 'PENDENTE',
  },
}, {
  tableName: 'avistamentos',
  timestamps: true,
});

module.exports = Avistamento;
