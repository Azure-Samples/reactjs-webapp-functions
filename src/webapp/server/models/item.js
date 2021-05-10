const { DataTypes, Sequelize } = require('sequelize');

module.exports = (sequelize) => {
    sequelize.define('item', {
        id: {
            allowNull: false,
            autoIncrement: true,
            primaryKey: true,
            type: DataTypes.INTEGER
        },
        orderId: {
            type:DataTypes.UUID,
            defaultValue: Sequelize.UUIDV4
        },
        status: {
            type: DataTypes.STRING,
            defaultValue: 'new'
        },
        createdAt: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        },
        updatedAt: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        },
        workflowStatus: {
            type: DataTypes.STRING,
            defaultValue: 'not started'
        }
    });

    return 'item';
};