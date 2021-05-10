const Umzug = require('umzug');
const path = require('path');
const db = require('../db/db');

const umzug = new Umzug({
    storage: 'sequelize',
    storageOptions: {
        sequelize: db
    },
    logger: console,

    migrations: {
        path: path.join(__dirname, './migrations'),
        pattern: /\.js$/,
        params: [
            db.getQueryInterface()
        ]
    }
});

module.exports = {
    migrate : async function migrate() {
        console.log("Running migrations.");
        await umzug.up();
    },
    rollback : async function rollback() {
        console.log("Rollback migrations.");
        await umzug.down();
    }
}