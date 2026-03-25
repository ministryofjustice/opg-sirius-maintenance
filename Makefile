export DOCKER_BUILDKIT=1
all: lint gosec build test

lint: setup-directories
	docker compose run --rm go-lint

gosec:
	docker compose run --rm gosec

build:
	docker compose build maintenance

test-results:
	mkdir -p -m 0777 .cache test-results

setup-directories: test-results

test:
	docker compose up -d
	curl -s localhost:8888 | grep '<h1 class="govuk-heading-xl">Sirius is currently unavailable</h1>'
	curl -s -f localhost:8888/health-check
	docker compose down
