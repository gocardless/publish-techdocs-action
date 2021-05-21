#!/bin/bash
while getopts a:b:c:d:e:f:g:h flag
do
    case "${flag}" in
        a) publisher=${OPTARG};;
        b) credentials=${OPTARG};;
        c) bucket=${OPTARG};;
        d) entity=${OPTARG};;
        e) azureAccountName=${OPTARG};;
        f) azureAccountKey=${OPTARG};;
        g) awsRoleArn=${OPTARG};;
        h) awsEndpoint=${OPTARG};;
    esac
done

echo "Generating the docs" 
techdocs-cli generate --no-docker --verbose

publishCmd="techdocs-cli publish \
        --publisher-type $publisher \
        --storage-name $bucket \
        --entity $entity"

if [[ $publisher == "googleGcs" ]]; then
    GOOGLE_APPLICATION_CREDENTIALS=$credentials
fi 

creds=( $credentials )
if [[ $publisher == "awsS3" ]]; then
    AWS_ACCESS_KEY_ID=${creds[0]}
    AWS_SECRET_ACCESS_KEY=${creds[1]}
    AWS_REGION=${creds[2]}
    publishCmd = "$publishCmd --awsRoleArn $awsRoleArn --awsEndpoint $awsEndpoint"
fi

if [[ $publisher == "azureBlobStorage" ]]; then
    AZURE_TENANT_ID=${creds[0]}
    AZURE_CLIENT_ID=${creds[1]}
    AZURE_CLIENT_SECRET=${creds[2]}
    publishCmd = "$publishCmd --azureAccountName $azureAccountName --azureAccountKey $azureAccountKey"
fi 

echo "Publishing $entity to $publisher" 
eval $publishCmd