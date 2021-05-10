#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Checking for prefix for naming
prefix=$1
if
    [[ $prefix == "" ]]
then
    printf "${RED}You need to provide a prefix for your resources './lima-setup.sh {prefix}'. The prefix is used to name resoures. All resources created by this script also have the prefix as a tag. ${NC}\n"
    exit 1
fi
printf "${GREEN}Log in to Azure ${NC}\n"
az login -o none

printf "${GREEN}Installing Azure-CLI Extensions ${NC}\n"
az extension add --yes --source ../../.devcontainer/content/appservice_kube-0.1.9-py2.py3-none-any.whl
az extension add --yes --source ../../.devcontainer/content/connectedk8s-0.3.5-py2.py3-none-any.whl
az extension add --yes --source ../../.devcontainer/content/customlocation-0.1.0-py2.py3-none-any.whl
az extension add --yes --source ../../.devcontainer/content/k8s_extension-0.1.0-py2.py3-none-any.whl

az version
read -n1 -s -r -p $'Verify that you have four extensions isntalled, if not, check here: https://github.com/microsoft/Azure-App-Service-on-Azure-Arc/blob/main/docs/getting-started/setup.md press space to continue...\n' key

# Checking that all providers are registrered
printf "${GREEN}Checking if all providers are registrered ${NC}\n"

printf "${GREEN}Regions available for Kubernetes Environments - has to include 'Central US EUAP'${NC}\n"
az provider show -n Microsoft.Web --query "resourceTypes[?resourceType=='kubeEnvironments'].locations"
printf "${GREEN}Regions available for Connected clusters ${NC}\n"
az provider show -n Microsoft.Kubernetes --query "[registrationState,resourceTypes[?resourceType=='connectedClusters'].locations]"
printf "${GREEN}Regions available for Cluster Extensions ${NC}\n"
az provider show -n Microsoft.KubernetesConfiguration --query "[registrationState,resourceTypes[?resourceType=='extensions'].locations]"
printf "${GREEN}Regions available for Custom Locations ${NC}\n"
az provider show -n Microsoft.ExtendedLocation --query "[registrationState,resourceTypes[?resourceType=='customLocations'].locations]"
printf "${GREEN}Regions available for Web App Kubernetes Environments ${NC}\n"
az provider show -n Microsoft.Web --query "[registrationState,resourceTypes[?resourceType=='kubeEnvironments'].locations]"

read -n1 -s -r -p $'Verify that you have regions for all of the above, if not, check here: https://github.com/microsoft/Azure-App-Service-on-Azure-Arc/blob/main/docs/getting-started/setup.md press space to continue...\n' key

# Static IP Name for the clsuter
staticIpName="${prefix}-ip"

# The name of the resource group into which your resources will be provisioned
groupName="${prefix}-lima-rg"

# Only needed if using AKS; the name of the resource group in which the AKS cluster resides
aksClusterGroupName="${prefix}-aks-cluster-rg"
aksClusterName="${prefix}-aks-cluster"

# The client app ID for your AAD-enabled cluster. If using the AKS-enabled AAD, the value is "80faf920-1908-4b52-b5ef-a8e7bedfc67a"
clientAppId="80faf920-1908-4b52-b5ef-a8e7bedfc67a"
# The server app ID for your AAD-enabled cluster. If using the AKS-enabled AAD, the value is "6dae42f8-4368-4678-94ff-3960e28e3630"
serverAppId="6dae42f8-4368-4678-94ff-3960e28e3630"
# The subscription ID into which your resources will be provisioned
subscriptionId=$(az account show --query id -o tsv)

# The desired name of your connected cluster resource
clusterName="${prefix}-arc-cluster"
# The desired name of the extension to be installed in the connected cluster
extensionName="${prefix}-kube"
# The desired name of your custom location
customLocationName="${prefix}-location"
# The desired name of your Kubernetes environment
kubeEnvironmentName=$extensionName
# Workspace name
workspaceName="${prefix}-workspace"

printf "${GREEN}Creating AKS cluster resource group: ${aksClusterGroupName} ${NC}\n"
az group create -n $aksClusterGroupName -l "Central US EUAP" --tags prefix=$prefix
read -n1 -s -r -p $'Press space to continue...\n' key

printf "${GREEN}Checking if AKS cluster: ${aksClusterName} already exists...${NC}\n"

if
    [[ $(az aks show -g $aksClusterGroupName -n $aksClusterName | jq -r .name) == "${aksClusterName}" ]]
then
    echo "Cluster already exists"
else
    printf "${GREEN}Creating AKS cluster: ${aksClusterName} ${NC}\n"
    az aks create -g $aksClusterGroupName -n $aksClusterName --enable-aad --generate-ssh-keys --tags prefix=$prefix
fi

printf "${GREEN}Getting credentials ${NC}\n"
az aks get-credentials -g $aksClusterGroupName -n $aksClusterName --admin
kubectl get ns
read -n1 -s -r -p $'If you see a list of namespaces above, you are good to continue. Press space to continue...\n' key

