#!/bin/bash
set -eo pipefail
# Inputs arrive as INPUT_* environment variables (see action.yml) rather than
# as args, which would leave the credential in /proc/1/cmdline for the
# repository-controlled MkDocs build below to read. The environment is just as
# readable via /proc/1/environ, so stash the secrets on unlinked file
# descriptors and re-exec with them unset; they are read back only once
# generation has finished. See https://hackerone.com/reports/4012368
if [[ -z $TECHDOCS_ACTION_STAGE ]]; then
    self=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")
    stash=$(mktemp -d)
    (umask 077; printf '%s' "$INPUT_CREDENTIALS" > "$stash/credentials")
    (umask 077; printf '%s' "$INPUT_AZUREACCOUNTKEY" > "$stash/azureAccountKey")
    exec 3<"$stash/credentials"
    exec 4<"$stash/azureAccountKey"
    rm -rf "$stash"

    unset INPUT_CREDENTIALS INPUT_AZUREACCOUNTKEY
    export TECHDOCS_ACTION_STAGE=build
    exec "$self"
fi

publisher=$INPUT_PUBLISHER
bucket=$INPUT_BUCKET
entity=$INPUT_ENTITY
sourceDir=${INPUT_SOURCEDIR:-.}
azureAccountName=$INPUT_AZUREACCOUNTNAME
awsRoleArn=$INPUT_AWSROLEARN
awsEndpoint=$INPUT_AWSENDPOINT

pushd $GITHUB_WORKSPACE

if [[ ! -d $sourceDir ]]
then
  echo "$sourceDir does not exist"
  exit 0
fi
# Markdown extensions such as pymdownx.snippets follow symlinks, so a link
# escaping the source tree (the report's `proc -> /proc`) reads arbitrary files
# inside the container. Refuse to build such a tree. .git is excluded because
# actions/checkout leaves the GITHUB_TOKEN in .git/config.
root=$(cd "$sourceDir" && pwd -P)
escaping=$(find "$root" -name .git -prune -o -type l -print | while read -r link
do
    target=$(readlink -f -- "$link")
    if [[ $target == "$root"/.git || $target == "$root"/.git/* ]]
    then
      echo "$link"
    elif [[ $target != "$root" && $target != "$root"/* ]]
    then
      echo "$link"
    fi
done)
if [[ -n $escaping ]]
then
  echo "::error::Refusing to generate docs, these symlinks escape $sourceDir: $escaping"
  exit 1
fi

echo "Generating the docs from $sourceDir to $sourceDir/site/"

techdocs-cli generate --no-docker --verbose --source-dir "$sourceDir" --output-dir "$sourceDir/site"

# Generation is over, so the credentials can come back off their descriptors.
credentials=$(cat <&3)
azureAccountKey=$(cat <&4)

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
