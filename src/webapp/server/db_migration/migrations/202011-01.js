const Sequelize = require('sequelize')

module.exports = {
    up: async (query) => {
        await query.createTable('items', {
                id: {
                    type: Sequelize.INTEGER,
                    primaryKey: true,
                    autoIncrement: true,
                    allowNull: false
                },
                orderId: Sequelize.UUID,
                status: Sequelize.STRING,
                createdAt: Sequelize.DATE,
                updatedAt: Sequelize.DATE,
                workflowStatus: Sequelize.STRING
            }
        )
    },
    down: async (query) => {
        await query.dropTable('items');
    }
}