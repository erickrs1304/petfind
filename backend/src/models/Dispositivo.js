const { DataTypes } = require('sequelize');
const sequelize = require('../database');

// Token FCM de um celular onde o usuário está logado (RF-008, notificação push).
const Dispositivo = sequelize.define('Dispositivo', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  usuarioId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  token: {
    type: DataTypes.STRING(512),
    allowNull: false,
    unique: true,
  },
}, {
  tableName: 'dispositivos',
  timestamps: true,
});

module.exports = Dispositivo;
