const appInsights = require('applicationinsights');

if (!process.env.APPINSIGHTS_INSTRUMENTATIONKEY) {
    console.log(`Found no AI key. AI will not emit data.`);
}
else {
    appInsights.setup()
        .setSendLiveMetrics(true)
        .start();
}

const go = async () => {

    const App = require("./app");
    const app = new App();

    app.start();
};

go();