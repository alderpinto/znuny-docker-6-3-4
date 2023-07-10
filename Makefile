
DOCKER_ID ?= alderpinto
IMAGE = znuny
VERSION ?= latest

.PHONY: build
build:
	@echo "Build docker image..."
	docker build --tag $(DOCKER_ID)/$(IMAGE):$(VERSION) .

.PHONY: push
push:
	@echo "Push docker image..."
	docker login
	docker push $(DOCKER_ID)/$(IMAGE):$(VERSION)

.PHONY: run
run:
	@echo "Run docker image..."
	docker run --name $(IMAGE) --rm -p 5000:5000 $(DOCKER_ID)/$(IMAGE):$(VERSION)
