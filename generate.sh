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
POCKETBASE_ENABLED=false

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
        --pb)
            POCKETBASE_ENABLED=true
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
        generate_conf "$DOMAIN" "$POCKETBASE_ENABLED"
        copy_config "$DOMAIN"
        enable_site "$DOMAIN"
        
        if [ "$POCKETBASE_ENABLED" = true ]; then
            log_info "HTTPS site with PocketBase setup complete for $DOMAIN!"
            log_info "Copy your files to: /var/www/$DOMAIN/"
            log_info "PocketBase API available at: https://$DOMAIN/api"
            log_info "PocketBase Admin available at: https://$DOMAIN/_"
        else
            log_info "HTTPS site setup complete for $DOMAIN!"
            log_info "Copy your files to: /var/www/$DOMAIN/"
        fi
        
        if [ "$WWW_REDIRECT" = true ]; then
            log_info "WWW redirect enabled: www.$DOMAIN → $DOMAIN"
        fi
        
        log_info "Visit: https://$DOMAIN"
        ;;
    pb)
        generate_conf "$DOMAIN" true
        copy_config "$DOMAIN"
        enable_site "$DOMAIN"
        log_info "PocketBase proxy added to $DOMAIN!"
        log_info "PocketBase API available at: https://$DOMAIN/api"
        log_info "PocketBase Admin available at: https://$DOMAIN/_"
        ;;
    check)
        check_site "$DOMAIN"
        ;;
    remove)
        remove_site "$DOMAIN"
        ;;
esac