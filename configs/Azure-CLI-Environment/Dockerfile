FROM mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu20.04:20231002.v1

# Set build arguments for Azure credentials
ARG AZURE_CLIENT_ID
ARG AZURE_CLIENT_SECRET
ARG AZURE_TENANT_ID
ARG AZURE_SUBSCRIPTION_ID

# Install Azure CLI
RUN apt-get update && \
    apt-get install -y curl && \
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    apt-get clean

# Set the working directory
WORKDIR /app

# Copy the dataset
COPY iris.csv /app/datasets/iris.csv

# Copy the MLTable file
COPY MLTable /app/datasets/MLTable

# Copy automl create config file 
COPY automl_settings.yml /app/configs/automl_settings.yml

# Copy automl register config file 
COPY best_model_settings.yml /app/configs/best_model_settings.yml

# Copy endpoint config file 
COPY automl_endpoint_k8s_settings.yml /app/configs/automl_endpoint_k8s_settings.yml

# Copy kubernetes cluster deployment config file 
COPY automl_deployment_k8s_settings.yml /app/configs/automl_deployment_k8s_settings.yml

# Copy score.py file 
COPY score.py /app/configs/score.py

# Log in to Azure
RUN az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

# Install Azure ML CLI extension
RUN az extension add -n ml

# Set active subscription 
RUN az account set -s $AZURE_SUBSCRIPTION_ID

# Verify installation
RUN az --version
