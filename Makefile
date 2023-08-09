export DOCKER_BUILDKIT=1
all: lint gosec build scan test

lint: setup-directories
	docker compose run --rm go-lint

gosec:
	docker compose run --rm gosec

build:
	docker compose build maintenance

test-results:
	mkdir -p -m 0777 .trivy-cache .cache test-results

setup-directories: test-results

scan: setup-directories
	docker compose run --rm trivy image --format table --exit-code 0 sirius-maintenance:latest
	docker compose run --rm trivy image --format sarif --output /test-results/trivy.sarif --exit-code 1 sirius-maintenance:latest

test:
	docker compose up -d
	curl -s localhost:8888 | grep '<h1 class="govuk-heading-xl">Sirius is currently unavailable</h1>'
	curl -s -f localhost:8888/health-check
	docker compose down
