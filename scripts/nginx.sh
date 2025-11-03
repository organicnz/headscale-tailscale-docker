#!/usr/bin/env bash
# nginx management helper script for Headscale deployment
# Provides convenient commands for common nginx operations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if nginx container is running
check_nginx() {
    if ! docker ps --filter "name=nginx" --filter "status=running" --format "{{.Names}}" | grep -q "nginx"; then
        error "nginx container is not running"
        exit 1
    fi
}

# Show usage
usage() {
    cat << EOF
nginx Management Script for Headscale

Usage: $0 <command> [options]

Commands:
  status              Show nginx container status
  logs [lines]        Show nginx logs (default: 50 lines, use 'all' for everything)
  test                Test nginx configuration syntax
  reload              Reload nginx configuration without downtime
  restart             Restart nginx container
  stats               Show nginx connection statistics
  access-log [lines]  Show access log (default: 50 lines)
  error-log [lines]   Show error log (default: 50 lines)
  health              Check health endpoint
  ssl-info            Show SSL certificate information (production only)
  ssl-test            Test SSL configuration (requires openssl)
  connections         Show active connections to nginx
  top                 Show real-time resource usage
  exec <command>      Execute arbitrary command in nginx container

Examples:
  $0 status           # Show container status
  $0 logs 100         # Show last 100 log lines
  $0 test             # Test configuration
  $0 reload           # Reload configuration
  $0 health           # Test health endpoint

EOF
    exit 0
}

# Show nginx status
show_status() {
    info "nginx container status:"
    docker ps --filter "name=nginx" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Show logs
show_logs() {
    local lines="${1:-50}"
    check_nginx

    if [[ "$lines" == "all" ]]; then
        info "Showing all nginx logs (follow mode - Ctrl+C to exit):"
        docker logs -f nginx
    else
        info "Showing last $lines lines of nginx logs:"
        docker logs --tail "$lines" nginx
    fi
}

# Test nginx configuration
test_config() {
    check_nginx
    info "Testing nginx configuration..."
    docker exec nginx nginx -t

    if [[ $? -eq 0 ]]; then
        info "Configuration test passed!"
    else
        error "Configuration test failed!"
        exit 1
    fi
}

# Reload nginx configuration
reload_nginx() {
    check_nginx
    info "Reloading nginx configuration..."
    docker exec nginx nginx -s reload

    if [[ $? -eq 0 ]]; then
        info "nginx configuration reloaded successfully!"
    else
        error "Failed to reload nginx configuration"
        exit 1
    fi
}

# Restart nginx container
restart_nginx() {
    info "Restarting nginx container..."
    docker compose restart nginx

    if [[ $? -eq 0 ]]; then
        info "nginx container restarted successfully!"
    else
        error "Failed to restart nginx container"
        exit 1
    fi
}

# Show nginx statistics
show_stats() {
    check_nginx
    info "nginx container statistics:"
    docker stats nginx --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Show access log
show_access_log() {
    local lines="${1:-50}"
    check_nginx
    info "Showing last $lines lines of access log:"
    docker exec nginx tail -n "$lines" /var/log/nginx/access.log
}

# Show error log
show_error_log() {
    local lines="${1:-50}"
    check_nginx
    info "Showing last $lines lines of error log:"
    docker exec nginx tail -n "$lines" /var/log/nginx/error.log
}

# Check health endpoint
check_health() {
    info "Checking health endpoint..."

    # Try localhost first (development mode)
    if curl -s -f -o /dev/null -w "%{http_code}" http://localhost:8000/health > /dev/null 2>&1; then
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
        if [[ "$status_code" == "200" ]]; then
            info "Health check passed! (HTTP $status_code)"
        else
            warn "Health check returned HTTP $status_code"
        fi
    else
        warn "Could not reach health endpoint on http://localhost:8000/health"
        info "This might be expected if you're running in production mode"
    fi
}

# Show SSL certificate information
show_ssl_info() {
    check_nginx
    info "SSL certificate information:"

    # Check if certificate exists
    if docker exec nginx test -f /etc/letsencrypt/live/*/fullchain.pem 2>/dev/null; then
        docker exec nginx sh -c "openssl x509 -in /etc/letsencrypt/live/*/fullchain.pem -text -noout | grep -A 2 'Validity'"
        docker exec nginx sh -c "openssl x509 -in /etc/letsencrypt/live/*/fullchain.pem -noout -subject -issuer"
    else
        warn "No SSL certificate found (development mode or certificates not yet configured)"
    fi
}

# Test SSL configuration
test_ssl() {
    local domain="${1:-localhost}"
    info "Testing SSL configuration for $domain..."

    if command -v openssl &> /dev/null; then
        echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | openssl x509 -noout -text
    else
        error "openssl command not found. Please install openssl."
        exit 1
    fi
}

# Show active connections
show_connections() {
    check_nginx
    info "Active connections to nginx:"
    docker exec nginx sh -c "netstat -an | grep :8080 | wc -l" || \
    docker exec nginx sh -c "ss -an | grep :8080 | wc -l"
}

# Show real-time resource usage
show_top() {
    check_nginx
    info "Real-time resource usage (Ctrl+C to exit):"
    docker stats nginx
}

# Execute arbitrary command
exec_command() {
    check_nginx
    local cmd="$*"
    info "Executing: $cmd"
    docker exec nginx sh -c "$cmd"
}

# Main command router
main() {
    if [[ $# -eq 0 ]]; then
        usage
    fi

    local command=$1
    shift

    case "$command" in
        status)
            show_status
            ;;
        logs)
            show_logs "$@"
            ;;
        test)
            test_config
            ;;
        reload)
            reload_nginx
            ;;
        restart)
            restart_nginx
            ;;
        stats)
            show_stats
            ;;
        access-log)
            show_access_log "$@"
            ;;
        error-log)
            show_error_log "$@"
            ;;
        health)
            check_health
            ;;
        ssl-info)
            show_ssl_info
            ;;
        ssl-test)
            test_ssl "$@"
            ;;
        connections)
            show_connections
            ;;
        top)
            show_top
            ;;
        exec)
            exec_command "$@"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Unknown command: $command"
            echo ""
            usage
            ;;
    esac
}

main "$@"
