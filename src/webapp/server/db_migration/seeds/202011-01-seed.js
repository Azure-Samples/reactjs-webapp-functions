const Sequelize = require('sequelize');
const { models, model } = require('../../db/db');

//const item_names = ["item 1", "item 2"];

module.exports = {

    up: async () => {
/*         await item_names.forEach(element => {
            models.item.create({ name: element })
        }); */
    },

    down: async () => {
        /* await item_names.forEach(element => {
            models.item.destroy({
                where: { name: element }
            })
         }); */
    }
};