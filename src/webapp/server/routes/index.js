const items = require('./item');
//const order = require('./order');

const { response } = require('express');

const Router = require('express-promise-router');
const { models } = require('../db/db');

const router = new Router();

router.get('/message', function(req, res, next) {
  res.json('Welcome To Azure App Plat ordering system');
});

module.exports = app => {
  app.use('/api/items', items);
  app.use('/api', router);
}

