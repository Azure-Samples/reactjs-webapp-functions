const { Sequelize } = require('sequelize');

var sslOption = true;

if (process.env.NODE_ENV === 'development') {
 sslOption = false;
}

const db = new Sequelize(process.env.PGDB,
process.env.PGUSER,
process.env.PGPASSWORD,
{
  dialect: 'postgres',
  host: process.env.PGHOST,
  dialectOptions: {
    ssl: sslOption
  }
});

const modelDefiners = [
  require('../models/item')
];

for (const modelDefiner of modelDefiners) {
  modelDefiner(db);
}

module.exports = db;