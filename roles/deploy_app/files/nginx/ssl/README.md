# SSL Certificate Files

This directory contains SSL/TLS certificate files for Nginx configuration.

## Files Required

- **private.key** - Private key file (keep confidential)
- **fullchain.pem** - Full certificate chain file

## Setup Instructions

1. Place your SSL certificate files in this directory
2. Ensure proper file permissions:
    ```bash
    chmod 600 private.key
    chmod 644 fullchain.pem
    ```
3. Update your Nginx configuration to reference these files
4. Never commit private keys to version control

## Security Notes

- Keep `private.key` secure and never expose it
- Add private keys to `.gitignore`
- Restrict read permissions to the Nginx process owner