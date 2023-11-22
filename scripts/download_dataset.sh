#!/bin/bash
set -e

datasetName=$1

mkdir -p tmp/datasets
rm -rf "tmp/datasets/${datasetName}"
rm -rf "tmp/datasets/${datasetName}.zip"
wget -O "tmp/datasets/${datasetName}.zip" "https://codecrafters-coderbot-datasets.s3.amazonaws.com/${datasetName}.zip"
unzip "tmp/datasets/${datasetName}.zip" -d "tmp/datasets/${datasetName}"

chown -R $USER:$USER "tmp/datasets/${datasetName}"
