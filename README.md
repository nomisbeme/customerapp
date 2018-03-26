# Summary

A simple customer database for a fictitious company. Kubernetes + Java backed by MongoDB. 
Makes heavy use of Microsoft managed services to keep things easy.
Traffic to/from the application is secured using TLS.

> This is a demonstration application that optimizes for simplicity and learning. Not intended for production use.

# Prerequisites

  * A [Microsoft Azure account](https://azure.microsoft.com/en-us/free/?WT.mc_id=AEF469A45), for running Kubernetes (AKS) and MongoDB (CosmosDB) 
  * A [Docker Hub account](https://hub.docker.com), for storing our application image.
  * A [Lets Encrypt account](https://letsencrypt.org)
  * A domain name you control, for making the application available to the world

# Setup

Provisioning the initial resources can take a little time so I did these steps upfront.

1. Download and setup the command-line tools you'll need on your computer. The examples below assume Mac but should work on other platforms.
  * [Docker for Mac](https://docs.docker.com/docker-for-mac/install/). Choose the Edge version if you want experimental Kubernetes support (not required)
  * [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
  * [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
  * [Helm](https://docs.helm.sh/using_helm/#installing-helm)
  
2. Create an Azure group and an empty Kubernetes cluster in that group
```
az group create --name bayazure --location eastus
az aks create --name k8s --resource-group bayazure
az aks get-credentials --name k8s --resource-group bayazure
```

3. Add some needed components to Kubernetes

```
$ helm init
$ helm install stable/nginx-ingress
$ helm install --name kube-lego stable/kube-lego --set config.LEGO_EMAIL=simon@baleenlabs.com --set config.LEGO_URL=https://acme-v01.api.letsencrypt.org/directory
```
> We use nginx-ingress to route external traffic within our cluster. kube-lego is used to automatically obtain a TLS certificate from Let's Encrypt.
Adjust the example values above for your environment and domain.

4. Next we'll create a CosmosDB MongoDB database to store our application data in.
```
$ az cosmosdb create --kind MongoDB --name customerdatabase --resource-group bayazure
```
# Building and deploying the application

5. First create a Kubernetes secret so that the application can connect to MongoDB:
```
kubectl create secret generic customerdatabasesecret \
    --from-literal="MONGODB_URI=$(\
    az cosmosdb list-connection-strings -n customerdatabase -g bayazure --query "connectionStrings[0].connectionString" \
      --out tsv | tr -d '\n')"
```
6. Next we'll build our Spring Boot application code:
```
mvn clean package
```
This creates an file `target/customerapp-0.1.2.war` that contains our application.

7. Then package the application in a Container image and push it to the Docker Hub:

```
docker build -t nomisbeme/customerapp:0.1.2 .
docker push nomisbeme/customerapp:0.1.2
```
8. Use the Kubernetes package manager, helm, to deploy the resulting application to Kubernetes.
```
helm install helm/customerapp/ -n capp
```
> Adjust the ingress.host to point to the correct domain name if needed.

9. Wait for the application to deploy then access it at your domain name.
```
open http://azure.baleenlabs.com
```

# Updating the application
Kubernetes and Helm make it easy to deploy new versions of an application, so we'll modify the application and deploy the result.

10. Modify the application. Hint: Uncomment list.jsp

11. Rebuild the application and push a new version to the Docker Hub:

```
mvn clean package
docker build -t nomisbeme/customerapp:fixed .
docker push nomisbeme/customerapp:fixed
```

12. Now update the existing deployment to reference the new code.

```
helm upgrade --set image.tag=fixed capp helm/customerapp
```

# Improvements
* Use Open Service Catalog for Azure to expose Cosmos within the Kubernetes cluster
* Use the Spotify maven plugins to simplify container image creation
* Use a private registry e.g. Azure Container Registry to avoid making application code publicly available.
* Replace kube-lego with the more modern replacement cert-manager
