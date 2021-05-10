const express = require('express');
const http = require('http');
const path = require('path');
const bodyParser = require('body-parser');
const mountRoutes = require('./routes');
const db = require('./db/db');
const expressOasGenerator = require('express-oas-generator');

class App {
	app = express();

	constructor() {
		expressOasGenerator.handleResponses(this.app, {});
		this.app.use(bodyParser.json());
		this.app.use(express.static(path.join(__dirname, 'build')));
		this.app.set('views', path.join(__dirname, 'views'));
		this.app.set('view engine', 'jade');
		mountRoutes(this.app);
		expressOasGenerator.handleRequests(this.app, {});
	};

	start = async () => {
		await this.checkDBConnection();

		var port = (process.env.PORT || '3001');
		var server = http.createServer(this.app);
		server.listen(port, () => console.log(`Server now listening on ${port}`));
	};

	checkDBConnection = async () => {
		try {
			console.log(`Trying to connect to: ${process.env.PGHOST}`);
			await db.authenticate();
			console.log(`Database connection OK!`);

		} catch (error) {
			console.log(`Unable to connect to the database:`);
			console.log(error.message);
			process.exit(1);
		}
	};
};

module.exports = App;