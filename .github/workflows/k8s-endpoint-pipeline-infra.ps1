# Credential 저장
$clientId = "{SERVICE_PRINCIPAL_CLIENT_ID}"
$clientSecret = "{SERVICE_PRINCIPAL_CLIENT_SECRET}"
$tenantId = "{TENANT_ID}"
$subscriptionId = "{SUBSCRIPTION_ID}"

az login --service-principal --username $clientId --password $clientSecret --tenant $tenantId

############################################################
# 1.1. CLI 실행 환경 준비
############################################################

# ACR 로그인
$acrName = "{ACR_인스턴스_이름}"
az acr login --name $acrName

# Docker 이미지 생성 및 ACR에 push
docker build `
    --build-arg AZURE_CLIENT_ID=$clientId `
    --build-arg AZURE_CLIENT_SECRET=$clientSecret `
    --build-arg AZURE_TENANT_ID=$tenantId `
    --build-arg AZURE_SUBSCRIPTION_ID=$subscriptionId `
    -t "$acrName.azurecr.io/azureml-with-azcli:latest" `
    -f "../../configs/Azure-CLI-Environment/Dockerfile" `
    "../../configs/Azure-CLI-Environment"

docker push "$acrName.azurecr.io/azureml-with-azcli:latest"

$resourceGroup = "{리소스_그룹_명}"
$workspaceName = "{워크스페이스_명}"

# 리소스 간 keys sync
az ml workspace sync-keys --resource-group $resourceGroup --name $workspaceName

# managed identity를 사용하기 위해 admin access disable 처리
$acrInstanceName = az ml workspace show --name $workspaceName --resource-group $resourceGroup --subscription $subscriptionId --query container_registry -o tsv
$acrBaseName = [System.IO.Path]::GetFileName($acrInstanceName)
az acr update --name $acrBaseName --admin-enabled false

############################################################
# 1.2. 컴퓨트 생성
############################################################

# Azure ML Compute Cluster 생성
az ml compute create --file "../../scripts/compute_cluster.yml" --resource-group $resourceGroup --workspace-name $workspaceName

############################################################
# 1.3. 스케쥴 예약
############################################################

# Azure ML Schedule 생성
az ml schedule create --file "../../scripts/scheduling_job_k8s.yml" --resource-group $resourceGroup --workspace-name $workspaceName

# 작업 종료 후 로그아웃
az logout