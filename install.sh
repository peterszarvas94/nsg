#!/bin/bash

# NSG Installation Script
# Installs nginx site generator as a system-wide command

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/share/nsg"
BIN_DIR="/usr/local/bin"

echo "[INFO] Installing NSG (Nginx Site Generator)"
echo "[INFO] Source: $SCRIPT_DIR"
echo "[INFO] Target: $INSTALL_DIR"
echo ""

# Check for sudo
if [ "$EUID" -ne 0 ]; then 
    echo "[ERROR] Please run with sudo"
    exit 1
fi

# Create installation directory
echo "[INFO] Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy library files
echo "[INFO] Copying library files..."
cp -r "$SCRIPT_DIR/lib" "$INSTALL_DIR/"

# Copy templates
echo "[INFO] Copying templates..."
cp -r "$SCRIPT_DIR/templates" "$INSTALL_DIR/"

# Create wrapper script
echo "[INFO] Creating nsg command..."
cat > "$BIN_DIR/nsg" << 'EOF'
#!/bin/bash

# NSG wrapper script
# This script loads libraries from the installation directory

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library modules from installation directory
source "/usr/local/share/nsg/lib/logger.sh"
source "/usr/local/share/nsg/lib/utils.sh"
source "/usr/local/share/nsg/lib/prerequisites.sh"
source "/usr/local/share/nsg/lib/ssl.sh"
source "/usr/local/share/nsg/lib/config.sh"
source "/usr/local/share/nsg/lib/nginx.sh"
source "/usr/local/share/nsg/lib/health.sh"
source "/usr/local/share/nsg/lib/cleanup.sh"

EOF

# Append the main script (without the source lines)
sed -n '/^show_help()/,$p' "$SCRIPT_DIR/generate.sh" >> "$BIN_DIR/nsg"

# Make executable
chmod +x "$BIN_DIR/nsg"

# Update get_template function to use installation path
sed -i.bak 's|script_dir/../templates|/usr/local/share/nsg/templates|g' "$INSTALL_DIR/lib/config.sh"
rm -f "$INSTALL_DIR/lib/config.sh.bak"

echo ""
echo "[SUCCESS] NSG installed successfully!"
echo ""
echo "Usage:"
echo "  nsg setup --domain=example.com"
echo "  nsg pb --domain=pb.example.com"
echo "  nsg --help"
echo ""
echo "To uninstall:"
echo "  sudo rm -rf $INSTALL_DIR"
echo "  sudo rm $BIN_DIR/nsg"
