#!/bin/bash
datasetName=$1
gh workflow run test-dataset.yml -F commit_sha=$(shell git rev-parse HEAD) -F "dataset_name=${datasetName}" -F branch_name="$(git branch --show-current)"
echo $(shell gh run list --workflow=test-dataset.yml --json url | jq -r ".[0].url")
