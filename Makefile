# ─────────────────────────────────────────────
#  nanobot-webui  Makefile
# ─────────────────────────────────────────────
IMAGE   ?= kangkang223/nanobot-webui
TAG     ?= latest
PLATFORMS ?= linux/amd64,linux/arm64

# ── Local dev ─────────────────────────────────
.PHONY: dev
dev:
	cd web && bun run dev

.PHONY: build-web
build-web:
	cd web && bun install --frozen-lockfile && bun run build

# ── Docker (single-platform, local) ───────────
.PHONY: build
build:
	docker build -t $(IMAGE):$(TAG) .

.PHONY: up
up:
	docker compose up -d

.PHONY: down
down:
	docker compose down

.PHONY: logs
logs:
	docker compose logs -f

.PHONY: restart
restart:
	docker compose restart

# ── Docker multi-platform → docker.io ─────────
# Requires: docker buildx with a multi-arch builder
#   Run once to create it:
#     docker buildx create --name multi --use --bootstrap
.PHONY: push
push:
	docker buildx build \
		--platform $(PLATFORMS) \
		--tag $(IMAGE):$(TAG) \
		--push \
		.

.PHONY: push-latest
push-latest: TAG=latest
push-latest: push

# Build & push with an explicit version tag AND update latest
.PHONY: release
release:
	docker buildx build \
		--platform $(PLATFORMS) \
		--tag $(IMAGE):$(TAG) \
		--tag $(IMAGE):latest \
		--push \
		.

# Build & push with a date-based tag (e.g. 2026-03-11) AND update latest
.PHONY: release-dated
release-dated:
	$(eval DATE := $(shell date +%Y-%m-%d))
	docker buildx build \
		--platform $(PLATFORMS) \
		--tag $(IMAGE):$(DATE) \
		--tag $(IMAGE):latest \
		--push \
		.

# ── Python PyPI publish ───────────────────────
.PHONY: build-py
build-py:
	rm -rf dist/ build/ nanobot_webui.egg-info/
	python -m build

.PHONY: publish
publish: build-py
	twine upload dist/*

.PHONY: publish-test
publish-test: build-py
	twine upload --repository testpypi dist/*

# ── Helpers ───────────────────────────────────
.PHONY: help
help:
	@echo ""
	@echo "  make dev            Start Vite dev server (web/)"
	@echo "  make build-web      Build frontend with Bun"
	@echo ""
	@echo "  make build          Build local Docker image ($(IMAGE):$(TAG))"
	@echo "  make up             docker compose up -d"
	@echo "  make down           docker compose down"
	@echo "  make logs           Follow compose logs"
	@echo "  make restart        docker compose restart"
	@echo ""
	@echo "  make push           Build & push multi-arch image ($(PLATFORMS))"
	@echo "  make release TAG=x  Build & push :x and :latest"
	@echo "  make release-dated  Build & push :YYYY-MM-DD and :latest"
	@echo ""
	@echo "  Override defaults:"
	@echo "    IMAGE=$(IMAGE)  TAG=$(TAG)"
	@echo ""
