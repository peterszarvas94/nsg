#!/bin/bash

# SSL module for nginx static site configuration generator
# Handles SSL certificate generation and management

setup_ssl() {
    local domain=$1
    
    log_info "Setting up SSL certificate for $domain using webroot method"
    
    # Install certbot if not installed
    if ! command -v certbot &> /dev/null; then
        log_info "Installing certbot..."
        sudo apt update && sudo apt install -y certbot
        if [ $? -ne 0 ]; then
            log_error "Failed to install certbot"
            exit 1
        fi
    fi
    
    # Ensure webroot directory exists with proper permissions
    sudo mkdir -p /var/www/certbot
    sudo chown -R www-data:www-data /var/www/certbot
    sudo chmod -R 755 /var/www/certbot
    
    # Stage 1: Generate HTTP-only nginx config for certificate validation
    log_info "Stage 1: Creating temporary HTTP-only configuration"
    generate_http_only_conf "$domain"
    
    # Copy the HTTP-only config to nginx and enable it
    sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    local config_file="${domain}.conf"
    
    if sudo cp "$config_file" /etc/nginx/sites-available/; then
        log_info "Copied HTTP-only config to nginx sites-available"
    else
        log_error "Failed to copy HTTP-only config to nginx sites-available"
        exit 1
    fi
    
    # Remove any existing symlink and create new one
    sudo rm -f "/etc/nginx/sites-enabled/$config_file"
    sudo ln -s "/etc/nginx/sites-available/$config_file" /etc/nginx/sites-enabled/
    
    # Test nginx config and restart
    if sudo nginx -t &> /dev/null; then
        log_info "HTTP-only configuration is valid"
        sudo systemctl reload nginx
    else
        log_error "HTTP-only configuration has errors:"
        sudo nginx -t
        exit 1
    fi
    
    # Stage 2: Get certificate using webroot method (nginx stays running)
    log_info "Stage 2: Getting SSL certificate using webroot method"
    
    if [ "$WWW_REDIRECT" = true ]; then
        log_info "Getting SSL certificate for $domain and www.$domain"
        sudo certbot certonly --webroot -w /var/www/certbot --cert-name "$domain" -d "$domain" -d "www.$domain" --expand --non-interactive --agree-tos --email admin@"$domain"
    else
        log_info "Getting SSL certificate for $domain only"
        sudo certbot certonly --webroot -w /var/www/certbot --cert-name "$domain" -d "$domain" --expand --non-interactive --agree-tos --email admin@"$domain"
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Failed to get SSL certificate for $domain"
        log_error "Check that domain points to this server and ports 80/443 are open"
        exit 1
    fi
    
    log_info "SSL certificate obtained for $domain"
    
    # Setup auto-renewal cron job
    if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
        log_info "Setting up SSL auto-renewal with webroot method"
        (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | sudo crontab -
        log_info "SSL auto-renewal configured"
    fi
    
    log_info "SSL certificate setup complete!"
    log_info "Next: Run --conf to generate HTTPS configuration"
}

