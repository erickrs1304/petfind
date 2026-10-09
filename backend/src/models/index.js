const sequelize = require('../database');
const Usuario = require('./Usuario');
const Animal = require('./Animal');
const Avistamento = require('./Avistamento');
const Notificacao = require('./Notificacao');
const Dispositivo = require('./Dispositivo');

Usuario.hasMany(Animal, { foreignKey: 'usuarioId', as: 'animais' });
Animal.belongsTo(Usuario, { foreignKey: 'usuarioId', as: 'tutor' });

Usuario.hasMany(Avistamento, { foreignKey: 'usuarioId', as: 'avistamentos' });
Avistamento.belongsTo(Usuario, { foreignKey: 'usuarioId', as: 'colaborador' });

Animal.hasMany(Avistamento, { foreignKey: 'animalId', as: 'avistamentos' });
Avistamento.belongsTo(Animal, { foreignKey: 'animalId', as: 'animal' });

Usuario.hasMany(Notificacao, { foreignKey: 'usuarioId', as: 'notificacoes' });
Notificacao.belongsTo(Usuario, { foreignKey: 'usuarioId', as: 'destinatario' });

Usuario.hasMany(Dispositivo, { foreignKey: 'usuarioId', as: 'dispositivos' });
Dispositivo.belongsTo(Usuario, { foreignKey: 'usuarioId', as: 'usuario' });

module.exports = {
  sequelize,
  Usuario,
  Animal,
  Avistamento,
  Notificacao,
  Dispositivo,
};
