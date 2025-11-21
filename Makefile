APP_NAME := go-book-crud-gin
MAIN := ./cmd/server/main.go

DOCKER_IMAGE_DEV := $(APP_NAME)-dev
DOCKER_IMAGE_PROD := $(APP_NAME)
DOCKER_PORT := 8080

.PHONY: dev run build test tidy fmt lint clean docker-clean

dev:
	@echo "Building dev image $(DOCKER_IMAGE_DEV)..."
	docker build --target dev -t $(DOCKER_IMAGE_DEV) .
	@echo "Starting dev container with hot reload on port $(DOCKER_PORT)..."
	docker run --rm -it \
		-p $(DOCKER_PORT):$(DOCKER_PORT) \
		-v "$$PWD":/app \
		$(DOCKER_IMAGE_DEV)

run:
	@echo "Building prod image $(DOCKER_IMAGE_PROD)..."
	docker build --target prod -t $(DOCKER_IMAGE_PROD) .
	@echo "Running $(DOCKER_IMAGE_PROD) on port $(DOCKER_PORT)..."
	docker run --rm -p $(DOCKER_PORT):$(DOCKER_PORT) $(DOCKER_IMAGE_PROD)

build:
	@echo "Building production image $(DOCKER_IMAGE_PROD)..."
	docker build --target prod -t $(DOCKER_IMAGE_PROD) .

test:
	@echo "Running tests in Docker..."
	docker run --rm \
		-v "$$PWD":/app \
		-w /app \
		golang:1.25.4-bookworm \
		go test ./... -v

fmt:
	@echo "Formatting..."
	go fmt ./...

lint:
	@echo "Linting..."
	go vet ./...

clean:
	@echo "Cleaning..."
	rm -rf bin/

tidy:
	@echo "Tidying..."
	go mod tidy

docker-clean:
	@echo "Removing Docker images..."
	-docker rmi $(DOCKER_IMAGE_DEV) $(DOCKER_IMAGE_PROD) 2>/dev/null || true
