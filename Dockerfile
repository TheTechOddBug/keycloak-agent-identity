# Multi-stage Dockerfile for Keycloak Agent Identity
# This creates a Keycloak image with SPIFFE plugins and setup scripts
# The actual setup is handled by a separate Python container

# Stage 1: Build custom Keycloak image with SPIFFE plugins
FROM quay.io/keycloak/keycloak:26.2.5 AS keycloak-base

# Copy SPIFFE plugins into Keycloak providers directory
COPY keycloak/spiffe-svid-client-authenticator-1.0.0.jar /opt/keycloak/providers/
COPY keycloak/spiffe-dcr-spi-1.0.0.jar /opt/keycloak/providers/

# Stage 2: Python environment with setup scripts
FROM python:3.11-slim AS python-setup

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir requests

# Create app directory
WORKDIR /app

# Copy Python setup scripts
COPY keycloak/setup_keycloak.py /app/
COPY keycloak/boot_keycloak.py /app/
COPY run_keycloak.py /app/

# Stage 3: Final Keycloak image with SPIFFE plugins
FROM quay.io/keycloak/keycloak:26.2.5 AS final

# Copy SPIFFE plugins from keycloak-base stage
COPY --from=keycloak-base /opt/keycloak/providers/spiffe-svid-client-authenticator-1.0.0.jar /opt/keycloak/providers/
COPY --from=keycloak-base /opt/keycloak/providers/spiffe-dcr-spi-1.0.0.jar /opt/keycloak/providers/

# Create app directory
WORKDIR /app

# Create entrypoint script
COPY <<EOF /app/entrypoint.sh
#!/bin/bash
set -e

echo "🚀 Starting Keycloak Agent Identity Server"
echo "Keycloak URL: http://localhost:8080"

# Start Keycloak
echo "🔧 Starting Keycloak server..."
exec /opt/keycloak/bin/kc.sh start-dev \
    --http-enabled=true \
    --hostname=0.0.0.0 \
    --hostname-port=8080 \
    --hostname-strict=false \
    --health-enabled=true
EOF

# Make entrypoint script executable
USER root
RUN chmod +x /app/entrypoint.sh

# Expose Keycloak port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD timeout 5 bash -c "</dev/tcp/localhost/8080" || exit 1

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command
CMD []