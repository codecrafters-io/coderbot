download_datasets:
	rm -rf tmp/datasets
	mkdir -p tmp/datasets
	wget -O tmp/datasets/coderbot_dataset_7.zip https://codecrafters-coderbot-datasets.s3.amazonaws.com/coderbot_dataset_7.zip
	wget -O tmp/datasets/coderbot_dataset_35.zip https://codecrafters-coderbot-datasets.s3.amazonaws.com/coderbot_dataset_35.zip
	wget -O tmp/datasets/coderbot_dataset_140.zip https://codecrafters-coderbot-datasets.s3.amazonaws.com/coderbot_dataset_140.zip
	unzip tmp/datasets/coderbot_dataset_7.zip -d tmp/datasets/coderbot_dataset_7
	unzip tmp/datasets/coderbot_dataset_35.zip -d tmp/datasets/coderbot_dataset_35
	unzip tmp/datasets/coderbot_dataset_140.zip -d tmp/datasets/coderbot_dataset_140

test_dataset_small:
	gh workflow run test-dataset-small.yml -F commit_sha=$(shell git rev-parse HEAD)

