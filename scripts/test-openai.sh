set -e
set -x

source .env

curl --request POST \
    --url https://oai.hconeai.com/openai/deployments/gpt-4-1106-preview/chat/completions?api-version=2023-03-15-preview \
    --header "Helicone-Auth: Bearer ${HELICONE_API_KEY}" \
    --header "Helicone-OpenAI-Api-Base: ${AZURE_OPENAI_ENDPOINT}" \
    --header "api-key: ${AZURE_OPENAI_API_KEY}" \
    --header "content-type: application/json" \
    --data '{
    "messages": [
      {
        "role": "user",
        "content": "Answer in one word"
      }],
    "max_tokens": 800,
    "temperature": 1,
    "model": "gpt-4-1106-preview"
  }'
