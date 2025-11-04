#!/bin/bash

# Nginx module for nginx static site configuration generator
# Handles nginx site management operations

copy_config() {
    local domain=$1
    local webroot="/var/www/$domain"
    local config_file="${domain}.conf"
    
    log_info "Creating webroot and copying config for $domain"
    
    # Ensure config file exists
    if [ ! -f "$config_file" ]; then
        log_error "Config file $config_file not found. Run --conf first."
        exit 1
    fi
    
    # Create webroot directory
    sudo mkdir -p "$webroot"
    log_info "Created webroot: ${webroot}"
    
    # Ensure nginx directories exist
    sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    
    # Copy to nginx sites directory
    if sudo cp "$config_file" /etc/nginx/sites-available/; then
        log_info "Copied config to nginx sites-available"
    else
        log_error "Failed to copy config to nginx sites-available"
        exit 1
    fi
}

enable_site() {
    local domain=$1
    local config_file="${domain}.conf"
    
    log_info "Enabling site for $domain"
    
    # Check if config exists in sites-available
    if [ ! -f "/etc/nginx/sites-available/$config_file" ]; then
        log_error "Config file not found in /etc/nginx/sites-available/. Run --copy first."
        exit 1
    fi
    
    # Enable site (remove existing symlink first if it exists)
    sudo rm -f "/etc/nginx/sites-enabled/$config_file"
    sudo ln -s "/etc/nginx/sites-available/$config_file" /etc/nginx/sites-enabled/
    log_info "Enabled site in nginx"
    
    # Test only our specific config by temporarily moving others
    log_info "Testing $domain configuration..."
    
    # Backup other enabled sites
    sudo mkdir -p /tmp/nginx-backup
    sudo find /etc/nginx/sites-enabled/ -name "*.conf" ! -name "$config_file" -exec mv {} /tmp/nginx-backup/ \;
    
    # Test with only our config
    if sudo nginx -t &> /dev/null; then
        log_info "$domain configuration is valid"
    else
        log_error "$domain configuration has errors:"
        sudo nginx -t
        # Restore other configs before exiting
        sudo find /tmp/nginx-backup/ -name "*.conf" -exec mv {} /etc/nginx/sites-enabled/ \;
        exit 1
    fi
    
    # Restore other configs
    sudo find /tmp/nginx-backup/ -name "*.conf" -exec mv {} /etc/nginx/sites-enabled/ \;
    sudo rmdir /tmp/nginx-backup 2>/dev/null
    
    # Restart nginx to pick up SSL configurations
    log_info "Restarting nginx to apply SSL configuration"
    sudo systemctl restart nginx
    
    log_info "$domain enabled and configuration validated"
}