printf "${GREEN}Creating static IP for the cluster ${NC}\n"
infra_rg=$(az aks show -g $aksClusterGroupName -n $aksClusterName -o tsv --query nodeResourceGroup)
az network public-ip create -g $infra_rg -n $staticIpName --sku STANDARD
staticIp=$(az network public-ip show -g $infra_rg -n $staticIpName | jq -r .ipAddress)
printf "${GREEN}Ip address: ${staticIp} ${NC}\n"

printf "${GREEN}Connecting cluster to ARC in RG: ${groupName} ${NC}\n"
printf "${GREEN}Creating resource group for ARC resource: ${groupName} ${NC}\n"
az group create -n $groupName -l "West Europe" --tags prefix=$prefix

printf "${GREEN}Creating a Log Analytics Workspace for the cluster ${NC}\n"
printf "${GREEN}If this command never returns, cancel it (ctrl+c), comment out the line below and, rerun the script...${NC}\n"
az monitor log-analytics workspace create -g $groupName -n $workspaceName
logAnalyticsWorkspaceId==$(az monitor log-analytics workspace show --resource-group $groupName --workspace-name $workspaceName -o tsv --query "customerId")
logAnalyticsWorkspaceIdEnc=$(printf %s $logAnalyticsWorkspaceId | base64)
logAnalyticsKey=$(az monitor log-analytics workspace get-shared-keys --resource-group $groupName --workspace-name $workspaceName -o tsv --query "secondarySharedKey")
logAnalyticsKeyEncWithSpace=$(printf %s $logAnalyticsKey | base64)
logAnalyticsKeyEnc=$(echo -n "${logAnalyticsKeyEncWithSpace//[[:space:]]/}")

printf "${GREEN}Creating a role assignment to allow Custom Locations and App Service Resource Providers to work against your cluster ${NC}\n"
MicrosoftAzureWebsitesOid=$(az ad sp show --id 'abfa0a7c-a6b6-4736-8310-5855508787cd' --query objectId -o tsv)
CustomLocationsRpOid=$(az ad sp show --id 'bc313c14-388c-4e7d-a58e-70017303ee3b' --query objectId -o tsv)
az role assignment create --assignee-object-id $MicrosoftAzureWebsitesOid --role Owner --scope "/subscriptions/${subscriptionId}/resourceGroups/${groupName}" --output none

printf "${GREEN}Creating clusterrolebinding.yaml file and applying to your AKS cluster${NC}\n"
echo "
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
    name: cluster-admin-firstparty-app
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
subjects:
    - kind: User
      name: $MicrosoftAzureWebsitesOid
    - kind: User
      name: $CustomLocationsRpOid
" > "./clusterrolebinding.yaml"
kubectl apply -f "./clusterrolebinding.yaml"

echo "
systemDefaultValues:
  azureArcAgents:
    autoUpdate: false
" > ./onboarding.yaml
export HELMVALUESPATH=onboarding.yaml
export HELMREGISTRY="mcr.microsoft.com/azurearck8s/batch1/stable/azure-arc-k8sagents:0.2.62"

az connectedk8s connect -g $groupName -n $clusterName --aad-client-app-id $clientAppId --aad-server-app-id $serverAppId --tags prefix=$prefix

# Looping until cluster is connected
while true
do
    printf "${GREEN}\nChecking connectivity... ${NC}\n" 
    sleep 10
    connectivityStatus=$(az connectedk8s show -n $clusterName -g $groupName | jq -r .connectivityStatus)
    printf "${GREEN}connectivityStatus: ${connectivityStatus} ${NC}\n"
    if
        [[ $connectivityStatus == "Connected" ]]
    then
        break
    fi
done

connectedClusterId=$(az connectedk8s show -n $clusterName -g $groupName --query id -o tsv)
rm ./clusterrolebinding.yaml

printf "${GREEN}Let's grab the resources in the cluster: ${NC}\n"
kubectl get pods -n azure-arc
read -n1 -s -r -p $'If you see a list of pods in a good state, press space to continue...\n' key

printf "${GREEN}Installing the App Service extension on your cluster ${NC}\n"
az k8s-extension create -g $groupName --name $extensionName --cluster-type connectedClusters -c $clusterName --extension-type 'Microsoft.Web.Appservice' --version "0.4.0" --auto-upgrade-minor-version false --scope cluster --release-namespace 'appservice-ns' --configuration-settings "Microsoft.CustomLocation.ServiceAccount=default" --configuration-settings "appsNamespace=appservice-ns" --configuration-settings "clusterName=${kubeEnvironmentName}" --configuration-settings "loadBalancerIp=${staticIp}" --configuration-settings "buildService.storageClassName=default" --configuration-settings "buildService.storageAccessMode=ReadWriteOnce" --configuration-settings "envoy.annotations.service.beta.kubernetes.io/azure-load-balancer-resource-group=${aksClusterGroupName}" --configuration-settings "logProcessor.appLogs.destination=log-analytics" --configuration-settings "logProcessor.appLogs.logAnalyticsConfig.customerId=${logAnalyticsWorkspaceIdEnc}" --configuration-settings "logProcessor.appLogs.logAnalyticsConfig.sharedKey=${logAnalyticsKeyEnc}"

