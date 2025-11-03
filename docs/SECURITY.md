# Security Guidelines

## Critical Security Requirements

### 1. Change Default Passwords

**BEFORE** deploying to production, you MUST change the default database password:

1. Generate a strong password:
   ```bash
   openssl rand -base64 32
   ```

2. Update `.env` file:
   ```bash
   POSTGRES_PASSWORD=your_strong_password_here
   ```

3. Update `config/config.yaml`:
   ```yaml
   database:
     postgres:
       pass: your_strong_password_here  # Must match .env
   ```

### 2. Never Commit Sensitive Files

The following files are excluded by `.gitignore` and should NEVER be committed:

- `.env` - Contains your actual passwords and configuration
- `data/` - Contains Headscale state and keys
- `caddy-data/` - Contains SSL certificates
- `backups/` - Contains database backups

### 3. Production Deployment Checklist

Before exposing to the internet:

- [ ] Changed default PostgreSQL password
- [ ] Updated `server_url` in config.yaml to your actual domain
- [ ] Configured proper DNS records
- [ ] Enabled HTTPS in Caddyfile (for production)
- [ ] Reviewed and configured ACL policies
- [ ] Set up regular backups
- [ ] Limited pre-auth key lifetime
- [ ] Reviewed and secured open ports

### 4. Pre-Auth Key Security

- Use short expiration times (24h recommended)
- Use `--ephemeral` for temporary devices
- Regularly audit and expire unused keys:
  ```bash
  ./headscale.sh keys list default
  ```

### 5. Network Security

- The metrics endpoint (port 8080) is bound to localhost only
- PostgreSQL is NOT exposed outside the Docker network
- Use firewall rules to restrict access to Caddy ports

### 6. Regular Maintenance

```bash
# Regular security updates
docker compose pull
docker compose up -d

# Monitor logs for suspicious activity
docker compose logs -f headscale

# Regular backups
./backup.sh
```

## Reporting Security Issues

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Contact the maintainer privately
3. Provide detailed information about the vulnerability
4. Allow reasonable time for a fix before public disclosure

## Security Best Practices

### ACL Policies

Implement least-privilege access control:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:admin"],
      "dst": ["*:*"]
    },
    {
      "action": "accept",
      "src": ["group:users"],
      "dst": ["tag:services:80,443"]
    }
  ]
}
```

### Database Backups

Encrypt backups if storing remotely:

```bash
# Backup and encrypt
./backup.sh
gpg --symmetric --cipher-algo AES256 backups/database_*.sql
```

### Monitoring

Enable metrics collection and monitor for:
- Unusual connection patterns
- Failed authentication attempts
- Unexpected node registrations

```bash
curl http://localhost:8080/metrics
```

## Default Credentials Warning

This repository contains example configurations with default/weak passwords for **development purposes only**. These MUST be changed before any production use.

Default values that MUST be changed:
- PostgreSQL password: `changeme`
- Server URL: `http://localhost:8000`

## Additional Resources

- [Headscale Security Documentation](https://headscale.net/security/)
- [Tailscale Security Best Practices](https://tailscale.com/kb/1077/secure-server-ubuntu/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
