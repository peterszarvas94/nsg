#!/bin/bash

# Config module for nginx static site configuration generator
# Handles nginx configuration template generation

generate_conf() {
    local domain=$1
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
    
    if [ "$WWW_REDIRECT" = true ]; then
        # Template 1: HTTPS with www → non-www redirect
        log_info "Using template: HTTPS with www redirect"
        cat > "$config_file" << EOF
server {
    listen 80;
    server_name ${domain} www.${domain};
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
    location / { return 301 https://${domain}\$request_uri; }
}

server {
    listen 443 ssl;
    server_name www.${domain};
    ssl_certificate ${ssl_path}/fullchain.pem;
    ssl_certificate_key ${ssl_path}/privkey.pem;
    return 301 https://${domain}\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${domain};
    ssl_certificate ${ssl_path}/fullchain.pem;
    ssl_certificate_key ${ssl_path}/privkey.pem;
    root ${webroot};
    index index.html;
    location / { try_files \$uri \$uri/ \$uri/index.html =404; }
}
EOF
    else
        # Template 2: HTTPS only (no www redirect)
        log_info "Using template: HTTPS only"
        cat > "$config_file" << EOF
server {
    listen 80;
    server_name ${domain};
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
    location / { return 301 https://${domain}\$request_uri; }
}

server {
    listen 443 ssl;
    server_name ${domain};
    ssl_certificate ${ssl_path}/fullchain.pem;
    ssl_certificate_key ${ssl_path}/privkey.pem;
    root ${webroot};
    index index.html;
    location / { try_files \$uri \$uri/ \$uri/index.html =404; }
}
EOF
    fi
    
    # Verify config file was created successfully
    if [ ! -f "$config_file" ]; then
        log_error "Failed to generate config file ${config_file}"
        exit 1
    fi
    
    log_info "Generated config ${config_file}"
}