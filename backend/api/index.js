// Ponto de entrada serverless do Vercel: reaproveita o app Express sem chamar
// listen() nem sequelize.sync() (as tabelas já existem no banco na nuvem).
module.exports = require('../src/app');
