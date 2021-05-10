# Lima

## Create Postgres database in Azure

Note: Could be using Postgres ARM and run on Arc (check mail)

PGHOST: mikhegn-12-postgres.postgres.database.azure.com
PGUSER: postgres
PGPASSWORD: 
PGDB: postgres

## ARM

Note: Could create App Plan as part of this, and not use an existing...
Note: Does functions need storage on Lima?
Note: Could reuse AI and Log Analytics from 1. deployment
Note: Cannot output postgres information if not creating postgres as part of the deployment (currently commented out in the bicep)

1. Build ARM template
    `az bicep build -f main.bicep`
1. Deploy ARM template
    ```bash
    az deployment group create -g mikhegn-12-rg --template-file main.json --parameters location=centraluseuap name_prefix=mikhegn-12 kubeEnvironment_id=""
    postgres_adminPassword=""
    teamsWebhookUrl=""
    ```

## Functions and WebApp deployment

make zip_it

./zip_deploy.sh "/subscriptions/c484c80e-0a6f-4470-86de-697ecee16984/resourceGroups/mikhegn-12-rg/providers/Microsoft.Web/sites/mikhegn-12-webapi-guusxusroqiqi" output/app/webapi.zip

./zip_deploy.sh "/subscriptions/c484c80e-0a6f-4470-86de-697ecee16984/resourceGroups/mikhegn-12-rg/providers/Microsoft.Web/sites/mikhegn-12-function-guusxusroqiqi" output/function/function.zip

seed the database

## In GitHub

1. Arc: bool in environment.yaml
2. Deploy workflow to know whether to pass is_kubeenvironment to arm template
3. kube_envoronment_id as GitHub secret is still a thing
