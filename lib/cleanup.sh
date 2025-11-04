#!/bin/bash

# Cleanup module for nginx static site configuration generator
# Handles complete site and certificate removal

remove_site() {
    local domain=$1
    local webroot="/var/www/$domain"
    local config_file="${domain}.conf"
    
    log_warn "REMOVING SITE: $domain"
    log_warn "This will permanently delete:"
    echo "- Website files: $webroot"
    echo "- Nginx config: /etc/nginx/sites-available/$config_file"
    echo "- Nginx symlink: /etc/nginx/sites-enabled/$config_file"
    echo "- SSL certificate: /etc/letsencrypt/live/$domain"
    echo "- Local config: $config_file"
    
    # Confirmation prompt
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Removal cancelled"
        exit 0
    fi
    
    log_info "Removing nginx configuration for $domain..."
    
    # Disable site (remove symlink)
    if [ -L "/etc/nginx/sites-enabled/$config_file" ]; then
        sudo rm "/etc/nginx/sites-enabled/$config_file"
        log_info "Disabled nginx site"
    fi
    
    # Remove config file
    if [ -f "/etc/nginx/sites-available/$config_file" ]; then
        sudo rm "/etc/nginx/sites-available/$config_file"
        log_info "Removed nginx config"
    fi
    
    # Remove local config file
    if [ -f "$config_file" ]; then
        rm "$config_file"
        log_info "Removed local config file"
    fi
    
    # Remove SSL certificate
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
        log_info "Removing SSL certificate for $domain..."
        sudo certbot delete --cert-name "$domain" --non-interactive
        if [ $? -eq 0 ]; then
            log_info "Removed SSL certificate"
        else
            log_warn "Could not remove SSL certificate automatically"
        fi
    fi
    
    # Remove webroot directory
    if [ -d "$webroot" ]; then
        log_info "Removing website files at $webroot..."
        sudo rm -rf "$webroot"
        log_info "Removed website files"
    fi
    
    # Test and reload nginx
    if sudo nginx -t &> /dev/null; then
        sudo systemctl reload nginx
        log_info "Nginx configuration reloaded"
    else
        log_warn "Nginx configuration test failed - manual fix may be needed"
    fi
    
    log_info "Site $domain completely removed!"
}