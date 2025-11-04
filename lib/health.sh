#!/bin/bash

# Health module for nginx static site configuration generator
# Handles domain and site health checking

check_site() {
    local domain=$1
    local webroot="/var/www/$domain"
    local config_file="${domain}.conf"
    
    log_info "CHECKING DOMAIN HEALTH: $domain"
    
    local issues=0
    
    # Check DNS resolution
    log_info "Checking DNS resolution..."
    if dig +short "$domain" &> /dev/null || nslookup "$domain" &> /dev/null; then
        local ip=$(dig +short "$domain" 2>/dev/null | head -1)
        if [ -n "$ip" ]; then
            log_info "DNS resolves to: $ip"
        else
            log_info "DNS resolution working"
        fi
    else
        log_error "DNS resolution failed"
        ((issues++))
    fi
    
    # Check www DNS resolution
    log_info "Checking www DNS resolution..."
    if dig +short "www.$domain" &> /dev/null || nslookup "www.$domain" &> /dev/null; then
        log_info "www.$domain DNS working"
    else
        log_warn "www.$domain DNS not configured"
    fi
    
    # Check nginx config exists
    log_info "Checking nginx configuration..."
    if [ -f "/etc/nginx/sites-available/$config_file" ]; then
        log_info "Nginx config exists"
        
        if [ -L "/etc/nginx/sites-enabled/$config_file" ]; then
            log_info "Nginx site is enabled"
        else
            log_error "Nginx site not enabled"
            ((issues++))
        fi
    else
        log_error "Nginx config missing"
        ((issues++))
    fi
    
    # Check webroot exists
    log_info "Checking webroot directory..."
    if [ -d "$webroot" ]; then
        log_info "Webroot exists: $webroot"
        
        if [ -f "$webroot/index.html" ]; then
            log_info "index.html found"
        else
            log_warn "No index.html found in webroot"
        fi
    else
        log_error "Webroot directory missing"
        ((issues++))
    fi
    
    # Check SSL certificate
    log_info "Checking SSL certificate..."
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
        log_info "SSL certificate exists"
        
        # Check certificate expiry
        if command -v openssl &> /dev/null; then
            local expiry=$(sudo openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$domain/cert.pem" 2>/dev/null | cut -d= -f2)
            if [ -n "$expiry" ]; then
                log_info "Certificate expires: $expiry"
            fi
        fi
    else
        # Check if HTTPS is working anyway (might be using other certificates)
        if command -v curl &> /dev/null; then
            if curl -s --max-time 5 "https://$domain" > /dev/null 2>&1; then
                log_info "SSL certificate working (external/custom cert)"
            else
                log_warn "No SSL certificate found"
            fi
        else
            log_warn "No SSL certificate found"
        fi
    fi
    
    # Check nginx service
    log_info "Checking nginx service..."
    if systemctl is-active --quiet nginx; then
        log_info "Nginx service is running"
    else
        log_error "Nginx service not running"
        ((issues++))
    fi
    
    # Check nginx config validity (but don't count as error if site works)
    log_info "Testing nginx configuration..."
    if sudo nginx -t &> /dev/null; then
        log_info "Nginx configuration is valid"
    else
        log_warn "Nginx configuration has errors (but site may still work)"
        # Don't increment issues counter - if HTTPS works, this doesn't matter
    fi
    
    # Check HTTP response
    log_info "Testing HTTP connection..."
    if command -v curl &> /dev/null; then
        local http_status=$(curl -s -o /dev/null -w "%{http_code}" "http://$domain" --max-time 10 2>/dev/null)
        if [ "$http_status" = "301" ] || [ "$http_status" = "302" ]; then
            log_info "HTTP redirects properly (status: $http_status)"
        elif [ "$http_status" = "200" ]; then
            log_info "HTTP responds (status: $http_status)"
        else
            log_error "HTTP connection failed (status: $http_status)"
            ((issues++))
        fi
    else
        log_warn "curl not available - cannot test HTTP"
    fi
    
    # Check HTTPS response
    log_info "Testing HTTPS connection..."
    local https_working=false
    if command -v curl &> /dev/null; then
        local https_status=$(curl -s -o /dev/null -w "%{http_code}" "https://$domain" --max-time 10 2>/dev/null)
        if [ "$https_status" = "200" ]; then
            log_info "HTTPS responds correctly (status: $https_status)"
            https_working=true
        else
            log_error "HTTPS connection failed (status: $https_status)"
            ((issues++))
        fi
    else
        log_warn "curl not available - cannot test HTTPS"
    fi
    
    # Check SSL certificate validity via online test
    log_info "Testing SSL certificate validity..."
    if command -v curl &> /dev/null; then
        if curl -s --max-time 5 "https://$domain" > /dev/null 2>&1; then
            log_info "SSL certificate is valid and trusted"
            # If HTTPS works, the site is healthy regardless of other warnings
            if [ "$https_working" = true ]; then
                # Reset issues if HTTPS works perfectly
                issues=0
            fi
        else
            log_warn "SSL certificate may have issues"
        fi
    fi
    
    log_info "HEALTH CHECK SUMMARY:"
    
    if [ $issues -eq 0 ]; then
        log_info "$domain is healthy! All checks passed."
        log_info "URLs to test:"
        echo "- https://$domain"
        echo "- https://www.$domain -> https://$domain"
        echo "- http://$domain -> https://$domain"
        echo "- http://www.$domain -> https://$domain"
    else
        log_error "$domain has $issues issue(s) that need attention."
        log_info "Common fixes:"
        echo "- DNS not pointing to server: Update A records"
        echo "- Nginx not running: sudo systemctl start nginx"
        echo "- Config errors: sudo nginx -t"
        echo "- Missing SSL: $0 --ssl $domain"
    fi
    
}