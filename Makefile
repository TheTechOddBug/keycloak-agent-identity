# Keycloak Agent Identity Makefile
# This Makefile provides targets for building and pushing Docker images

# Variables
KEYCLOAK_IMAGE_NAME ?= keycloak-agent-identity
SETUP_IMAGE_NAME ?= keycloak-agent-identity-setup
IMAGE_TAG ?= latest
KEYCLOAK_FULL_IMAGE_NAME = $(KEYCLOAK_IMAGE_NAME):$(IMAGE_TAG)
SETUP_FULL_IMAGE_NAME = $(SETUP_IMAGE_NAME):$(IMAGE_TAG)
PLATFORMS ?= linux/amd64,linux/arm64

# Default target
.PHONY: help
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Images built:"
	@echo "  $(KEYCLOAK_FULL_IMAGE_NAME) - Keycloak with SPIFFE plugins"
	@echo "  $(SETUP_FULL_IMAGE_NAME) - Python setup container"

.PHONY: build
build: ## Build multi-architecture Docker images (ARM64 + AMD64) - DEFAULT
	@echo "Building multi-architecture Keycloak image: $(KEYCLOAK_FULL_IMAGE_NAME)"
	@echo "Targeting platforms: $(PLATFORMS)"
	@if ! docker buildx version >/dev/null 2>&1; then \
		echo "Error: Docker buildx is not available. Please enable buildx or upgrade Docker."; \
		exit 1; \
	fi
	docker buildx build --platform $(PLATFORMS) -t $(KEYCLOAK_FULL_IMAGE_NAME) --load .
	@echo "Building multi-architecture setup image: $(SETUP_FULL_IMAGE_NAME)"
	docker buildx build --platform $(PLATFORMS) -f Dockerfile.setup -t $(SETUP_FULL_IMAGE_NAME) --load .
	@echo "Multi-architecture build complete!"

.PHONY: push
push: build ## Build and push both Docker images to Docker Hub
	@echo "Tagging images for Docker Hub..."
	docker tag $(KEYCLOAK_FULL_IMAGE_NAME) ceposta/$(KEYCLOAK_IMAGE_NAME):$(IMAGE_TAG)
	docker tag $(SETUP_FULL_IMAGE_NAME) ceposta/$(SETUP_IMAGE_NAME):$(IMAGE_TAG)
	@echo "Pushing Keycloak image to Docker Hub..."
	docker push ceposta/$(KEYCLOAK_IMAGE_NAME):$(IMAGE_TAG)
	@echo "Pushing setup image to Docker Hub..."
	docker push ceposta/$(SETUP_IMAGE_NAME):$(IMAGE_TAG)
	@echo "Push complete! Images available at:"
	@echo "  ceposta/$(KEYCLOAK_IMAGE_NAME):$(IMAGE_TAG)"
	@echo "  ceposta/$(SETUP_IMAGE_NAME):$(IMAGE_TAG)"
