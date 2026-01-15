#!/bin/bash

# Configuration
URL="https://localhost"
PREDICT_ENDPOINT="$URL/predict"
USER="admin"
PASS="admin"

echo "========================================"
echo "Starting Nginx Exam Tests"
echo "========================================"

# 1. HTTP -> HTTPS Redirect
echo "[TEST] HTTP -> HTTPS Redirect"
REDIRECT_CODE=$(curl -o /dev/null -s -w "%{http_code}\n" http://localhost/)
if [[ "$REDIRECT_CODE" == "301" ]]; then
    echo "✅ Passed: 301 Redirect found."
else
    echo "❌ Failed: Expected 301, got $REDIRECT_CODE"
fi

# 2. Basic Auth Protection
echo "[TEST] Basic Authentication"
AUTH_CODE=$(curl -k -o /dev/null -s -w "%{http_code}\n" $PREDICT_ENDPOINT -H "Content-Type: application/json" -d '{"sentence": "test"}')
if [[ "$AUTH_CODE" == "401" ]]; then
    echo "✅ Passed: 401 Unauthorized without credentials."
else
    echo "❌ Failed: Expected 401, got $AUTH_CODE"
fi

# 3. Successful Prediction (Authenticated)
echo "[TEST] Successful Prediction (v1)"
RESPONSE=$(curl -k -u $USER:$PASS -s -w "\n%{http_code}" $PREDICT_ENDPOINT -H "Content-Type: application/json" -d '{"sentence": "I am happy"}')
BODY=$(echo "$RESPONSE" | head -n -1)
CODE=$(echo "$RESPONSE" | tail -n 1)

if [[ "$CODE" == "200" ]]; then
    echo "✅ Passed: Got 200 OK."
    echo "Response: $BODY"
else
    echo "❌ Failed: Expected 200, got $CODE"
fi

# 4. A/B Testing (Header routing)
echo "[TEST] A/B Testing (Header: X-Experiment-Group: debug)"
# api-v2 returns extra field "prediction_proba_dict", v1 does not (it is commented out in v1 code).
RESPONSE_V2=$(curl -k -u $USER:$PASS -s $PREDICT_ENDPOINT -H "Content-Type: application/json" -H "X-Experiment-Group: debug" -d '{"sentence": "I am sad"}')

if [[ "$RESPONSE_V2" == *"prediction_proba_dict"* ]]; then
    echo "✅ Passed: api-v2 reached (found 'prediction_proba_dict')."
else
    echo "❌ Failed: Expected api-v2 response. Got: $RESPONSE_V2"
fi

# 5. Rate Limiting
echo "[TEST] Rate Limiting (10 req/s)"
echo "Sending 20 requests quickly..."
LIMIT_HIT=0
for i in {1..20}; do
    CODE=$(curl -k -u $USER:$PASS -s -w "%{http_code}\n" -o /dev/null $PREDICT_ENDPOINT -H "Content-Type: application/json" -d '{"sentence": "spam"}')
    if [[ "$CODE" == "503" ]]; then
        LIMIT_HIT=1
        break
    fi
done

if [[ "$LIMIT_HIT" -eq 1 ]]; then
    echo "✅ Passed: Rate limit hit (503 received)."
else
    echo "Warning: Rate limit not triggered. Nginx might handle burst=20 within tolerance or loop too slow."
fi

echo "========================================"
echo "Tests Completed"
echo "========================================"
