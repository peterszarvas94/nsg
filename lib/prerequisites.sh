#!/bin/bash

# Prerequisites module for nginx static site configuration generator
# Handles system checks and dependency installation

check_prerequisites() {
    log_info "Checking system prerequisites..."
    
    # Check if running with sudo or as root
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        log_error "This script requires root privileges for nginx configuration."
        log_error "Please run with: sudo $0 [your-arguments-here]"
        exit 1
    fi
    
    # Install nginx if not present
    if ! command -v nginx &> /dev/null; then
        log_info "Nginx not found, installing..."
        sudo apt update && sudo apt install -y nginx
        if [ $? -eq 0 ]; then
            log_info "Nginx installed successfully"
        else
            log_error "Failed to install nginx"
            exit 1
        fi
    else
        log_info "Nginx found"
    fi
    
    # Ensure nginx directories exist
    sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    
    # Check if nginx is enabled to start on boot
    if ! systemctl is-enabled nginx &> /dev/null; then
        log_info "Enabling nginx to start on boot"
        sudo systemctl enable nginx
    fi
    
    # Check firewall status (informational only)
    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        if ! ufw status | grep -q "80\|443"; then
            log_warn "UFW firewall is active but ports 80/443 may not be open"
            log_warn "Run: sudo ufw allow 'Nginx Full'"
        fi
    fi
    
    log_info "Prerequisites checked (ignoring any existing nginx config issues)"
}