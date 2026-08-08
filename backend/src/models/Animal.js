const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const Animal = sequelize.define('Animal', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  usuarioId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  nome: {
    type: DataTypes.STRING(50),
    allowNull: false,
  },
  especie: {
    type: DataTypes.ENUM('Cachorro', 'Gato', 'Outro'),
    allowNull: false,
  },
  raca: {
    type: DataTypes.STRING(50),
    allowNull: true,
  },
  porte: {
    type: DataTypes.ENUM('Pequeno', 'Médio', 'Grande'),
    allowNull: true,
  },
  caracteristicas: {
    type: DataTypes.STRING(200),
    allowNull: false,
  },
  fotoUrl: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  dataDesaparecimento: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  ultimaLocalizacaoTexto: {
    type: DataTypes.STRING(200),
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
  status: {
    type: DataTypes.ENUM('ATIVO', 'ENCERRADO'),
    allowNull: false,
    defaultValue: 'ATIVO',
  },
  encerradoEm: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'animais',
  timestamps: true,
});

module.exports = Animal;
