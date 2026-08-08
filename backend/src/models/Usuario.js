const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const Usuario = sequelize.define('Usuario', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  nome: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  email: {
    type: DataTypes.STRING(150),
    allowNull: false,
    unique: true,
    validate: { isEmail: true },
  },
  telefone: {
    type: DataTypes.STRING(20),
    allowNull: false,
  },
  senhaHash: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  regiao: {
    type: DataTypes.STRING(150),
    allowNull: false,
  },
  lat: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  lng: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  raioNotificacaoKm: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 5,
  },
  notificacoesAtivas: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  loginTentativasFalhas: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  loginBloqueadoAte: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  resetCode: {
    type: DataTypes.STRING(6),
    allowNull: true,
  },
  resetCodeExpiraEm: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'usuarios',
  timestamps: true,
});

module.exports = Usuario;
