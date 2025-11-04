#!/bin/bash

# Utils module for nginx static site configuration generator
# Utility functions for input validation and processing

get_domain_input() {
    read -p "Domain name: " domain_input
    
    # Remove http:// or https:// if present
    domain_input=$(echo "$domain_input" | sed 's|https\?://||')
    # Remove trailing slash if present
    domain_input=$(echo "$domain_input" | sed 's|/$||')
    # Remove www. if present (we'll handle www separately)
    domain_input=$(echo "$domain_input" | sed 's|^www\.||')
    
    if [ -z "$domain_input" ]; then
        log_error "Domain cannot be empty"
        exit 1
    fi
    
    echo "$domain_input"
}