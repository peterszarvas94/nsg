#!/bin/bash

# Config module for nginx static site configuration generator
# Handles nginx configuration template generation

get_template() {
    local template_name=$1
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local template_dir="$script_dir/../templates"
    local template_path="$template_dir/${template_name}"
    
    if [ ! -f "$template_path" ]; then
        log_error "Template not found: $template_path"
        exit 1
    fi
    
    echo "$template_path"
}

generate_http_only_conf() {
    local domain=$1
    local config_file="${domain}.conf"
    
    log_info "Generating temporary HTTP-only config for SSL certificate generation"
    
    # Create webroot directory for certbot
    sudo mkdir -p /var/www/certbot
    sudo chown -R www-data:www-data /var/www/certbot
    sudo chmod -R 755 /var/www/certbot
    
    # Set environment variable for envsubst
    export DOMAIN="$domain"
    
    # Generate config using envsubst
    if [ "$WWW_REDIRECT" = true ]; then
        # HTTP-only config with www support for certificate generation
        log_info "Using template: HTTP-only with www support"
        local template_path=$(get_template "nginx-www-http.conf.template")
        envsubst '$DOMAIN' < "$template_path" > "$config_file"
    else
        # HTTP-only config without www support
        log_info "Using template: HTTP-only without www"
        local template_path=$(get_template "nginx-no-www-http.conf.template")
        envsubst '$DOMAIN' < "$template_path" > "$config_file"
    fi
    
    # Verify config file was created successfully
    if [ ! -f "$config_file" ]; then
        log_error "Failed to generate HTTP-only config file ${config_file}"
        exit 1
    fi
    
    log_info "Generated temporary HTTP-only config ${config_file}"
}

generate_conf() {
    local domain=$1
    local pocketbase_enabled=${2:-false}
    local webroot="/var/www/$domain"
    local config_file="${domain}.conf"
    local ssl_path=""
    
    log_info "Generating HTTPS config for $domain"
    
    # Find the correct SSL certificate path (prefer clean domain name, fallback to suffixed)
    for path in "/etc/letsencrypt/live/${domain}" "/etc/letsencrypt/live/${domain}-"*; do
        if [ -f "$path/fullchain.pem" ] && [ -f "$path/privkey.pem" ]; then
            ssl_path="$path"
            break
        fi
    done
    
    if [ -z "$ssl_path" ]; then
        log_error "SSL certificates not found for $domain"
        log_error "Checked paths:"
        log_error "  /etc/letsencrypt/live/${domain}/"
        log_error "  /etc/letsencrypt/live/${domain}-*/"
        log_error "Run: $0 --ssl --domain=$domain first"
        exit 1
    fi
    
    log_info "SSL certificates found at: $ssl_path"
    
    # Set environment variables for envsubst
    export DOMAIN="$domain"
    export WEBROOT="$webroot"
    export SSL_PATH="$ssl_path"
    
    # PocketBase locations
    if [ "$pocketbase_enabled" = true ]; then
        # Load PocketBase locations from template
        local template_path=$(get_template "pocketbase-locations.conf.template")
        export POCKETBASE_LOCATIONS=$(cat "$template_path")
        log_info "PocketBase proxy enabled for /api/ and /_/ endpoints"
    else
        export POCKETBASE_LOCATIONS=""
    fi
    
    # Generate config using envsubst
    if [ "$WWW_REDIRECT" = true ]; then
        # Template 1: HTTPS with www → non-www redirect
        log_info "Using template: HTTPS with www redirect"
        local template_path=$(get_template "nginx-www-https.conf.template")
        envsubst '$DOMAIN,$WEBROOT,$SSL_PATH,$POCKETBASE_LOCATIONS' < "$template_path" > "$config_file"
    else
        # Template 2: HTTPS only (no www redirect)
        log_info "Using template: HTTPS without www"
        local template_path=$(get_template "nginx-no-www-https.conf.template")
        envsubst '$DOMAIN,$WEBROOT,$SSL_PATH,$POCKETBASE_LOCATIONS' < "$template_path" > "$config_file"
    fi
    
    # Verify config file was created successfully
    if [ ! -f "$config_file" ]; then
        log_error "Failed to generate config file ${config_file}"
        exit 1
    fi
    
    log_info "Generated config ${config_file}"
}