# Azure-ML-k8s-deploy-research ([Main Doc.](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-attach-kubernetes-anywhere?view=azureml-api-2))

### Index 
  1. [Prepare an Azure Kubernetes Service cluster](#1-prepare-an-azure-kubernetes-service-cluster)
  2. [Deploy the Azure Machine Learning cluster extension](#2-deploy-the-azure-machine-learning-extension-on-aks-or-arc-kubernetes-cluster)
  3. [Attach the Kubernetes cluster to your Azure Machine Learning workspace](#3-attach-the-kubernetes-cluster-to-your-azure-machine-learning-workspace)
  4. [Use the Kubernetes compute target from the CLI v2, SDK v2, or the Azure Machine Learning studio UI](#4-use-the-kubernetes-compute-target-from-the-cli-v2-sdk-v2-or-the-azure-machine-learning-studio-ui)

### Version Table 
|             | Version       |
|-------------|---------------|
| Kubernetes version | 1.29.8 |
| Location    | Korea Central |
| Network Conf      | kubenet |

## 1. Prepare an Azure Kubernetes Service cluster
Service Principal 생성 (기존 사용하던 Service Princpal이 있으면 생략 가능) 
```powershell
az ad sp create-for-rbac --name "{SERVICE_PRINCIPAL_NAME}" `
  --role contributor `
  --scopes /subscriptions/{SUBSCRIPTION_ID} `
  --sdk-auth
```
> This will then return a response of credentials in JSON format. Save the JSON as a repository secret with the name of `AZURE_CREDENTIALS`, which will then later be used in Azure CLI login in the GitHub workflow. 

Create a public AKS cluster by running a [workflow](https://github.com/Kyrsang/Azure-ML-automation-research/blob/main/.github/workflows/k8s-1-create-public-AKS-cluster.yml) that creates a cluster and upload a `kubeconfig` file. 

Then download the `kubeconfig` file that is uploaded as an artifact from the result page of the workflow's run:
```
PS C:\Users> ls
...
-a----      2024-10-14  오후 12:51           9809 kubeconfig
```
> Ensure that the directory path containing the `kubeconfig` file does not include any characters that are not supported by the 'cp949' codec, such as Korean characters.

To configure kubectl to refer to the cluster in AKS, set the KUBECONFIG environment variable as follows:
```
PS C:\Users> $env:KUBECONFIG = "C:\Users\kubeconfig"
```

You will see that you are successfully connected to the cluster in AKS:

```
PS C:\Users> kubectl config get-contexts
CURRENT   NAME                  CLUSTER               AUTHINFO                                                    NAMESPACE
*         eunsang-aks-cluster   eunsang-aks-cluster   clusterUser_inbrein-azure-ml-research_eunsang-aks-cluster
```

<details>
  <summary>
    <code><br>PS C:\Users> kubectl get all -A<br></code>
  </summary>
  <br>
  
  ```shell
  NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
  kube-system   pod/azure-ip-masq-agent-gfnvs             1/1     Running   0          17m
  kube-system   pod/cloud-node-manager-4wxrb              1/1     Running   0          17m
  kube-system   pod/coredns-597bb9d4db-42gmw              1/1     Running   0          16m
  kube-system   pod/coredns-597bb9d4db-4jmpg              1/1     Running   0          17m
  kube-system   pod/coredns-autoscaler-689db4649c-2f9d2   1/1     Running   0          17m
  kube-system   pod/csi-azuredisk-node-jjdpp              3/3     Running   0          17m
  kube-system   pod/csi-azurefile-node-9wwht              3/3     Running   0          17m
  kube-system   pod/konnectivity-agent-85d8d6f866-9pcqh   1/1     Running   0          17m
  kube-system   pod/konnectivity-agent-85d8d6f866-tdxc5   1/1     Running   0          17m
  kube-system   pod/kube-proxy-pnhs2                      1/1     Running   0          17m
  kube-system   pod/metrics-server-7b685846d6-2wjqc       2/2     Running   0          16m
  kube-system   pod/metrics-server-7b685846d6-zcrvh       2/2     Running   0          16m
  
  NAMESPACE     NAME                     TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)         AGE
  default       service/kubernetes       ClusterIP   10.0.0.1     <none>        443/TCP         18m
  kube-system   service/kube-dns         ClusterIP   10.0.0.10    <none>        53/UDP,53/TCP   17m
  kube-system   service/metrics-server   ClusterIP   10.0.9.56    <none>        443/TCP         17m
  
  NAMESPACE     NAME                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
  kube-system   daemonset.apps/azure-ip-masq-agent          1         1         1       1            1           <none>          17m
  kube-system   daemonset.apps/cloud-node-manager           1         1         1       1            1           <none>          17m
  kube-system   daemonset.apps/cloud-node-manager-windows   0         0         0       0            0           <none>          17m
  kube-system   daemonset.apps/csi-azuredisk-node           1         1         1       1            1           <none>          17m
  kube-system   daemonset.apps/csi-azuredisk-node-win       0         0         0       0            0           <none>          17m
  kube-system   daemonset.apps/csi-azurefile-node           1         1         1       1            1           <none>          17m
  kube-system   daemonset.apps/csi-azurefile-node-win       0         0         0       0            0           <none>          17m
  kube-system   daemonset.apps/kube-proxy                   1         1         1       1            1           <none>          17m
  
  NAMESPACE     NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
  kube-system   deployment.apps/coredns              2/2     2            2           17m
  kube-system   deployment.apps/coredns-autoscaler   1/1     1            1           17m
  kube-system   deployment.apps/konnectivity-agent   2/2     2            2           17m
  kube-system   deployment.apps/metrics-server       2/2     2            2           17m
  
  NAMESPACE     NAME                                            DESIRED   CURRENT   READY   AGE
  kube-system   replicaset.apps/coredns-597bb9d4db              2         2         2       17m
  kube-system   replicaset.apps/coredns-autoscaler-689db4649c   1         1         1       17m
  kube-system   replicaset.apps/konnectivity-agent-85d8d6f866   2         2         2       17m
  kube-system   replicaset.apps/metrics-server-7b445dd694       0         0         0       17m
  kube-system   replicaset.apps/metrics-server-7b685846d6       2         2         2       16m
  ```
</details>

## 2. Deploy the Azure Machine Learning extension on AKS or Arc Kubernetes cluster

Register resource providers for subscription by running: 
```
az provider register --namespace Microsoft.KubernetesConfiguration
```

Install Azure Machine Learning extension on the cluster by running: 
```powershell 
az k8s-extension create `
	--name eunsang-aks-cluster-ml-extension `
	--extension-type Microsoft.AzureML.Kubernetes `
	--cluster-type managedClusters `
	--cluster-name eunsang-aks-cluster `
	--resource-group inbrein-azure-ml-research `
	--scope cluster `
	--config `
		enableTraining=True `
		enableInference=True `
		inferenceRouterServiceType=LoadBalancer `
		allowInsecureConnections=True `
		InferenceRouterHA=False 
```
> The parameters are set for a quick proof of concept to run various ML workloads. For more detailed deployment requirements, refer [here](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-kubernetes-extension?view=azureml-api-2&tabs=deploy-extension-with-cli#azure-machine-learning-extension-deployment---cli-examples-and-azure-portal). 

<details>
  <summary>Registration success response (view details) </summary>
  <br>
  
  ```json
{
  "aksAssignedIdentity": {
    "principalId": "cc75d747-af29-4cf7-b8a6-1115c1c0c521",
    "tenantId": null,
    "type": null
  },
  "autoUpgradeMinorVersion": true,
  "configurationProtectedSettings": {},
  "configurationSettings": {
    "InferenceRouterHA": "False",
    "allowInsecureConnections": "True",
    "clusterId": "/subscriptions/e6b2576a-d64f-4ef2-a429-ec3fde2a21db/resourceGroups/inbrein-azure-ml-research/providers/Microsoft.ContainerService/managedClusters/eunsang-aks-cluster",
    "clusterPurpose": "DevTest",
    "cluster_name": "/subscriptions/e6b2576a-d64f-4ef2-a429-ec3fde2a21db/resourceGroups/inbrein-azure-ml-research/providers/Microsoft.ContainerService/managedClusters/eunsang-aks-cluster",
    "cluster_name_friendly": "eunsang-aks-cluster",
    "domain": "koreacentral.cloudapp.azure.com",
    "enableInference": "True",
    "enableTraining": "True",
    "inferenceRouterHA": "false",
    "inferenceRouterServiceType": "LoadBalancer",
    "jobSchedulerLocation": "koreacentral",
    "location": "koreacentral",
    "nginxIngress.enabled": "true",
    "prometheus.prometheusSpec.externalLabels.cluster_name": "/subscriptions/e6b2576a-d64f-4ef2-a429-ec3fde2a21db/resourceGroups/inbrein-azure-ml-research/providers/Microsoft.ContainerService/managedClusters/eunsang-aks-cluster",
    "relayserver.enabled": "false",
    "servicebus.enabled": "false"
  },
  "currentVersion": "1.1.61",
  "customLocationSettings": null,
  "errorInfo": null,
  "extensionType": "microsoft.azureml.kubernetes",
  "id": "/subscriptions/e6b2576a-d64f-4ef2-a429-ec3fde2a21db/resourceGroups/inbrein-azure-ml-research/providers/Microsoft.ContainerService/managedClusters/eunsang-aks-cluster/providers/Microsoft.KubernetesConfiguration/extensions/eunsang-aks-cluster-ml-extension",
  "identity": null,
  "isSystemExtension": false,
  "name": "eunsang-aks-cluster-ml-extension",
  "packageUri": null,
  "plan": null,
  "provisioningState": "Succeeded",
  "releaseTrain": "stable",
  "resourceGroup": "inbrein-azure-ml-research",
  "scope": {
    "cluster": {
      "releaseNamespace": "azureml"
    },
    "namespace": null
  },
  "statuses": [],
  "systemData": {
    "createdAt": "2024-10-14T04:20:28.942789+00:00",
    "createdBy": null,
    "createdByType": null,
    "lastModifiedAt": "2024-10-14T04:20:28.942789+00:00",
    "lastModifiedBy": null,
    "lastModifiedByType": null
  },
  "type": "Microsoft.KubernetesConfiguration/extensions",
  "version": null
}
  ```
</details>

You will see the Azure Machine Learning extensions deployed on the kubernetes cluster under `azureml` namespace:  

```powershell
PS C:\Users> kubectl get pods -n azureml
NAME                                                              READY   STATUS      RESTARTS   AGE
aml-operator-6fbbddb96f-s27l2                                     2/2     Running     0          8m19s
amlarc-identity-controller-7dd4f65648-f82sn                       2/2     Running     0          8m19s
amlarc-identity-proxy-84dddf8f67-l42jc                            2/2     Running     0          8m19s
azureml-fe-v2-5fb6689988-6kqvj                                    4/4     Running     0          8m19s
azureml-ingress-nginx-controller-5bff665f9-bbjrw                  1/1     Running     0          8m19s
eunsang-aks-cluster-ml-extension-kube-state-metrics-68784fm9px4   1/1     Running     0          8m19s
eunsang-aks-cluster-ml-extension-prometheus-operator-654c49ps4x   1/1     Running     0          8m19s
gateway-5cb9cdbd49-k9sxm                                          2/2     Running     0          8m19s
healthcheck                                                       0/1     Completed   0          9m27s
inference-operator-controller-manager-65f5f74987-b4cxc            2/2     Running     0          8m19s
metrics-controller-manager-bf7cfb5df-4nxm5                        2/2     Running     0          8m19s
prometheus-prom-prometheus-0                                      2/2     Running     0          7m55s
volcano-admission-cd84d5769-pfhz6                                 1/1     Running     0          8m19s
volcano-controllers-76f648b6b4-bx4hx                              1/1     Running     0          8m19s
volcano-scheduler-58d96746b9-n4h7h                                1/1     Running     0          8m19s
```

## 3. Attach the Kubernetes cluster to your Azure Machine Learning workspace

Attach an AKS cluster to Azure Machine Learning workspace by running: 
```powershell 
az ml compute attach `
	--resource-group inbrein-azure-ml-research `
	--workspace-name inbrein-azure-ml-research-eunsang `
	--type Kubernetes `
	--name k8s-compute `
	--resource-id "/subscriptions/e6b2576a-d64f-4ef2-a429-ec3fde2a21db/resourceGroups/inbrein-azure-ml-research/providers/Microsoft.ContainerService/managedclusters/eunsang-aks-cluster" `
	--identity-type SystemAssigned `
	--namespace eunsang-aks-compute `
	--no-wait
```

You need to ensure that a namespace for Azure Machine Learning workloads exists on the cluster. The following command will effecively create a new namespace for our project:  
```powershell 
PS C:\Users> kubectl create namespace eunsang-aks-compute
```

<details>
  <summary> Kubernetes cluster attachment view </summary>
  <img width="100%" alt="image" src="https://github.com/user-attachments/assets/fc1573e5-47a0-4896-8db3-dd4b594be853">
</details>

## 4. Use the Kubernetes compute target from the CLI v2, SDK v2, or the Azure Machine Learning studio UI

The endpoint will use the Kubernetes cluster as the compute resource, as shown in the snippet below:
```yaml 
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineEndpoint.schema.json
name: endpoint-eunsang-k8s
auth_mode: key
compute: azureml:k8s-compute
identity:
  type: system_assigned
```

Create a pipeline schedule by running a [workflow](https://github.com/Kyrsang/Azure-ML-automation-research/blob/main/.github/workflows/k8s-2-azure-ml-pipeline-infra.yml) and run the scheduled job on Azure Machine Learning UI. 
