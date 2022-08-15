Installing Kong Mesh with Terraform
===========================================================

This example stands up a simple Azure AKS cluster, then installs Kong Mesh Enterprise on that cluster in Standalone mode.

![](img/flat-diagram.png "Standalone Deployment")

## Prerequisites
1. AKS Credentials (App ID and Password)
2. Terraform CLI
3. Azure CLI
4. AKS Domain name
5. Kong Mesh Enterprise license

## Procedure

1. Insert your Enterprise license under `./license/license.json` of this directory.
2. Open `/tf-provision-aks/aks-cluster.tf` to search & replace `simongreen` with your own name.  That way, all AKS objects will be tagged with your name making them easily searchable. Also, update the Azure region in this file to the region of your choice.
3. If you haven't done so already, create an Active Directory service principal account via the CLI:

 ```bash
 az login
 az ad sp create-for-rbac --skip-assignment.  # This will give you the `appId` and `password` that Terraform requires to provision AKS.
 ```

4.  In `/tf-provision-aks` directory, create a file called `terraform.tfvars`.  Enter the following text, using your credentials from the previous command:

```bash
appId    = "******"
password = "******"
location = "East US"
```

5. Via the CLI, `cd tf-provision-aks/` then run the following Terraform commands to provisions AKS:

```bash
terraform init
terraform apply
```

6. Once terraform has stoodup AKS, setup `kubectl` to point to your new AKS instance:

```bash
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
kubectl get all
```

### Post install testing:

1. Check services:

`kubectl get ing -n kong-mesh-system -w`

2. Copy the external address.  This will form your GUI URL: `http://<external address>/gui`

3. Go through the wizard.  If you want to expose the Demo App over HTTP, there is an ingress rule in `../kic/demo-app.yaml`.  You can apply the ingress rule by executing:

```bash
kubectl apply -n main-application -f ../kic/demo-app.yaml
```
***
