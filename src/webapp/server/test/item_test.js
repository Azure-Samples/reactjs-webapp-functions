const chai = require('chai');
const should = require('chai').should();

// Seed data to the database
const migrator = require('../db_migration/migrator');
const db = require('../db/db');
const { model, models } = require('../db/db');

before(async () => {
  await migrator.migrate();

  const item_names = ["test1", "test2"];
  await item_names.forEach(element => {
    models.item.create({ name: element })
  });
});

// Test that there's data in the database
describe('Get data from database using db.query', () => {
  it('it should return two rows', async () => {
    var rows = await db.query('SELECT * FROM Items');
    rows.length.should.be.above(1);
  });
});

// Test that we get two items back from the webapi
const chaiHttp = require('chai-http');
const http = require('http');
chai.use(chaiHttp);

const App = require('../app');
const app = new App();
app.start();

const API = 'http://localhost:3001'

describe('HTTP call to /GET items', () => {
  it('it should GET all two items', (done) => {
    chai.request(API)
      .get('/api/items')
      .end((err, res) => {
        res.should.have.status(200);
        res.body.should.be.a('array');
        res.body.length.should.be.above(1);
        done();
      });
  });
});