#!/bin/bash
set -eo pipefail
while getopts a:b:c:d:e:f:g:h:i flag
do
    case "${flag}" in
        a) publisher=${OPTARG};;
        b) credentials=${OPTARG};;
        c) bucket=${OPTARG};;
        d) entity=${OPTARG};;
        e) sourceDir=${OPTARG};;
        f) azureAccountName=${OPTARG};;
        g) azureAccountKey=${OPTARG};;
        h) awsRoleArn=${OPTARG};;
        i) awsEndpoint=${OPTARG};;
    esac
done

pushd $GITHUB_WORKSPACE

if [[ ! -d $sourceDir ]]
then
  echo "$sourceDir does not exist"
  exit 0
fi
echo "Generating the docs from $sourceDir to $sourceDir/site/"

techdocs-cli generate --no-docker --verbose --source-dir "$sourceDir" --output-dir "$sourceDir/site"

if [[ $publisher == "googleGcs" ]]; then
    echo $credentials | base64 -d > /tmp/credentials

    echo "Publishing $entity to $publisher"
    GOOGLE_APPLICATION_CREDENTIALS=/tmp/credentials techdocs-cli publish \
        --publisher-type $publisher \
        --storage-name $bucket \
        --entity $entity \
        --directory "$sourceDir/site"

    exit 0
fi

creds=( $credentials )
if [[ $publisher == "awsS3" ]]; then
    AWS_ACCESS_KEY_ID=${creds[0]}
    AWS_SECRET_ACCESS_KEY=${creds[1]}
    AWS_REGION=${creds[2]}

    echo "Publishing $entity to $publisher"
    techdocs-cli publish \
        --publisher-type $publisher \
        --storage-name $bucket \
        --entity $entity \ 
        --awsRoleArn $awsRoleArn \
        --awsEndpoint $awsEndpoint \
        --directory "$sourceDir/site"
fi

if [[ $publisher == "azureBlobStorage" ]]; then
    AZURE_TENANT_ID=${creds[0]}
    AZURE_CLIENT_ID=${creds[1]}
    AZURE_CLIENT_SECRET=${creds[2]}
    techdocs-cli publish \
        --publisher-type $publisher \
        --storage-name $bucket \
        --entity $entity \ 
        --azureAccountName $azureAccountName \
        --azureAccountKey $azureAccountKey \
        --directory "$sourceDir/site"

    exit 0
fi

echo "Publisher $publisher not valid"

exit 1
