# FYI:
# Naming convention for images is $(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/$(DOCKER_IMAGE_NAME)-$(DOCKER_IMAGE_ENV):$(DOCKER_IMAGE_TAG)
# e.g.                docker.io/asapdotid/node:latest
# $(DOCKER_REGISTRY)   ---^        ^       ^     ^      docker.io
# $(DOCKER_NAMESPACE)  ------------^       ^     ^      asapdotid
# $(DOCKER_IMAGE_NAME) --------------------^     ^      node
# $(DOCKER_IMAGE_TAG)  --------------------------^		latest

DOCKER_DIR:=./src
BUILD_SERVICE_NAME:=node
DOCKER_BUILD_IMAGE_FILE:=$(DOCKER_DIR)/$(BUILD_SERVICE_NAME)/$(VER)/Dockerfile-$(TAG)

TAGGING?=

ifeq ($(TAG),)
	echo "Please provide tag!"
else
	TAGGING:=$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/$(DOCKER_IMAGE_NAME):$(VER)-$(TAG)
endif

# Run Build Docker Image
DOCKER_BUILD_COMMAND:= \
    docker buildx build \
	--platform ${DOCKER_IMAGE_PLATFORM} \
    -f $(DOCKER_BUILD_IMAGE_FILE) \
	-t $(TAGGING) --push .

# Run Push Docker Image
DOCKER_PUSH_COMMAND:= \
	docker push $(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/$(DOCKER_IMAGE_NAME):$(TAG)

##@ [Docker]

.PHONY: build
build: ## Docker build image with arguments VER="8.1" or with TAG=latest
	@$(DOCKER_BUILD_COMMAND)

.PHONY: push
push: ## Docker push image with arguments VER="8.1" or with TAG=latest
	@$(DOCKER_PUSH_COMMAND)
