#!/bin/bash
set -e
datasetName=$1
branchName=$2

if [ -z "$datasetName" ]; then
    echo "datasetName is empty"
    exit 1
fi

if [ -z "$branchName" ]; then
    branchName=$(git branch --show-current)
    commitSha=$(git rev-parse HEAD)
else
    commitSha=$(git rev-parse $branchName)
fi

gh workflow run test-dataset.yml -F "commit_sha=${commitSha}" -F "dataset_name=${datasetName}" -F branch_name="${branchName}"
open https://github.com/codecrafters-io/coderbot/actions
