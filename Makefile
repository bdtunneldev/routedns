# ============================================================================
# RouteDNS Stack - Professional Makefile
# ============================================================================
# Usage: make [target]
# Run 'make help' for available commands
# ============================================================================

.PHONY: help build up down restart logs status health test clean prune \
        lint security backup restore shell-haproxy shell-valkey shell-grafana \
        cert-check cert-renew release dev prod

# Colors for output
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;34m
PURPLE := \033[0;35m
CYAN   := \033[0;36m
NC     := \033[0m # No Color

# Default environment
ENV ?= dev
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMPOSE_FILE := docker-compose.yml

# ============================================================================
# HELP
# ============================================================================
help: ## Show this help message
	@echo ""
	@echo "$(CYAN)╔═══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║         RouteDNS Stack - Management Commands                  ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make up              # Start all services"
	@echo "  make logs            # View logs"
	@echo "  make health          # Run health checks"
	@echo "  make test            # Run full test suite"
	@echo ""

# ============================================================================
# BUILD & RUN
# ============================================================================
build: ## Build all Docker images
	@echo "$(BLUE)🔨 Building Docker images...$(NC)"
	docker compose build --no-cache
	@echo "$(GREEN)✅ Build complete$(NC)"

build-cache: ## Build with cache
	@echo "$(BLUE)🔨 Building Docker images (with cache)...$(NC)"
	docker compose build
	@echo "$(GREEN)✅ Build complete$(NC)"

up: ## Start all services
	@echo "$(BLUE)🚀 Starting RouteDNS stack...$(NC)"
	docker compose up -d
	@echo "$(GREEN)✅ Stack started$(NC)"
	@$(MAKE) --no-print-directory status

up-logs: ## Start all services with logs
	@echo "$(BLUE)🚀 Starting RouteDNS stack with logs...$(NC)"
	docker compose up

down: ## Stop all services
	@echo "$(YELLOW)🛑 Stopping RouteDNS stack...$(NC)"
	docker compose down
	@echo "$(GREEN)✅ Stack stopped$(NC)"

restart: ## Restart all services
	@echo "$(YELLOW)🔄 Restarting RouteDNS stack...$(NC)"
	docker compose restart
	@echo "$(GREEN)✅ Stack restarted$(NC)"

pull: ## Pull latest images
	@echo "$(BLUE)📥 Pulling latest images...$(NC)"
	docker compose pull
	@echo "$(GREEN)✅ Images updated$(NC)"

# ============================================================================
# MONITORING & LOGS
# ============================================================================
logs: ## View all logs (follow mode)
	docker compose logs -f

logs-haproxy: ## View HAProxy logs
	docker compose logs -f haproxy

logs-routedns: ## View RouteDNS logs
	docker compose logs -f routedns

logs-valkey: ## View Valkey logs
	docker compose logs -f valkey

logs-prometheus: ## View Prometheus logs
	docker compose logs -f prometheus

logs-grafana: ## View Grafana logs
	docker compose logs -f grafana

status: ## Show service status
	@echo ""
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)              SERVICE STATUS$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
	@echo ""

stats: ## Show resource usage
	@echo ""
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)              RESOURCE USAGE$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
	@echo ""

# ============================================================================
# HEALTH CHECKS
# ============================================================================
health: ## Run comprehensive health checks
	@echo ""
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)           HEALTH CHECK REPORT$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(BLUE)Containers:$(NC)"
	@docker compose ps -q | while read id; do \
		name=$$(docker inspect --format '{{.Name}}' $$id | sed 's/\///'); \
		status=$$(docker inspect --format '{{.State.Health.Status}}' $$id 2>/dev/null || echo "no-healthcheck"); \
		if [ "$$status" = "healthy" ]; then \
			echo "  $(GREEN)✅ $$name: $$status$(NC)"; \
		elif [ "$$status" = "no-healthcheck" ]; then \
			running=$$(docker inspect --format '{{.State.Running}}' $$id); \
			if [ "$$running" = "true" ]; then \
				echo "  $(YELLOW)⚡ $$name: running (no healthcheck)$(NC)"; \
			else \
				echo "  $(RED)❌ $$name: not running$(NC)"; \
			fi; \
		else \
			echo "  $(RED)❌ $$name: $$status$(NC)"; \
		fi; \
	done
	@echo ""
	@echo "$(BLUE)Endpoints:$(NC)"
	@curl -sf http://localhost:9090/-/healthy > /dev/null 2>&1 && \
		echo "  $(GREEN)✅ Prometheus: http://localhost:9090$(NC)" || \
		echo "  $(RED)❌ Prometheus: http://localhost:9090$(NC)"
	@curl -sf http://localhost:3000/api/health > /dev/null 2>&1 && \
		echo "  $(GREEN)✅ Grafana: http://localhost:3000$(NC)" || \
		echo "  $(RED)❌ Grafana: http://localhost:3000$(NC)"
	@nc -z localhost 853 2>/dev/null && \
		echo "  $(GREEN)✅ DoT (853): listening$(NC)" || \
		echo "  $(RED)❌ DoT (853): not listening$(NC)"
	@nc -z localhost 8404 2>/dev/null && \
		echo "  $(GREEN)✅ HAProxy Stats (8404): listening$(NC)" || \
		echo "  $(RED)❌ HAProxy Stats (8404): not listening$(NC)"
	@echo ""