# Looping until extention is installed
while true
do
    printf "${GREEN}\nChecking state of extension... ${NC}\n" 
    sleep 10
    installState=$(az k8s-extension show --cluster-type connectedClusters -c $clusterName -g $groupName --name $extensionName | jq -r .installState)
    printf "${GREEN}installState: ${installState} ${NC}\n"
    if
        [[ $installState == "Installed" ]]
    then
        break
    fi
done

extensionId=$(az k8s-extension show --cluster-type connectedClusters -c $clusterName -g $groupName --name $extensionName --query id -o tsv)

printf "${GREEN}Creating custom location ${NC}\n"
az customlocation create -g $groupName -n $customLocationName -hr $connectedClusterId -ns appservice-ns -c $extensionId

# Looping until custom location is provisioned
while true
do
    printf "${GREEN}\nChecking state of custom location... ${NC}\n" 
    sleep 10
    customLocationState=$(az customlocation show -g $groupName -n $customLocationName | jq -r .provisioningState)
    printf "${GREEN}customLocationState: ${customLocationState} ${NC}\n"
    if
        [[ $customLocationState == "Succeeded" ]]
    then
        break
    fi
done

customLocationId=$(az customlocation show -g $groupName -n $customLocationName --query id -o tsv)

printf "${GREEN}Creating a Web App Kubernetes environment ${NC}\n"
echo "{
    \"Location\": \"Central US EUAP\",
    \"Kind\": \"null\",
    \"Tags\": {},
    \"Plan\": null,
    \"Properties\": {
        \"ExtendedLocation\":{
            \"CustomLocation\": \"${customLocationId}\"
        },
        \"StaticIp\": \"${staticIp}\",
        \"AksClusterResourceGroup\":\"${aksClusterGroupName}\",
        \"ArcConfiguration\":{
            \"ArtifactsStorageType\" : \"NetworkFileSystem\",
            \"ArtifactStorageClassName\": \"default\",
            \"FrontEndServiceConfiguration\": {
                \"Kind\": \"LoadBalancer\"
            }
        }
    }
}" > "./${prefix}kubeenvironment.json"

az rest --m "PUT" --headers "Content-Type=application/json" -b "@./${prefix}kubeenvironment.json" --uri "/subscriptions/${subscriptionId}/resourceGroups/${groupName}/providers/Microsoft.Web/kubeEnvironments/${kubeEnvironmentName}?api-version=2019-08-01"

read -n1 -s -r -p $'Validate the response from the rest call, press space to continue...\n' key

# Looping until environment is ready
while true
do
    printf "${GREEN}\nChecking state of environment... ${NC}\n" 
    sleep 10
    kubeenvironmentState=$(az appservice kube show -g $groupName -n $kubeEnvironmentName | jq -r .provisioningState)
    printf "${GREEN}kubeenvironmentState: ${kubeenvironmentState} ${NC}\n"
    if
        [[ $kubeenvironmentState == "Succeeded" ]]
    then
        break
    fi
done

read -n1 -s -r -p $'Validate the status of the Kubernetes environment, press space to continue...\n' key

printf "${GREEN}Let's check all the resources... ${NC}\n"
kubectl get pods -n appservice-ns

read -n1 -s -r -p $'Looking good??? Press space to continue...\n' key
printf "${GREEN}Whooo - congratulations! You made it all the way through - now go deploy apps!!!\n
    KNOWN ISSUE In order to enable HTTPS endpoints for apps and SCM after deployment the app controller pod needs to be deleted and restarted to achieve this execute:
    `kubectl delete pods -n appservice-ns -l control-plane=app-controller`
    - https://github.com/microsoft/Azure-App-Service-on-Azure-Arc/blob/main/docs/getting-started/create-first-web-app.md \n
    - https://github.com/microsoft/Azure-App-Service-on-Azure-Arc/blob/main/docs/getting-started/create-first-function-app.md \n
    - https://github.com/microsoft/Azure-App-Service-on-Azure-Arc/blob/main/docs/getting-started/Logic-App-on-Azure-Arc/create-first-logic-app.md \n${NC}"

read -n1 -s -r -p $'Press space to install an nginx app... (ctrl+c to quit)\n' key
az appservice plan create -g $groupName -n "${prefix}-app-plan" --kube-environment "${kubeEnvironmentName}" --kube-sku ANY
az webapp create -g $groupName -p "${prefix}-app-plan" -n "${prefix}-nginx" --deployment-container-image-name docker.io/nginx:latest
nginxhostname=$(az webapp show -g $groupName -n "${prefix}-nginx" | jq -r .defaultHostName)
printf "${GREEN}Nginx up and running here http://${nginxhostname}... ${NC}\n"