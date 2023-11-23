download_datasets:
	scripts/download_dataset.sh coderbot_dataset_7
	scripts/download_dataset.sh coderbot_dataset_35
	scripts/download_dataset.sh coderbot_dataset_140

test_small:
	scripts/trigger_gh_workflow.sh coderbot_dataset_7

test_medium:
	scripts/trigger_gh_workflow.sh coderbot_dataset_35

test_large:
	scripts/trigger_gh_workflow.sh coderbot_dataset_140

local_test_small:
	bundle exec rails runner scripts/validate_dataset.rb tmp/datasets/coderbot_dataset_7

local_test_1:
	bundle exec rails runner scripts/validate_dataset.rb tmp/datasets/coderbot_dataset_7 1