# ============================================================================
# TESTING
# ============================================================================
test: ## Run full test suite
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)              RUNNING TEST SUITE$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@$(MAKE) --no-print-directory lint
	@$(MAKE) --no-print-directory health
	@$(MAKE) --no-print-directory test-dns
	@echo ""
	@echo "$(GREEN)✅ All tests passed$(NC)"

test-dns: ## Test DNS resolution
	@echo ""
	@echo "$(BLUE)Testing DNS-over-TLS...$(NC)"
	@if command -v kdig > /dev/null 2>&1; then \
		kdig +tls +tls-ca= @127.0.0.1 -p 853 google.com A 2>/dev/null && \
			echo "$(GREEN)✅ DoT query successful$(NC)" || \
			echo "$(YELLOW)⚠️  DoT query failed (check certs)$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  kdig not installed, skipping DoT test$(NC)"; \
	fi

lint: ## Lint all configuration files
	@echo ""
	@echo "$(BLUE)🔍 Linting configuration files...$(NC)"
	@docker compose config --quiet && \
		echo "  $(GREEN)✅ docker-compose.yml$(NC)" || \
		echo "  $(RED)❌ docker-compose.yml$(NC)"
	@python3 -c "import toml; toml.load('routedns/config.toml')" 2>/dev/null && \
		echo "  $(GREEN)✅ routedns/config.toml$(NC)" || \
		echo "  $(YELLOW)⚠️  routedns/config.toml (install: pip install toml)$(NC)"
	@echo ""

security: ## Run security scan
	@echo "$(BLUE)🔒 Running security scan...$(NC)"
	@if command -v trivy > /dev/null 2>&1; then \
		trivy config . --severity HIGH,CRITICAL; \
	else \
		echo "$(YELLOW)⚠️  Trivy not installed. Install: brew install trivy$(NC)"; \
	fi

# ============================================================================
# SHELL ACCESS
# ============================================================================
shell-haproxy: ## Open shell in HAProxy container
	docker compose exec haproxy /bin/sh

shell-valkey: ## Open Valkey CLI
	docker compose exec valkey valkey-cli

shell-grafana: ## Open shell in Grafana container
	docker compose exec grafana /bin/sh

shell-prometheus: ## Open shell in Prometheus container
	docker compose exec prometheus /bin/sh

# ============================================================================
# BACKUP & RESTORE
# ============================================================================
backup: ## Create backup of all data
	@echo "$(BLUE)📦 Creating backup...$(NC)"
	@./backup.sh
	@echo "$(GREEN)✅ Backup complete$(NC)"

