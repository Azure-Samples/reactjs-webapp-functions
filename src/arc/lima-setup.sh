#!/bin/bash

# This script can be used to set up an AKS cluster with Azure Arc-enabled Kubernetes and App Service.
# Check this article for the latest info: https://docs.microsoft.com/azure/app-service/manage-create-arc-environment

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Checking for prefix for naming
prefix=$1
# arcLocation is used for the AKS cluster and the ARC cluster resource
arcLocation=${2:-'eastus'}
# k8se location
k8seLocation=${3:-'centraluseuap'}

if
    [[ $prefix == "" ]]
then
    printf "${RED}You need to provide a prefix and location for your resources './lima-setup.sh {prefix} ({arcLocation}) ({k8seLocation})'. The prefix is used to name resoures. All resources created by this script also have the prefix as a tag. ${NC}\n"
    exit 1
fi

# Step 0 - Pre-reqs and setup

printf "${GREEN}Deploying k8se ARC to ${arcLocation} ${NC}\n"

printf "${GREEN}Log in to Azure ${NC}\n"
az login --use-device-code -o none

## Variables
## Static IP Name for the clsuter
staticIpName="${prefix}-ip"
## The name of the resource group into which your resources will be provisioned
groupName="${prefix}-lima-rg"
## Only needed if using AKS; the name of the resource group in which the AKS cluster resides
aksClusterGroupName="${prefix}-aks-cluster-rg"
aksClusterName="${prefix}-aks-cluster"
## The subscription ID into which your resources will be provisioned
subscriptionId=$(az account show --query id -o tsv)
## The desired name of your connected cluster resource
clusterName="${prefix}-arc-cluster"
## The desired name of the extension to be installed in the connected cluster
extensionName="${prefix}-appsvc-ext"
## The desired name of your custom location
customLocationName="${prefix}-location"
## The desired name of your Kubernetes environment
kubeEnvironmentName="${prefix}-kube"
## Workspace name
workspaceName="${prefix}-workspace"

## Check installed CLI extensions
printf "${GREEN}Installing Azure-CLI Extensions ${NC}\n"
az extension add --upgrade --yes -n connectedk8s
az extension add --upgrade --yes -n customlocation
az extension add --upgrade --yes -n k8s-extension
az extension add --yes --source "https://aka.ms/appsvc/appservice_kube-latest-py2.py3-none-any.whl"

az version

## Checking that all providers are registrered
printf "${GREEN}Checking if all providers are registrered ${NC}\n"
printf "${GREEN}Regions available for Kubernetes Environments${NC}\n"
az provider show -n Microsoft.Web --query "resourceTypes[?resourceType=='kubeEnvironments'].locations"
printf "${GREEN}Regions available for Connected clusters ${NC}\n"
az provider show -n Microsoft.Kubernetes --query "[registrationState,resourceTypes[?resourceType=='connectedClusters'].locations]"
printf "${GREEN}Regions available for Cluster Extensions ${NC}\n"
az provider show -n Microsoft.KubernetesConfiguration --query "[registrationState,resourceTypes[?resourceType=='extensions'].locations]"
printf "${GREEN}Regions available for Custom Locations ${NC}\n"
az provider show -n Microsoft.ExtendedLocation --query "[registrationState,resourceTypes[?resourceType=='customLocations'].locations]"
printf "${GREEN}Regions available for Web App Kubernetes Environments ${NC}\n"
az provider show -n Microsoft.Web --query "[registrationState,resourceTypes[?resourceType=='kubeEnvironments'].locations]"

# Section 1 - Creating AKS Cluster

printf "${GREEN}Creating AKS cluster resource group: ${aksClusterGroupName} in ${arcLocation} ${NC}\n"
az group create -n $aksClusterGroupName -l $arcLocation --tags prefix=$prefix

printf "${GREEN}Checking if AKS cluster: ${aksClusterName} already exists...${NC}\n"

if
    [[ $(az aks show -g $aksClusterGroupName -n $aksClusterName | jq -r .name) == "${aksClusterName}" ]]
then
    echo "Cluster already exists"
