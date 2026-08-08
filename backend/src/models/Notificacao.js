const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const Notificacao = sequelize.define('Notificacao', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  usuarioId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  tipo: {
    type: DataTypes.ENUM('NOVO_CASO', 'NOVO_AVISTAMENTO', 'AVISTAMENTO_CONFIRMADO', 'CASO_ENCERRADO'),
    allowNull: false,
  },
  titulo: {
    type: DataTypes.STRING(150),
    allowNull: false,
  },
  mensagem: {
    type: DataTypes.STRING(300),
    allowNull: false,
  },
  referenciaAnimalId: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  lida: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
}, {
  tableName: 'notificacoes',
  timestamps: true,
});

module.exports = Notificacao;
