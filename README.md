# Azure-ML-k8s-deploy-research ([Main Doc.](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-attach-kubernetes-anywhere?view=azureml-api-2))

공식 문서에 따르면, Azure Machine Learning 온라인 엔드포인트를 Kubernetes 클러스터에 배포하는 시나리오는 아래 인덱스에 나타난 것처럼 총 네 개의 단계로 구성됩니다. 

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

- Azure CLI에 로그인합니다. 로그인 후 올바른 구독을 선택합니다.
  ```powershell
  az login
  ```

- Service Principal을 생성합니다. (기존 사용하던 Service Princpal이 있으면 생략 가능) 
  ```powershell
  PS C:\Users\이은상\Desktop> az ad sp create-for-rbac --name "{SERVICE_PRINCIPAL_NAME}" `
    --role contributor `
    --scopes /subscriptions/{SUBSCRIPTION_ID} `
    --sdk-auth
  ```

- AKS cluster를 생성합니다. (기존 사용하던 AKS cluster가 있으면 생략 가능)
  ```powershell
  PS C:\Users\이은상\Desktop> az aks create --resource-group inbrein-azure-ml-research `
    --name eunsang-aks-cluster `
    --node-count 1 `
    --generate-ssh-keys
  ```

- AKS cluster의 설정 파일 kubeconfig을 조회합니다.
  ```powershell
  PS C:\Users\이은상\Desktop> az aks get-credentials `
    --resource-group inbrein-azure-ml-research `
    --name eunsang-aks-cluster `
    --overwrite-existing
    --file kubeconfig 
  ```
  > 명령어를 실행하는 현 디렉토리에 kubeconfig 파일을 다운로드받습니다.

- Kubernetes 관리 도구 `kubectl`이 AKS에 생성되어있는 클러스터를 참조하도록 관련 환경변수를 설정합니다.
  ```powershell
  PS C:\Users\이은상\Desktop> $env:KUBECONFIG = "C:\Users\이은상\Desktop\kubeconfig"
  ```

- 직전 설정이 올바르게 적용되었는지 확인합니다. 아래와 같이, AKS에 생성되어있는 클러스터 정보가 조회되는지 확인합니다.  
  ```powershell
  PS C:\Users\이은상\Desktop> kubectl config get-contexts
  CURRENT   NAME                  CLUSTER               AUTHINFO                                                    NAMESPACE
  *         eunsang-aks-cluster   eunsang-aks-cluster   clusterUser_inbrein-azure-ml-research_eunsang-aks-cluster
  ```
  <details>
    <summary>
      <code><br>PS C:\Users\이은상\Desktop> kubectl get all -A<br></code>
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

- Kubernetes 관련 리소스 제공자를 등록합니다.   
  ```
  PS C:\Users\이은상\Desktop> az provider register --namespace Microsoft.KubernetesConfiguration
  ```

- 클러스터에 Azure Machine Learning 익스텐션을 설치합니다.  
  ```powershell 
  PS C:\Users\이은상\Desktop> az k8s-extension create `
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
  > 위 커맨드에서 사용된 옵션(config 이하 `enableTraining`, `enableInference` 등)은 테스팅 환경을 위한 최소한의 기본 옵션입니다. 프로덕션 환경에 맞는 세부 옵션 설정을 위해서는 [문서](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-kubernetes-extension?view=azureml-api-2&tabs=deploy-extension-with-cli#azure-machine-learning-extension-deployment---cli-examples-and-azure-portal)를 참고해주세요. 

- 클러스터에 Azure Machine Learning 익스텐션이 올바르게 설치되었는지 확인합니다. 
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

- AKS 클러스터에 Azure Machine Learning 관련 workloads가 위치할 네임스페이스를 추가합니다.  
  ```powershell 
  PS C:\Users\이은상\Desktop> kubectl create namespace eunsang-aks-compute
  ```

- Azure Machine Learning 리소스에 준비된 AKS 클러스터를 추가합니다.  
  ```powershell 
  PS C:\Users\이은상\Desktop> az ml compute attach `
	--resource-group inbrein-azure-ml-research `
	--workspace-name inbrein-azure-ml-research-eunsang `
	--type Kubernetes `
	--name k8s-compute `
	--resource-id "/subscriptions/e6b2576a-d64f-4ef2-a429-ec3fde2a21db/resourceGroups/inbrein-azure-ml-research/providers/Microsoft.ContainerService/managedclusters/eunsang-aks-cluster" `
	--identity-type SystemAssigned `
	--namespace eunsang-aks-compute `
	--no-wait
  ```

- Azure Machine Learning 워크스페이스에 AKS 클러스터가 올바르게 추가된 모습
  <img width="100%" alt="image" src="https://github.com/user-attachments/assets/7396c2af-5e52-4236-8f9f-46609d7f7533">


## 4. Use the Kubernetes compute target from the CLI v2, SDK v2, or the Azure Machine Learning studio UI

이전 설정이 모두 올바르게 진행되었다면, 마지막 단계의 설정 내용은 준비된 AKS 클러스터를 배포 파이프라인에 활용하는 것입니다. 

[파이프라인 스크립트](https://github.com/Kyrsang/Azure-ML-k8s-deploy-research/blob/main/scripts/scheduled_pipeline_job_k8s.yml) 중, AKS 클러스터 배포를 위해 변경된 부분을 살펴보면 다음과 같습니다. 

#### `create_endpoint` 스텝
   
: 온라인 엔드포인트를 생성하는 커맨드 `az ml online-endpoint { update | creaete }`에 사용되는 설정 파일 [automl_endpoint_k8s_settings.yml](https://github.com/Kyrsang/Azure-ML-k8s-deploy-research/blob/main/configs/Azure-CLI-Environment/automl_endpoint_k8s_settings.yml) 내용이 변경되었습니다. 아래는 해당 파일 상세 내용입니다.
 
```yaml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineEndpoint.schema.json
name: endpoint-eunsang-k8s
auth_mode: key
compute: azureml:k8s-compute    [1] 
identity:			 
type: system_assigned 
```
> [1] 해당 라인이 추가되었습니다. AKS에 추가된 클러스터 이름을 값으로 설정합니다.
  
#### `deploy_best_model` 스텝
   
: 온라인 엔드포인트를 배포하는 커맨드 `az ml online-deployment updat { update | create }`에 사용되는 설정 파일 [automl_deployment_k8s_settings.yml](https://github.com/Kyrsang/Azure-ML-k8s-deploy-research/blob/main/configs/Azure-CLI-Environment/automl_deployment_k8s_settings.yml) 내용이 변경되었습니다. 아래는 해당 파일 상세 내용입니다.

```yaml
$schema: https://azuremlschemas.azureedge.net/latest/kubernetesOnlineDeployment.schema.json

