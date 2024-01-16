# CoderBot

🚧 WIP, context: https://twitter.com/RohitPaulK/status/1697923773188464718

CoderBot is a fully autonomous agent that can fix a broken submission for a [CodeCrafters](https://codecrafters.io/) challenge. It
reads stage instructions to generate a first fix, and then iteratively corrects itself based on test output to
arrive at the final solution.

# Running tests

We use datasets from [CodeCrafters](https://codecrafters.io/) for testing.

You'll first need to download these using `make download_datasets`. This will download datasets to `tmp/datasets`.

You can then run tests against datasets.

## Local Tests

To test a single submission from a dataset, run:

````bash
DEBUG=true bundle exec rails runner scripts/validate_dataset.rb tmp/datasets/coderbot_v2_dataset_7 1```
````

## Github Actions Tests

To trigger a Github Actions run:

```bash
# commit your changes and push first
git add .
git commit -m "<message>"
git push origin <branch>

# Trigger a workflow run on the dataset you want
scripts/trigger_gh_workflow.sh coderbot_v2_dataset_7
```

Using GitHub Actions is recommended when you're testing against a full dataset. Local testing
can be useful when iterating on a single submission.
