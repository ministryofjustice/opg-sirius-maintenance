export DOCKER_BUILDKIT=1
all: lint build security-test test

lint:
	docker run --rm -v $(PWD):/app -w /app golangci/golangci-lint:v1.43.0 golangci-lint run -v

build:
	docker-compose build app

scan:
	trivy image sirius-maintenance:latest

security-test:
	docker run --rm -it -e GO111MODULE=on -w /maintenance/ -v $(PWD)/:/maintenance securego/gosec /maintenance/...

test:
	docker-compose up -d
	curl -s localhost:8888 | grep '<h1 class="govuk-heading-xl">Sirius is currently unavailable</h1>'
	curl -s -f localhost:8888/health-check
	docker-compose down
