download_datasets:
	scripts/download_dataset.sh coderbot_v2_dataset_7
	scripts/download_dataset.sh coderbot_v2_dataset_35
	scripts/download_dataset.sh coderbot_v2_dataset_140

serve:
	lsof -t -i :5002 | xargs kill -9 # Kill orphaned rails server
	docker-compose up --build -d --remove-orphans
	DEBUG=true foreman start -f Procfile.dev -c "worker=2,web=1,scheduler=1"

test_small:
	scripts/trigger_gh_workflow.sh coderbot_v2_dataset_7

test_medium:
	scripts/trigger_gh_workflow.sh coderbot_v2_dataset_35

test_large:
	scripts/trigger_gh_workflow.sh coderbot_v2_dataset_140

test_large_against_main:
	scripts/trigger_gh_workflow.sh coderbot_v2_dataset_140 main
	scripts/trigger_gh_workflow.sh coderbot_v2_dataset_140

test_medium_against_main:
	scripts/trigger_gh_workflow.sh coderbot_dataset_35 main
	scripts/trigger_gh_workflow.sh coderbot_dataset_35

local_test_small:
	bundle exec rails runner scripts/validate_dataset.rb tmp/datasets/coderbot_v2_dataset_7

local_test_1:
	DEBUG=true bundle exec rails runner scripts/validate_dataset.rb tmp/datasets/coderbot_v2_dataset_7 1
