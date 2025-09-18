# Keycloak Agent Identity - Docker Usage

This project provides Docker containers for Keycloak with SPIFFE authentication plugins and automatic configuration setup.

## Architecture

- **Main Container**: Keycloak with SPIFFE plugins (`Dockerfile`)
- **Setup Container**: Python scripts for configuration (`Dockerfile.setup`)

## Quick Start

### Build Images

```bash
# Build main Keycloak image (with SPIFFE plugins baked in)
docker build -t keycloak-agent-identity .

# Build setup image (for configuration)
docker build -f Dockerfile.setup -t keycloak-agent-identity-setup .
```

### Run Setup Container
```bash
# Run the setup container to configure an existing Keycloak instance
docker compose up
```

The setup container will:
1. Wait for Keycloak to be ready at `http://host.docker.internal:8080`
2. Configure Keycloak using your `config.json` file
3. Exit when complete

## Configuration

### Environment Variables (Setup Container)
- `KEYCLOAK_URL`: Keycloak URL (default: `http://localhost:8080`)
- `CONFIG_FILE`: Path to config file (default: `/app/config.json`)
- `ADMIN_USERNAME`: Admin username (default: `admin`)
- `ADMIN_PASSWORD`: Admin password (default: `admin`)
- `MAX_RETRIES`: Max retries waiting for Keycloak (default: `30`)

### Config File
Mount your `config.json` file that defines:
- Realm settings with SPIFFE attributes
- Clients and their configurations
- Client scopes and role mappings
- Users and their roles
- Authentication flows

## Manual Usage

### Run Setup Container Directly
```bash
docker run --rm \
  -v $(pwd)/config.json:/app/config.json \
  -e KEYCLOAK_URL=http://host.docker.internal:8080 \
  keycloak-agent-identity-setup
```

### Run Keycloak Container
```bash
docker run -p 8080:8080 keycloak-agent-identity
```

## Kubernetes Deployment

For Kubernetes, use the setup container as an init container:
- **Init Container**: `keycloak-agent-identity-setup` configures Keycloak before startup
- **Main Container**: `keycloak-agent-identity` runs the server
- See `k8s-deployment.yaml` for complete example

## Features

- ✅ Keycloak 26.2.5 with SPIFFE plugins baked in
- ✅ Automatic configuration from JSON file
- ✅ Init container pattern for Kubernetes
- ✅ Configurable via environment variables
- ✅ Production-ready setup