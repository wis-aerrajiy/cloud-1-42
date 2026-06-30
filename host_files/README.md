# Per-host files

Files here are keyed by inventory hostname and copied to the matching
server by the `nginx` role - this is how each server gets its own SSL
certificate without changing any role code.

```
host_files/
└── <hostname>/        # must match the host name in hosts.yml
    └── ssl/
        ├── fullchain.pem      # full certificate chain
        └── <domain_name>.key  # private key, named after that host's domain_name
```

Never commit the `.key` files - they're covered by `.gitignore`, but
double-check before pushing.
