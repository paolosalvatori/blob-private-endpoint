#!/bin/bash

# Variables
blobServicePrimaryEndpoint=$1
fileSystemName=$2
directoryName=$3
fileName=$4
fileContent=$5

# Parameter validation
if [[ -z $blobServicePrimaryEndpoint ]]; then
    echo "blobServicePrimaryEndpoint cannot be null or empty"
    exit 1
else
    echo "blobServicePrimaryEndpoint: $blobServicePrimaryEndpoint"
fi

if [[ -z $fileSystemName ]]; then
    echo "fileSystemName parameter cannot be null or empty"
    exit 1
else
    echo "fileSystemName: $fileSystemName"
fi

if [[ -z $directoryName ]]; then
    echo "directoryName parameter cannot be null or empty"
    exit 1
else
    echo "directoryName: $directoryName"
fi

if [[ -z $fileName ]]; then
    echo "fileName parameter cannot be null or empty"
    exit 1
else
    echo "fileName: $fileName"
fi

if [[ -z $fileContent ]]; then
    echo "fileContent parameter cannot be null or empty"
    exit 1
else
    echo "fileContent: $fileContent"
fi

# Extract the storage name from the blob service primary endpoint
storageAccountName=$(echo "$blobServicePrimaryEndpoint" | awk -F'.' '{print $1}')

if [[ -z $storageAccountName ]]; then
    echo "storageAccountName cannot be null or empty"
    exit 1
else
    echo "storageAccountName: $storageAccountName"
fi

# Update the system
sudo apt-get update -y

# Upgrade packages
sudo apt-get upgrade -y

# Install curl and traceroute
sudo apt install -y curl traceroute

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Run nslookup to verify that the <storage-account>.blob.core.windows.net public hostname of the storage account 
# is properly mapped to <storage-account>.privatelink.blob.core.windows.net by the private DNS zone
# and the latter mapped to the private address by the A record
nslookup $blobServicePrimaryEndpoint

# Login using the virtual machine system-assigned managed identity
az login --identity

# Create file system for the Azure Data Lake Storage Gen2 account
az storage fs create \
    --name $fileSystemName \
    --account-name $storageAccountName

# Create a directory in the ADLS Gen2 file system
az storage fs directory create \
    --file-system $fileSystemName \
    --name $directoryName \
    --account-name $storageAccountName

# Create a file to upload to the ADLS Gen2 file system in the storage account
echo $fileContent > $fileName

# Upload the file to a file path in ADLS Gen2 file system.
az storage fs file upload \
    --file-system $fileSystemName \
    --path "$directoryName/$fileName" \
    --source "./$fileName" \
    --account-name $storageAccountName

# List files and directories in the directory in the ADLS Gen2 file system.
az storage fs file list \
    --file-system $fileSystemName \
    --path $directoryName \
    --account-name $storageAccountName