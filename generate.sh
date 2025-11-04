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
    echo "Usage: $0 [ACTION] [--domain=example.com]"
    echo "Actions:"
    echo "  --conf,         -c    Generate HTTPS config file (requires SSL certificates)"
    echo "  --copy,         -p    Create directory and copy config to nginx"
    echo "  --enable,       -e    Enable site in nginx"
    echo "  --ssl,          -s    Setup SSL certificate with certbot (webroot method)"
    echo "  --all,          -a    Run all steps (ssl + conf + copy + enable)"
    echo "  --check,        -k    Check domain health (DNS, HTTP, HTTPS, SSL)"
    echo "  --remove,       -r    Remove site completely (webroot + config + SSL cert)"
    echo ""
    echo "  --help,         -h    Show this help"
    echo "Domain Options:"
    echo "  --domain=example.com, -d example.com   Specify domain to work with"
    echo "  --www, -w                              Redirect www to non-www"
    echo "  (if domain not provided for most actions, you will be prompted to enter it)"
    echo "Examples:"
    echo "  $0 --all --domain=example.com         # Setup site (non-www only)"
    echo "  $0 --all --www --domain=example.com   # Setup site (www redirects to non-www)"
    echo "  $0 -a -w -d example.com               # Same as above (short flags)"
    echo "  $0 --check --domain=example.com       # Verify site is working"
    echo ""
    echo "  $0 --all                              # Will prompt for domain"
    echo "Prerequisites:"
    echo "  - Domain must point to this server's IP"
    echo "  - Ports 80 and 443 must be open"
    echo "  - Root/sudo access required"
    echo "SSL Auto-renewal Fix:"
    echo "  The script now uses webroot method instead of standalone to prevent"
    echo "  renewal failures. Remove existing certificates before using new version."
    exit 0
}

# Parse arguments
FLAG=""
DOMAIN=""
WWW_REDIRECT=false

# Check if no arguments or help requested
if [ $# -eq 0 ] || [ "$1" = "--help" ]; then
    show_help
fi

# Parse all arguments
i=0
while [ $i -lt $# ]; do
    i=$((i + 1))
    arg=${!i}
    
    case $arg in
        --domain=*)
            DOMAIN="${arg#*=}"
            ;;
        -d)
            # Next argument should be domain
            i=$((i + 1))
            if [ $i -le $# ]; then
                DOMAIN=${!i}
            else
                log_error "-d flag requires domain argument"
                show_help
            fi
            ;;
        --conf|-c)
            if [ -n "$FLAG" ]; then
                log_error "Multiple action flags not allowed"
                show_help
            fi
            FLAG="--conf"
            ;;
        --copy|-p)
            if [ -n "$FLAG" ]; then
                log_error "Multiple action flags not allowed"
                show_help
            fi
            FLAG="--copy"
            ;;
        --enable|-e)
            if [ -n "$FLAG" ]; then
                log_error "Multiple action flags not allowed"
                show_help
            fi
            FLAG="--enable"
            ;;
        --ssl|-s)
            if [ -n "$FLAG" ]; then
                log_error "Multiple action flags not allowed"
                show_help
            fi
            FLAG="--ssl"
            ;;
        --all|-a)
            if [ -n "$FLAG" ]; then
                log_error "Multiple action flags not allowed"
                show_help
            fi
            FLAG="--all"
            ;;
        --check|-k)
            if [ -n "$FLAG" ]; then
                log_error "Multiple action flags not allowed"
                show_help
            fi
            FLAG="--check"
            ;;
        --remove|-r)
            if [ -n "$FLAG" ]; then
                log_error "Multiple action flags not allowed"
                show_help
            fi
            FLAG="--remove"
            ;;
        --www|-w)
            WWW_REDIRECT=true
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown argument: $arg"
            show_help
            ;;
    esac
done

# Ensure we have an action flag
if [ -z "$FLAG" ]; then
    log_error "Action flag required (--all, --check, etc.)"
    show_help
fi

# Get domain if not provided
if [ -z "$DOMAIN" ]; then
    DOMAIN=$(get_domain_input)
fi

log_info "Processing domain: $DOMAIN"

case $FLAG in
    --conf)
        generate_conf "$DOMAIN"
        ;;
    --copy)
        check_prerequisites
        copy_config "$DOMAIN"
        ;;
    --enable)
        check_prerequisites
        enable_site "$DOMAIN"
        ;;
    --ssl)
        check_prerequisites
        setup_ssl "$DOMAIN"
        ;;
    --all)
        check_prerequisites
        setup_ssl "$DOMAIN"
        generate_conf "$DOMAIN"
        copy_config "$DOMAIN"
        enable_site "$DOMAIN"
        log_info "HTTPS site setup complete for $DOMAIN!"
        log_info "Copy your files to: /var/www/$DOMAIN/"
        log_info "Visit: https://$DOMAIN"
        ;;
    --check)
        check_site "$DOMAIN"
        ;;
    --remove)
        remove_site "$DOMAIN"
        ;;
    *)
        log_error "Unknown flag $FLAG"
        show_help
        ;;
esac