type: kubernetes 		  [1] 
app_insights_enabled: true	  [2] 

name: deployment-eunsang-k8s
endpoint_name: endpoint-eunsang-k8s

model:
  path: ./downloaded_artifacts/named-outputs/best_model/

code_configuration:
  code: ./
  scoring_script: score.py

environment: 
  conda_file: ./downloaded_artifacts/named-outputs/best_model/conda.yaml
  image: mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu20.04:latest

instance_type: defaultinstancetype   [3]   # Specify a custom InstanceType CRD name here if needed     
instance_count: 1
```
> [1] 배포 타입을 `kubernetes`로 설정합니다.
>
> [2] `app_insights_enabled`를 `true`로 설정합니다. 모니터링 리소스와 연관된 설정이라고 합니다.
> 
> [3] 배포 환경의 컴퓨팅 리소스 용량을 늘리기 위해 커스텀 컴퓨트 인스턴스를 생성하였다면 해당 CRD의 이름을 명시합니다. 테스트 환경에서는 CRD를 사용하지 않았으므로 기본값 (`defaultinstancetype`)으로 설정하였습니다.   

---
이상의 내용이 Azure Machine Learning 모델 엔드포인트를 Kubernetes 클러스터에 배포하기 위한 모든 설정 내용이었습니다. (AKS 클러스터 설정 / 파이프라인 참조 yaml 파일 설정 등)

Azure Machine Learning 워크스페이스 상 스케쥴링된 AutoML 배포 파이프라인을 생성을 위해서는, 기존 Managed Online Endpont 배포 시나리오와 동일하게 powershell 커맨드([k8s-endpoint-pipeline-infra.ps1](https://github.com/Kyrsang/Azure-ML-k8s-deploy-research/blob/main/.github/workflows/k8s-endpoint-pipeline-infra.ps1))를 실행합니다.  

