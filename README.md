# NSG - Nginx Site Generator

Automated nginx setup with SSL for static sites and PocketBase applications.

## Quick Start

```bash
git clone https://github.com/peterszarvas94/nsg.git
cd nsg
chmod +x generate.sh
sudo ./generate.sh all --domain=example.com
```

## Commands

```bash
./generate.sh COMMAND [--domain=example.com] [OPTIONS]
```

| Command  | Description                                 |
| -------- | ------------------------------------------- |
| `setup`  | Complete site setup (SSL + config + enable) |
| `pb`     | Add PocketBase to existing site             |
| `check`  | Check domain health                         |
| `remove` | Remove site completely                      |

## Options

| Option                 | Description                                  |
| ---------------------- | -------------------------------------------- |
| `--www`                | Enable www redirect (for setup command)      |
| `--pb`                 | Include PocketBase proxy (for setup command) |
| `--domain=example.com` | Specify domain                               |

## Examples

### Static Sites

```bash
./generate.sh setup --domain=example.com
./generate.sh setup --www --domain=example.com  # With www redirect
```

### PocketBase Sites

```bash
./generate.sh setup --pb --domain=example.com  # Full setup
./generate.sh setup --www --pb --domain=example.com  # With www and PocketBase
./generate.sh pb --domain=example.com  # Add to existing site
```

### Site Management

```bash
./generate.sh check --domain=example.com    # Check health
./generate.sh remove --domain=example.com   # Remove site
```

## PocketBase

When using PocketBase commands, these endpoints are automatically proxied:

- `/api/` → PocketBase API
- `/_/` → PocketBase Admin panel
- Port 8090 forwarded internally

## Prerequisites

- Ubuntu/Debian server with sudo access
- Domain pointing to server IP
- Ports 80 and 443 open

## What Gets Created

- `/var/www/example.com/` - Webroot
- `/etc/nginx/sites-available/example.com.conf` - Nginx config
- SSL certificates via Let's Encrypt
- Auto-renewal setup

## File Upload

After setup, copy files to webroot:

```bash
sudo cp -r /path/to/site/* /var/www/example.com/
sudo chown -R www-data:www-data /var/www/example.com/
```

## SSL Auto-Renewal

Certificates auto-renew via cron. Check status:

```bash
sudo certbot certificates
sudo certbot renew --dry-run
```

## Troubleshooting

```bash
sudo nginx -t                    # Test nginx config
sudo systemctl status nginx      # Check nginx
./generate.sh check --domain=example.com  # Full health check
```

---

Created with [Claude](https://claude.ai) and [OpenCode](https://opencode.ai)