restore: ## Restore from backup (BACKUP_FILE=path required)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)❌ Error: BACKUP_FILE not specified$(NC)"; \
		echo "Usage: make restore BACKUP_FILE=./backups/backup-2026-01-18.tar.gz"; \
		exit 1; \
	fi
	@echo "$(YELLOW)⚠️  Restoring from $(BACKUP_FILE)...$(NC)"
	@echo "This will overwrite current data. Press Ctrl+C to cancel."
	@sleep 3
	@tar -xzf $(BACKUP_FILE) -C ./
	@echo "$(GREEN)✅ Restore complete$(NC)"

# ============================================================================
# CERTIFICATES
# ============================================================================
cert-check: ## Check TLS certificate status
	@echo "$(BLUE)🔐 Checking certificates...$(NC)"
	@if [ -f haproxy/certs/dot.pem ]; then \
		openssl x509 -in haproxy/certs/dot.pem -noout -dates -subject 2>/dev/null || \
			echo "$(RED)❌ Invalid certificate$(NC)"; \
	else \
		echo "$(RED)❌ Certificate not found: haproxy/certs/dot.pem$(NC)"; \
	fi

cert-generate-test: ## Generate self-signed test certificate
	@echo "$(BLUE)🔐 Generating test certificate...$(NC)"
	@mkdir -p haproxy/certs
	@openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes \
		-subj "/CN=test.dns.routedns.io"
	@cat cert.pem key.pem > haproxy/certs/dot.pem
	@rm -f key.pem cert.pem
	@chmod 600 haproxy/certs/dot.pem
	@echo "$(GREEN)✅ Test certificate generated$(NC)"

# ============================================================================
# CLEANUP
# ============================================================================
clean: ## Stop services and remove containers
	@echo "$(YELLOW)🧹 Cleaning up...$(NC)"
	docker compose down --remove-orphans
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

clean-volumes: ## Remove all volumes (⚠️  DATA LOSS)
	@echo "$(RED)⚠️  This will delete all data!$(NC)"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	docker compose down -v --remove-orphans
	@echo "$(GREEN)✅ Volumes removed$(NC)"

prune: ## Full Docker cleanup (⚠️  affects all Docker resources)
	@echo "$(RED)⚠️  This will prune all unused Docker resources!$(NC)"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	docker system prune -af
	docker volume prune -f
	@echo "$(GREEN)✅ Docker pruned$(NC)"

# ============================================================================
# RELEASE
# ============================================================================
release: ## Create a new release (VERSION=x.x.x required)
	@if [ -z "$(VERSION)" ] || [ "$(VERSION)" = "dev" ]; then \
		echo "$(RED)❌ Error: VERSION not specified$(NC)"; \
		echo "Usage: make release VERSION=1.0.0"; \
		exit 1; \
	fi
	@echo "$(BLUE)📦 Creating release v$(VERSION)...$(NC)"
	git tag -a "v$(VERSION)" -m "Release v$(VERSION)"
	git push origin "v$(VERSION)"
	@echo "$(GREEN)✅ Release v$(VERSION) created and pushed$(NC)"

# ============================================================================
# DEVELOPMENT
# ============================================================================
dev: ## Start in development mode (with logs)
	@$(MAKE) --no-print-directory build-cache
	@$(MAKE) --no-print-directory up-logs

prod: ## Start in production mode
	@$(MAKE) --no-print-directory pull
	@$(MAKE) --no-print-directory up
	@$(MAKE) --no-print-directory health

init: ## Initialize project (first-time setup)
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)         INITIALIZING ROUTEDNS PROJECT$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo ""
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)✅ Created .env from .env.example$(NC)"; \
		echo "$(YELLOW)⚠️  Please edit .env with your passwords$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  .env already exists$(NC)"; \
	fi
	@mkdir -p haproxy/certs
	@if [ ! -f haproxy/certs/dot.pem ]; then \
		$(MAKE) --no-print-directory cert-generate-test; \
	else \
		echo "$(YELLOW)⚠️  Certificate already exists$(NC)"; \
	fi
	@echo ""
	@echo "$(GREEN)✅ Initialization complete!$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Edit .env with secure passwords"
	@echo "  2. Replace test cert with real certificate"
	@echo "  3. Run: make up"
	@echo ""
