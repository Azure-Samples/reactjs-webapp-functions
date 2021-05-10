# Tasks, launch and make configuration

This document described the tasks, launch configuration and make tagerts being used in this accelerator.

| Type | Definition | Implementation |
| --- | --- | --- |
| Launch configurations | VS Code launch configurations | .vscode/launch.json |
| Make targets | Targets deinfed in the makefile | /src/makefile |
| Tasks | VS Code tasks | .vscode/tasks.json | 

## Implementations

| Type | Name | Implementation |
| --- | --- | --- |
| Launch configuration | Launch WebAPI | Executes task `debug: make build and create db`, then starts '/src/webapi/app.js' with the VSCode 'node' debugger attached. |
| Make target | test | `npm test` --> `src/webapi/package.json` --> `mocha` |
| Make target | start | `npm start` --> `src/webapi/package.json` --> `node app.js` |
| Make target | build | `npm install` |
| Make target | clean | removes `src/webapi/node_modules` |
| Task | debug: make build and create db | Runs the two tasks: `make: build` and `tool: create_db` in parallel to make the environment ready for debugging. |
| Task | tool: create_db | Seeds the postgress database with data for debugging, by executing the `src/tools/create_dev_data.sql` script. |
| Task | test | `make test` |
| Task | start | `make start` |
| Task | build | `make build` |
| Task | clean | `make clean` |