else
    printf "${GREEN}Creating AKS cluster: ${aksClusterName} in ${arcLocation} ${NC}\n"
    az aks create -g $aksClusterGroupName -n $aksClusterName -l $arcLocation --enable-aad --generate-ssh-keys --tags prefix=$prefix
fi

printf "${GREEN}Getting credentials ${NC}\n"
az aks get-credentials -g $aksClusterGroupName -n $aksClusterName --admin
kubectl get ns

printf "${GREEN}Creating static IP for the cluster ${NC}\n"
infra_rg=$(az aks show -g $aksClusterGroupName -n $aksClusterName -o tsv --query nodeResourceGroup)

if
    [[ $(az network public-ip show -g $infra_rg -n $staticIpName | jq -r .name) == "${staticIpName}" ]]
then
    echo "Static IP already exists"
else
    az network public-ip create -g $infra_rg -n $staticIpName --sku STANDARD
fi

staticIp=$(az network public-ip show -g $infra_rg -n $staticIpName | jq -r .ipAddress)
printf "${GREEN}Ip address: ${staticIp} ${NC}\n"

# Section 2 - Creating ARC resource

## Resource Group
printf "${GREEN}Connecting cluster to ARC in RG: ${groupName} ${NC}\n"
printf "${GREEN}Creating resource group for ARC resource: ${groupName} in ${arcLocation} ${NC}\n"
az group create -n $groupName -l ${arcLocation} --tags prefix=$prefix

## Log Analytics workspace
printf "${GREEN}Creating a Log Analytics Workspace for the cluster ${NC}\n"

if
    [[ $(az monitor log-analytics workspace show -g $groupName -n $workspaceName | jq -r .name) == "${workspaceName}" ]]
then
    echo "Workspace already exists"
else
    az monitor log-analytics workspace create -g $groupName -n $workspaceName -l ${arcLocation}
fi

logAnalyticsWorkspaceId==$(az monitor log-analytics workspace show --resource-group $groupName --workspace-name $workspaceName -o tsv --query "customerId")
logAnalyticsWorkspaceIdEnc=$(printf %s $logAnalyticsWorkspaceId | base64)
logAnalyticsKey=$(az monitor log-analytics workspace get-shared-keys --resource-group $groupName --workspace-name $workspaceName -o tsv --query "secondarySharedKey")
logAnalyticsKeyEncWithSpace=$(printf %s $logAnalyticsKey | base64)
logAnalyticsKeyEnc=$(echo -n "${logAnalyticsKeyEncWithSpace//[[:space:]]/}")

## Installing ARC agent

printf "${GREEN}Installing ARC agent${NC}\n"

if
    [[ $(az connectedk8s show -g $groupName -n $clusterName | jq -r .name) == ${clusterName} ]]
then
    echo "Cluster already connected"
else

    az connectedk8s connect -g $groupName -n $clusterName --tags prefix=$prefix
    
    ### Looping until cluster is connected
    while true
    do
        printf "${GREEN}\nChecking connectivity... ${NC}\n" 
        sleep 10
        connectivityStatus=$(az connectedk8s show -n $clusterName -g $groupName | jq -r .connectivityStatus)
        printf "${GREEN}connectivityStatus: ${connectivityStatus} ${NC}\n"
        if
            [[ $connectivityStatus == "Failed" ]]
        then
            exit
        elif
            [[ $connectivityStatus == "Connected" ]]
        then
            break
        fi
    done
fi

connectedClusterId=$(az connectedk8s show -n $clusterName -g $groupName --query id -o tsv)

printf "${GREEN}Let's grab the resources in the cluster: ${NC}\n"
kubectl get pods -n azure-arc

# Step 3 - K8SE setup

## K8SE extension installation
printf "${GREEN}Installing the App Service extension on your cluster ${NC}\n"

if
    [[ $(az k8s-extension show --cluster-type connectedClusters -c $clusterName -g $groupName --name $extensionName | jq -r .installState) == "Installed" ]]
then
    echo "Extension already installed"
