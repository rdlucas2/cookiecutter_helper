.PHONY: build build-test test run debug clean \
       sonar-start sonar-scan sonar-logs \
       trivy-scan trivy-scan-json \
       lint-dockerfile lint-python \
       help

# --- Load .env (gitignored) ---
-include .env
export

# --- Configuration ---
IMAGE_NAME       ?= repo-generator
TEST_IMAGE_NAME  ?= repo-generator-test
TEMPLATE_URL     ?= https://github.com/cookiecutter-flask/cookiecutter-flask
REPO_URL         ?= https://github.com/rdlucas2/improved-fiesta
GITHUB_TOKEN     ?= YOUR_TOKEN_HERE
JSON_FILE_PATH   ?= /app/output/overrides.json
SONAR_TOKEN      ?= <your-generated-token>

# --- Build ---
build: ## Build the artifact image
	docker build -t $(IMAGE_NAME) .

build-test: ## Build the test image
	docker build -t $(TEST_IMAGE_NAME) . --target test

# --- Test ---
test: build-test ## Run tests with coverage
	docker run -it --rm -v $(PWD):/coverage $(TEST_IMAGE_NAME)
	# Replace the absolute path /app with the relative path or new root
	@sed -i 's|<source>/app</source>|<source>/usr/src</source>|g' coverage.xml


# --- Run ---
run: build ## Run the repo generator
	docker run -it --rm \
		-v $(PWD)/generated_code:/app/output \
		$(IMAGE_NAME) \
		--template_url $(TEMPLATE_URL) \
		--repo_url $(REPO_URL) \
		--token $(GITHUB_TOKEN) \
		--json_file $(JSON_FILE_PATH) \
		--output-dir /app/output

debug: build ## Start a debug shell in the artifact container
	docker run -it --rm \
		-v $(PWD)/generated_code:/app/output \
		--entrypoint /bin/sh \
		$(IMAGE_NAME)

# --- SonarQube ---
sonar-start: ## Start a local SonarQube instance
	docker run -d --name sonarqube -p 9000:9000 sonarqube
	@echo "SonarQube starting at http://localhost:9000 (admin/admin)"
	@echo "Generate an API token in the UI, then run: make sonar-scan SONAR_TOKEN=<token>"

sonar-logs: ## Tail SonarQube startup logs
	docker logs -f sonarqube

sonar-scan: ## Run SonarQube scan (set SONAR_TOKEN=<token>)
	# run make test first
	$(MAKE) test
	docker run -it --rm \
		-e SONAR_HOST_URL="http://host.docker.internal:9000" \
		-e SONAR_TOKEN="$(SONAR_TOKEN)" \
		-v $(PWD):/usr/src \
		sonarsource/sonar-scanner-cli

# --- Trivy ---
trivy-scan: build ## Run Trivy CVE scan (table output)
	docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD):/output \
		aquasec/trivy:0.69.3 image \
		--format table \
		--output /output/trivy-report.txt \
		--scanners vuln \
		$(IMAGE_NAME):latest

trivy-scan-json: build ## Run Trivy CVE scan (JSON output)
	docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD):/output \
		aquasec/trivy:0.69.3 image \
		--format json \
		--output /output/trivy-report.json \
		--scanners vuln \
		$(IMAGE_NAME):latest

# --- Linting ---
lint-dockerfile: ## Lint Dockerfile with hadolint
	./.agents/skills/dockerfile-best-practices/scripts/lint-dockerfile.sh Dockerfile

lint-python: ## Lint Python files with ruff
	./.agents/skills/python-best-practices/scripts/lint-python.sh .

# --- Cleanup ---
clean: ## Remove generated artifacts and scan reports
	rm -rf generated_code/
	rm -f coverage.xml trivy-report.txt trivy-report.json
	-docker rm -f sonarqube 2>/dev/null

# --- Help ---
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
