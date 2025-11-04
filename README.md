# Nginx Static Site Setup

## Overview

Single script to setup static websites with:
- ✅ **Two-stage SSL deployment** - HTTP first, HTTPS after certificate generation
- ✅ **HTTP → HTTPS redirects** - Automatic HTTPS enforcement
- ✅ **www → non-www redirects** - Canonical domain handling
- ✅ **Auto SSL certificate renewal** - Let's Encrypt with cron
- ✅ **Automated nginx configuration** - Zero-config setup
- ✅ **Fresh Ubuntu compatible** - Auto-installs dependencies

## Quick Start

```bash
# One-liner setup (always gets latest version):
wget -O - "https://raw.githubusercontent.com/peterszarvas94/static-deploy/refs/heads/master/generate-site-config.sh?$(date +%s)" | bash -s -- --all example.com
```

```bash
# Or download and run:
wget "https://raw.githubusercontent.com/peterszarvas94/static-deploy/refs/heads/master/generate-site-config.sh?$(date +%s)" -O generate-site-config.sh
chmod +x generate-site-config.sh
./generate-site-config.sh --all example.com
```

## How It Works

The script uses a **two-stage approach** to avoid SSL certificate chicken-and-egg problems:

1. **Stage 1 - HTTP Setup**: Creates HTTP-only config, enables site
2. **Stage 2 - SSL Setup**: Gets certificates, updates to HTTPS config

## Prerequisites

- Ubuntu/Debian server with root/sudo access
- Domain pointing to your server's IP address
- Ports 80 and 443 open (script will warn about firewall issues)

*Note: The script auto-installs nginx and certbot if missing*

## Manual Setup (Step by Step)

### 1. Download and Run

```bash
# Complete setup (recommended):
./generate-site-config.sh --all example.com

# Or step by step:
./generate-site-config.sh --conf example.com     # Generate HTTP config
./generate-site-config.sh --copy example.com     # Create dir & copy to nginx  
./generate-site-config.sh --enable example.com   # Enable site (HTTP only)
./generate-site-config.sh --ssl example.com      # Get SSL & update to HTTPS
```

### 2. Copy Your Static Files

```bash
# Upload your website files to the webroot (automatically created):
sudo cp -r /path/to/your/site/* /var/www/example.com/

# Or upload via rsync/scp:
rsync -avz /local/site/ user@server:/var/www/example.com/
```

### 3. Multiple Sites

```bash
# Run the script once for each domain:
./generate-site-config.sh --all site1.com
./generate-site-config.sh --all site2.com  
./generate-site-config.sh --all site3.com
```

## Script Flags

```bash
./generate-site-config.sh [FLAG] <domain>
```

**Available flags:**
- `--conf` - Generate HTTP config file only
- `--copy` - Create directory and copy config to nginx
- `--enable` - Enable site in nginx (tests config first)
- `--ssl` - Get SSL certificate and update to HTTPS config  
- `--all` - Run all steps: conf → copy → enable → ssl
- `--help` - Show usage and prerequisites

**Examples:**
```bash
./generate-site-config.sh --help           # Show all options
./generate-site-config.sh --all example.com # Complete setup (recommended)
./generate-site-config.sh --ssl example.com # Add SSL to existing HTTP site
```

## File Structure

**Created automatically:**
- `/var/www/example.com/` - Your website files go here
- `/etc/nginx/sites-available/example.com.conf` - Nginx config
- `/etc/nginx/sites-enabled/example.com.conf` - Symlink to enabled config
- `/var/www/certbot/` - Let's Encrypt challenge directory

**SSL certificates stored at:**
- `/etc/letsencrypt/live/example.com/fullchain.pem`
- `/etc/letsencrypt/live/example.com/privkey.pem`

## SSL Auto-Renewal

- ✅ **Automatic daily renewal** at 3 AM via cron job
- ✅ **Nginx auto-reload** after renewal
- ✅ **90-day Let's Encrypt certificates** renewed at 30 days

**Check certificate status:**
```bash
sudo certbot certificates
sudo certbot renew --dry-run  # Test renewal
```

## Troubleshooting

**Common issues:**

1. **"Domain not resolving"** - Make sure DNS points to your server
2. **"Port 80/443 blocked"** - Check firewall: `sudo ufw allow 'Nginx Full'`
3. **"SSL certificate failed"** - Ensure domain resolves and no other service uses port 80
4. **"Permission denied"** - Run with `sudo` or as root user

**Check everything is working:**
```bash
sudo nginx -t                    # Test nginx config
sudo systemctl status nginx      # Check nginx status  
sudo certbot certificates        # Check SSL certificates
curl -I https://example.com      # Test HTTPS redirect
```
