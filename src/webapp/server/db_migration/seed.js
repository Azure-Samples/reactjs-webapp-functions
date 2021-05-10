const Umzug = require('umzug');
const path = require('path');
const db = require('../db/db');

const umzug = new Umzug({
    storage: 'sequelize',
    storageOptions: {
        sequelize: db,
        tableName: 'SequelizeMetaSeed'
    },
    logger: console,

    migrations: {
        path: path.join(__dirname, './seeds'),
        pattern: /\.js$/,
        params: [
            db.getQueryInterface()
        ]
    }
});

module.exports = {
    seed: async function seed() {
        console.log("Seeding the database.");
        await umzug.up();
    },
    rollback: async function rollback() {
        console.log("Rollback seeds.");
        await umzug.down();
    }
};