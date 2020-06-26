#!/bin/bash

# Variables
adlsServicePrimaryEndpoint=$1
blobServicePrimaryEndpoint=$2
fileSystemName=$3
directoryName=$4
fileName=$5
fileContent=$6

# Parameter validation
if [[ -z $adlsServicePrimaryEndpoint ]]; then
    echo "adlsServicePrimaryEndpoint cannot be null or empty"
    exit 1
else
    echo "adlsServicePrimaryEndpoint: $adlsServicePrimaryEndpoint"
fi

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

# Extract the adls storage account name from the adls service primary endpoint
storageAccountName=$(echo "$adlsServicePrimaryEndpoint" | awk -F'.' '{print $1}')

if [[ -z $storageAccountName ]]; then
    echo "storageAccountName cannot be null or empty"
    exit 1
else
    echo "storageAccountName: $storageAccountName"
fi

# Eliminate debconf: warnings
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Update the system
sudo apt-get update -y

# Upgrade packages
sudo apt-get upgrade -y

# Install curl and traceroute
sudo apt install -y curl traceroute

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Run nslookup to verify that the <storage-account>.dfs.core.windows.net public hostname of the storage account 
# is properly mapped to <storage-account>.privatelink.dfs.core.windows.net by the privatelink.dfs.core.windows.net 
# private DNS zone and the latter is resolved to the private address by the A record
nslookup $adlsServicePrimaryEndpoint

# Run nslookup to verify that the <storage-account>.blob.core.windows.net public hostname of the storage account 
# is properly mapped to <storage-account>.privatelink.blob.core.windows.net by the privatelink.blob.core.windows.net 
# private DNS zone and the latter is resolved to the private address by the A record
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