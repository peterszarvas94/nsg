#!/bin/bash

# Logger module for nginx static site configuration generator
# Provides colored logging functions

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]  ${NC}$1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]  ${NC}$1"
}

log_error() {
    echo -e "${RED}[ERROR] ${NC}$1"
}