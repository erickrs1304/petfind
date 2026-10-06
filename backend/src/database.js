const { Sequelize } = require('sequelize');

// Em teste automatizado (NODE_ENV=test), usa SQLite em memória: cada rodada de
// teste parte de um banco limpo e isolado, sem depender de um servidor externo.
// Fora de teste, usa PostgreSQL — o SGBD especificado no DERS (Seção 2.3.1).
// DATABASE_URL aponta para um banco na nuvem (ex.: Supabase), que exige SSL;
// DB_HOST/DB_PORT/... continuam servindo para um Postgres local sem SSL.
const isTest = process.env.NODE_ENV === 'test';

const sequelize = isTest
  ? new Sequelize({ dialect: 'sqlite', storage: ':memory:', logging: false })
  : process.env.DATABASE_URL
    ? new Sequelize(process.env.DATABASE_URL, {
      logging: false,
      dialectOptions: { ssl: { require: true, rejectUnauthorized: false } },
      // Serverless (Vercel): cada instância abre o próprio pool, então 1 conexão
      // por instância evita estourar o limite de conexões do banco.
      pool: { max: process.env.VERCEL ? 1 : 5 },
    })
    : new Sequelize({
      dialect: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'petfind',
      username: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || '',
      logging: false,
    });

module.exports = sequelize;