else
    az k8s-extension create -g $groupName --name $extensionName \
        --cluster-type connectedClusters -c $clusterName \
        --extension-type 'Microsoft.Web.Appservice' \
        --auto-upgrade-minor-version true \
        --scope cluster \
        --release-namespace 'appservice-ns' \
        --configuration-settings "Microsoft.CustomLocation.ServiceAccount=default" \
        --configuration-settings "appsNamespace=appservice-ns" \
        --configuration-settings "clusterName=${kubeEnvironmentName}" \
        --configuration-settings "loadBalancerIp=${staticIp}" \
        --configuration-settings "keda.enabled=true" \
        --configuration-settings "buildService.storageClassName=default" \
        --configuration-settings "buildService.storageAccessMode=ReadWriteOnce" \
        --configuration-settings "envoy.annotations.service.beta.kubernetes.io/azure-load-balancer-resource-group=${aksClusterGroupName}" \
        --configuration-settings "logProcessor.appLogs.destination=log-analytics" \
        --configuration-settings "customConfigMap=appservice-ns/kube-environment-config" \
        --configuration-protected-settings"logProcessor.appLogs.logAnalyticsConfig.customerId=${logAnalyticsWorkspaceIdEnc}" \
        --configuration-protected-settings "logProcessor.appLogs.logAnalyticsConfig.sharedKey=${logAnalyticsKeyEnc}"

    ### Looping until extention is installed
    while true
    do
        printf "${GREEN}\nChecking state of extension... ${NC}\n" 
        sleep 10
        installState=$(az k8s-extension show --cluster-type connectedClusters -c $clusterName -g $groupName --name $extensionName | jq -r .installState)
        printf "${GREEN}installState: ${installState} ${NC}\n"
        if
            [[ $installState == "Failed" ]]
        then
            exit
        elif
            [[ $installState == "Installed" ]]
        then
            break
        fi
    done
fi

extensionId=$(az k8s-extension show --cluster-type connectedClusters -c $clusterName -g $groupName --name $extensionName --query id -o tsv)

## Creating custom location
printf "${GREEN}Creating custom location ${NC}\n"

if
    [[ $(az customlocation show -g $groupName -n $customLocationName | jq -r .provisioningState) == "Succeeded" ]]
then
    echo "CustomeLocation already exists"
else
    az customlocation create -g $groupName -n $customLocationName \
        --host-resource-id $connectedClusterId \
        --namespace appservice-ns -c $extensionId

    ### Looping until custom location is provisioned
    while true
    do
        printf "${GREEN}\nChecking state of custom location... ${NC}\n" 
        sleep 10
        customLocationState=$(az customlocation show -g $groupName -n $customLocationName | jq -r .provisioningState)
        printf "${GREEN}customLocationState: ${customLocationState} ${NC}\n"
        if
            [[ $customLocationState == "Failed" ]]
        then
            exit
        elif
            [[ $customLocationState == "Succeeded" ]]
        then
            break
        fi
    done
fi

customLocationId=$(az customlocation show -g $groupName -n $customLocationName --query id -o tsv)

## Creating Kube-Environment
printf "${GREEN}Creating Kubernetes environment ${NC}\n"

if
    [[ $(az appservice kube show -g $groupName -n $kubeEnvironmentName | jq -r .provisioningState) == "Succeeded" ]]
then
    echo "Kube environment already exists"
else
    az appservice kube create -g $groupName -n $kubeEnvironmentName \
        --custom-location $customLocationId --static-ip "$staticIp" \
        --location $k8seLocation

    ### Looping until environment is ready
    while true
    do
        printf "${GREEN}\nChecking state of environment... ${NC}\n" 
        sleep 10
        kubeenvironmentState=$(az appservice kube show -g $groupName -n $kubeEnvironmentName | jq -r .provisioningState)
        printf "${GREEN}kubeenvironmentState: ${kubeenvironmentState} ${NC}\n"
        if
            [[ $kubeenvironmentState == "Failed" ]]
        then
            exit
        elif
            [[ $kubeenvironmentState == "Succeeded" ]]
        then
            break
        fi
    done
fi

sleep 10

printf "${GREEN}Let's check all the resources... Run 'kubectl get pods -n appservice-ns' to check again ${NC}\n"
kubectl get pods -n appservice-ns

printf "${GREEN}Whooo - congratulations! You made it all the way through - now go deploy apps!!! ${NC}\n"