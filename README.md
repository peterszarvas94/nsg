# NSG - Nginx Site Generator

Automated nginx setup with SSL for static sites and PocketBase applications.

## Quick Start

```bash
git clone https://github.com/peterszarvas94/nsg.git
cd nsg
chmod +x generate.sh
sudo ./generate.sh setup --domain=example.com
```

## Commands

```bash
./generate.sh COMMAND [--domain=example.com] [OPTIONS]
```

| Command  | Description                                 |
| -------- | ------------------------------------------- |
| `setup`  | Complete site setup (SSL + config + enable) |
| `pb`     | Setup PocketBase subdomain                  |
| `check`  | Check domain health                         |
| `remove` | Remove site completely                      |

## Options

| Option                 | Description                             |
| ---------------------- | --------------------------------------- |
| `--www`                | Enable www redirect (for setup command) |
| `--port=8090`          | PocketBase port (default: 8090)         |
| `--domain=example.com` | Specify domain                          |

## Examples

### Static Sites

```bash
./generate.sh setup --domain=example.com
./generate.sh setup --www --domain=example.com  # With www redirect
```

### PocketBase Sites

```bash
./generate.sh pb --domain=pb.example.com                 # Default port 8090
./generate.sh pb --domain=pb2.example.com --port=8091    # Port 8091
```

### Site Management

```bash
./generate.sh check --domain=example.com    # Check health
./generate.sh remove --domain=example.com   # Remove site
```

## PocketBase

PocketBase gets its own subdomain with full proxy to localhost port (default 8090).
Multiple PocketBase instances supported with different ports.

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

