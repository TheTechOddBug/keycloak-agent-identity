#!/bin/bash
set -e

# Default values
KEYCLOAK_URL=${KEYCLOAK_URL:-"http://localhost:8080"}
CONFIG_FILE=${CONFIG_FILE:-"/app/config.json"}
ADMIN_USERNAME=${ADMIN_USERNAME:-"admin"}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-"admin"}
MAX_RETRIES=${MAX_RETRIES:-30}

echo "🔧 Keycloak Setup Init Container"
echo "Keycloak URL: $KEYCLOAK_URL"
echo "Config file: $CONFIG_FILE"

# Wait for Keycloak to be ready
echo "⏳ Waiting for Keycloak to be ready..."
for i in $(seq 1 $MAX_RETRIES); do
    if curl -s -f "$KEYCLOAK_URL/realms/master" > /dev/null 2>&1; then
        echo "✅ Keycloak is ready!"
        break
    fi
    echo "Attempt $i/$MAX_RETRIES - Keycloak not ready yet..."
    sleep 2
done

# Final check
if ! curl -s -f "$KEYCLOAK_URL/realms/master" > /dev/null 2>&1; then
    echo "❌ Keycloak failed to start within expected time"
    exit 1
fi

echo "🔎 Environment variables:"
echo "  KEYCLOAK_URL: $KEYCLOAK_URL"
echo "  CONFIG_FILE: $CONFIG_FILE"
echo "  ADMIN_USERNAME: $ADMIN_USERNAME"
echo "  ADMIN_PASSWORD: $ADMIN_PASSWORD"
echo "  MAX_RETRIES: $MAX_RETRIES"

echo "🔎 Config file contents ($CONFIG_FILE):"
if [ -f "$CONFIG_FILE" ]; then
    cat "$CONFIG_FILE"
else
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Run setup
echo "🔧 Running Keycloak setup..."
python3 /app/setup_keycloak.py \
    --config "$CONFIG_FILE" \
    --url "$KEYCLOAK_URL" \
    --admin-user "$ADMIN_USERNAME" \
    --admin-pass "$ADMIN_PASSWORD" \
    --summary

if [ $? -eq 0 ]; then
    echo "✅ Keycloak setup completed successfully!"
else
    echo "❌ Keycloak setup failed!"
    exit 1
fi
