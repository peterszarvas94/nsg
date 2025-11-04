#!/bin/bash

# SSL module for nginx static site configuration generator
# Handles SSL certificate generation and management

setup_ssl() {
    local domain=$1
    
    log_info "Setting up SSL certificate for $domain"
    
    # Install certbot if not installed
    if ! command -v certbot &> /dev/null; then
        log_info "Installing certbot..."
        sudo apt update && sudo apt install -y certbot
        if [ $? -ne 0 ]; then
            log_error "Failed to install certbot"
            exit 1
        fi
    fi
    
    # Stop nginx temporarily for standalone mode
    if systemctl is-active --quiet nginx; then
        log_info "Stopping nginx for SSL certificate generation"
        sudo systemctl stop nginx
    fi
    
    # Get certificate using standalone mode with explicit cert name
    if [ "$WWW_REDIRECT" = true ]; then
        log_info "Getting SSL certificate for $domain and www.$domain"
        sudo certbot certonly --standalone --cert-name "$domain" -d "$domain" -d "www.$domain" --expand --non-interactive --agree-tos --email admin@"$domain"
    else
        log_info "Getting SSL certificate for $domain only"
        sudo certbot certonly --standalone --cert-name "$domain" -d "$domain" --expand --non-interactive --agree-tos --email admin@"$domain"
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Failed to get SSL certificate for $domain"
        log_error "Check that domain points to this server and ports 80/443 are open"
        exit 1
    fi
    
    log_info "SSL certificate obtained for $domain"
    
    # Start nginx back up
    log_info "Starting nginx"
    sudo systemctl start nginx
    
    # Setup auto-renewal cron job
    if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
        log_info "Setting up SSL auto-renewal"
        (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | sudo crontab -
        log_info "SSL auto-renewal configured"
    fi
    
    log_info "SSL certificate setup complete!"
}