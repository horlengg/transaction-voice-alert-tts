curl -v http://127.0.0.1:8000/openai/api/v1/speech/sreymom/en-us/generate \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"trxAmount": "1.25", "trxCurrency": "USD"}'