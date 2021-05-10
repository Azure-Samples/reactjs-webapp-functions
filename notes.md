# Lima

## Create Postgres database in Azure

PGHOST: {hostname}.postgres.database.azure.com
PGUSER: postgres
PGPASSWORD: 
PGDB: postgres

## ARM

1. Build ARM template
    `az bicep build -f main.bicep`
1. Deploy ARM template
    ```bash
    az deployment group create -g {rgName} --template-file main.json --parameters location=westeurope name_prefix={prefix} kubeEnvironment_id=""
    postgres_adminPassword=""
    teamsWebhookUrl=""
    ```

## Functions and WebApp deployment

make zip_it

./zip_deploy.sh "/subscriptions/{subscriptionId}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{site}" output/app/webapi.zip

./zip_deploy.sh "/subscriptions/{subscriptionId}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{site}" output/function/function.zip

seed the database

## In GitHub

1. Arc: bool in environment.yaml
2. Deploy workflow to know whether to pass is_kubeenvironment to arm template
3. kube_envoronment_id as GitHub secret is still a thing
