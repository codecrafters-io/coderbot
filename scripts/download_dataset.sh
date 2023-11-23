#!/bin/bash
set -e

datasetName=$1

mkdir -p tmp/datasets
rm -rf "tmp/datasets/${datasetName}"
rm -rf "tmp/datasets/${datasetName}.zip"

if [ "$CI" = "true" ]; then
    wget -q -O "tmp/datasets/${datasetName}.zip" "https://codecrafters-coderbot-datasets.s3.amazonaws.com/${datasetName}.zip"
else
    wget -O "tmp/datasets/${datasetName}.zip" "https://codecrafters-coderbot-datasets.s3.amazonaws.com/${datasetName}.zip"
fi

unzip -q "tmp/datasets/${datasetName}.zip" -d "tmp/datasets/${datasetName}"
