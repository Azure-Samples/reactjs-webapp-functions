webapp_dir = src/webapp
function_dir = src/function
workflow_dir = src/workflow

.PHONY: init
init: 
	cp .devcontainer/content/function.local.settings.json $(function_dir)/local.settings.json
	mkdir -p .local && cp .devcontainer/content/local.env .local/.env
	make seed_db
	npm install --prefix $(function_dir)
	npm run build --prefix $(function_dir)

.PHONY: test
test : build
	npm run test --prefix $(webapp_dir)/server

.PHONY: start
start : build
	npm run start --prefix $(webapp_dir)

.PHONY: clean
clean :
	rm -r $(webapp_dir)/node_modules

.PHONY: build
build : install
	npm run build --prefix $(webapp_dir) & \
	npm run build --prefix $(webapp_dir)/server & \
	npm run build --prefix $(function_dir)

.PHONY: install
install :
	npm install --prefix $(webapp_dir) & \
	npm install --prefix $(webapp_dir)/server & \
	npm install --prefix $(function_dir) & \
	wait

.PHONY: migrate_db
migrate_db : build
	npm run migrate_db --prefix $(webapp_dir)/server

.PHONY: seed_db
seed_db : migrate_db
	npm run seed_db --prefix $(webapp_dir)/server

.PHONY: remove_db
remove_db :
	dropdb postgres && createdb postgres

.PHONY: zip_it
zip_it :
	cd $(webapp_dir)/server; zip -r ../../../webapi.zip .; cd ../../../
	cd $(function_dir); zip -r ../../function.zip .; cd ../../
	bicep build src/arm/main.bicep
	mkdir -p src/bundle/output/app && mv webapi.zip src/bundle/output/app/webapi.zip -f
	mkdir -p src/bundle/output/function && mv function.zip src/bundle/output/function/function.zip -f
	mkdir -p src/bundle/output/arm && mv src/arm/main.json src/bundle/output/arm/main.json -f