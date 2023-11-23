download_datasets:
	scripts/download_dataset.sh coderbot_dataset_7
	scripts/download_dataset.sh coderbot_dataset_35
	scripts/download_dataset.sh coderbot_dataset_140

test_small:
	gh workflow run test-dataset.yml -F commit_sha=$(shell git rev-parse HEAD) -F dataset_name=coderbot_dataset_7
	sleep 1
	echo $(shell gh run list --workflow=test-dataset.yml --json url | jq -r ".[0].url")

test_medium:
	gh workflow run test-dataset.yml -F commit_sha=$(shell git rev-parse HEAD) -F dataset_name=coderbot_dataset_35
	sleep 1
	echo $(shell gh run list --workflow=test-dataset.yml --json url | jq -r ".[0].url")

test_large:
	gh workflow run test-dataset.yml -F commit_sha=$(shell git rev-parse HEAD) -F dataset_name=coderbot_dataset_140
	sleep 1
	echo $(shell gh run list --workflow=test-dataset.yml --json url | jq -r ".[0].url")k

local_test_small:
	bundle exec rails runner scripts/validate_dataset.rb tmp/datasets/coderbot_dataset_7

local_test_1:
	bundle exec rails runner scripts/validate_dataset.rb tmp/datasets/coderbot_dataset_7 1
