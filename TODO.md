# Removing Existing SSL Certificates

If you have existing SSL certificates from the old script version, you'll need to remove them before using the new webroot method.

## Quick Removal

```bash
# Remove all certificates and nginx configs
sudo ./generate.sh --remove --domain=yourdomain.com

# Or remove certificates manually:
sudo certbot delete --cert-name yourdomain.com
sudo rm -rf /etc/nginx/sites-available/yourdomain.com.conf
sudo rm -rf /etc/nginx/sites-enabled/yourdomain.com.conf
sudo rm -rf /var/www/yourdomain.com
```

## List All Certificates

```bash
sudo certbot certificates
```

## Remove All Certificates (Nuclear Option)

```bash
# Stop nginx
sudo systemctl stop nginx

# Remove all Let's Encrypt certificates
sudo rm -rf /etc/letsencrypt/live/*
sudo rm -rf /etc/letsencrypt/archive/*
sudo rm -rf /etc/letsencrypt/renewal/*

# Remove all site configs
sudo rm -rf /etc/nginx/sites-available/*.conf
sudo rm -rf /etc/nginx/sites-enabled/*.conf

# Remove all webroots
sudo rm -rf /var/www/*/

# Remove cron job
sudo crontab -l | grep -v "certbot renew" | sudo crontab -

# Start nginx
sudo systemctl start nginx
```

## After Removal

Use the new script which now supports webroot method for automatic SSL renewal:

```bash
sudo ./generate.sh --all --domain=yourdomain.com
```

The new method keeps nginx running during certificate generation and renewal.