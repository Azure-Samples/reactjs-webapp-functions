const { response } = require('express');
const axios = require('axios').default;
const Router = require('express-promise-router');
const { models, Sequelize } = require('../db/db');
const router = new Router();

const eventGridUrl = process.env.eventGridUrl;

module.exports = router;

router.get('/', async (req, res) => {
  console.log('Returning all orders');
  
  const rows = await models.item.findAll({
    order: [
    ['createdAt', 'DESC']
    ]
  });
  
  res.json(rows);
});

router.get('/:uuid', async (req, res) => {
  console.log('Returning specific order');
  
  const item = await models.item.findOne({ where: { orderId: req.params.uuid }});
  
  res.json(item);
});

router.post('/', async (req, res) => {
  console.log('Creating order');
  const item = await models.item.create();

  console.log(`Triggering Function at ${eventGridUrl}`);
  const fnreply = await axios.post(eventGridUrl, item);
  
  item.workflowStatus = fnreply.data.newWorkflowStatus;
  item.status = fnreply.data.newStatus;
  console.log(`Workflow status: ${item.workflowStatus} and status: ${item.status}`);
  
  console.log(`Saving item: ${item.uuid}`);
  await item.save();
  
  console.log(`Saved`);
  res.json(item);
});

router.post('/:uuid', async (req, res) => {
  console.log('Updating order');
  const item = await models.item.findOne({ where: { orderId: req.params.uuid }});
  
  item.workflowStatus = 'completed';
  item.status = 'received user input';
  console.log(`Workflow status: ${item.workflowStatus} and status: ${item.status}`);
  
  console.log(`Saving item: ${item.uuid}`);
  await item.save();
  
  console.log(`Saved`);
  res.json(item);
})