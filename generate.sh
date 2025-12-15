#!/bin/bash

# Nginx Static Site Configuration Generator
# Generates nginx configs with HTTP->HTTPS and www->non-www redirects
# Usage: ./generate.sh --flag domain.com

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library modules
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/prerequisites.sh"
source "$SCRIPT_DIR/lib/ssl.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/nginx.sh"
source "$SCRIPT_DIR/lib/health.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"

show_help() {
    local help_template=$(get_template "help.txt.template")
    cat "$help_template" | envsubst '$0'
    exit 0
}

# Parse arguments
COMMAND=""
DOMAIN=""
WWW_REDIRECT=false
PB_PORT=8090

# Check if no arguments or help requested
if [ $# -eq 0 ] || [ "$1" = "--help" ]; then
    show_help
fi

# First argument should be the command
COMMAND="$1"
shift

# Parse remaining arguments
while [ $# -gt 0 ]; do
    case $1 in
        --domain=*)
            DOMAIN="${1#*=}"
            ;;
--www)
            WWW_REDIRECT=true
            ;;
        --port=*)
            PB_PORT="${1#*=}"
            ;;
        --help)
            show_help
            ;;
        
        --help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            ;;
    esac
    shift
done

# Ensure we have a valid command
case $COMMAND in
    setup|pb|check|remove)
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        ;;
esac

# Get domain if not provided
if [ -z "$DOMAIN" ]; then
    DOMAIN=$(get_domain_input)
fi

log_info "Processing domain: $DOMAIN"

case $COMMAND in
    setup)
        check_prerequisites
        setup_ssl "$DOMAIN"
        generate_conf "$DOMAIN"
        copy_config "$DOMAIN"
        enable_site "$DOMAIN"
        
        log_info "HTTPS site setup complete for $DOMAIN!"
        log_info "Copy your files to: /var/www/$DOMAIN/"
        
        if [ "$WWW_REDIRECT" = true ]; then
            log_info "WWW redirect enabled: www.$DOMAIN → $DOMAIN"
        fi
        
        log_info "Visit: https://$DOMAIN"
        ;;
    pb)
        check_prerequisites
        setup_ssl "$DOMAIN"
        generate_pocketbase_conf "$DOMAIN" "$PB_PORT"
        copy_config "$DOMAIN"
        enable_site "$DOMAIN"
        log_info "PocketBase setup complete for $DOMAIN!"
        log_info "PocketBase accessible at: https://$DOMAIN"
        log_info "Make sure PocketBase is running on localhost:$PB_PORT"
        log_info "Set Application URL in PocketBase to: https://$DOMAIN"
        ;;
    check)
        check_site "$DOMAIN"
        ;;
    remove)
        remove_site "$DOMAIN"
        ;;
esac