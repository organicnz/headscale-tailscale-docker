# File Organization

This document explains the file structure and organization of the Headscale deployment stack.

## Directory Structure

```
/Users/organic/dev/work/vpn/headscale-tailscale-docker/
├── docker-compose.yml                  # Production-ready compose file
├── docker-compose.override.yml         # Development overrides (gitignored)
├── docker-compose.override.example.yml # Development template
├── .env                                # Environment variables (gitignored)
├── .env.example                        # Environment template
├── .gitignore                          # Git ignore rules
├── CLAUDE.md                           # Development guidelines
├── README.md                           # Main documentation
│
├── config/                             # Headscale configuration
│   ├── config.yaml                     # Headscale server config
│   └── acl.example.json                # ACL policy example
│
├── data/                               # Headscale data (gitignored)
│   └── headscale.db                    # SQLite database
│
├── nginx.conf                          # Production nginx (SSL/TLS)
├── nginx.dev.conf                      # Development nginx (HTTP only)
│
├── scripts/                            # Helper scripts
│   ├── nginx.sh                        # nginx management
│   ├── headscale.sh                    # Headscale management
│   ├── setup.sh                        # Initial setup
│   ├── backup.sh                       # Backup utility
│   └── lefthook/                       # Git hooks
│
├── docs/                               # Documentation
│   ├── DEPLOYMENT.md                   # Deployment guide
│   ├── NGINX_CONFIGURATION.md          # nginx setup
│   ├── NGINX_QUICK_REFERENCE.md        # Quick commands
│   ├── NGINX_ARCHITECTURE.md           # Architecture diagrams
│   ├── NGINX_REFACTORING_SUMMARY.md    # Refactoring details
│   ├── NGINX_CONSOLIDATION.md          # Consolidation details
│   ├── CONSOLIDATION_SUMMARY.md        # Docker compose consolidation
│   ├── REFACTORING_COMPLETE.md         # Complete summary
│   ├── SECURITY.md                     # Security best practices
│   ├── BEST_PRACTICES.md               # Production best practices
│   ├── DOCUMENTATION_INDEX.md          # Documentation index
│   └── FILE_ORGANIZATION.md            # This file
│
├── headplane/                          # Headplane UI config (gitignored)
│   └── config.yaml                     # Headplane settings
│
├── logs/                               # Log files (gitignored)
│   └── nginx/                          # nginx logs
│       ├── access.log
│       └── error.log
│
├── certbot/                            # SSL certificates (gitignored)
│   ├── conf/                           # Certificate storage
│   │   └── live/                       # Live certificates
│   └── www/                            # ACME challenge files
│
└── backups/                            # Database backups (gitignored)
    └── database_*.sql                  # Timestamped backups
```

## File Purposes

### Root Configuration Files

#### Production
- **docker-compose.yml** - Production-ready configuration with SSL/TLS
- **nginx.conf** - Production nginx with HTTPS, rate limiting, security headers

#### Development
- **docker-compose.override.yml** - Created from example, overrides for local dev
- **nginx.dev.conf** - Simple HTTP configuration, no SSL

#### Templates
- **docker-compose.override.example.yml** - Template for development overrides
- **.env.example** - Template for environment variables

#### Git
- **.gitignore** - Excludes sensitive files and generated content

#### Documentation
- **CLAUDE.md** - Guidelines for Claude Code assistant
- **README.md** - Main project documentation

### Scripts Directory (`scripts/`)

All helper scripts are located in the `scripts/` directory:

#### nginx Management (`scripts/nginx.sh`)
```bash
./scripts/nginx.sh status      # Container status
./scripts/nginx.sh logs [n]    # View logs
./scripts/nginx.sh test        # Test configuration
./scripts/nginx.sh reload      # Hot reload
./scripts/nginx.sh restart     # Full restart
./scripts/nginx.sh health      # Health check
./scripts/nginx.sh ssl-init    # Initialize SSL
./scripts/nginx.sh ssl-info    # Certificate info
./scripts/nginx.sh stats       # Resource usage
./scripts/nginx.sh connections # Active connections
./scripts/nginx.sh follow      # Follow logs
```

#### Headscale Management (`scripts/headscale.sh`)
```bash
./scripts/headscale.sh users create <name>    # Create user
./scripts/headscale.sh users list             # List users
./scripts/headscale.sh keys create <user>     # Create auth key
./scripts/headscale.sh nodes list             # List nodes
./scripts/headscale.sh routes list            # List routes
./scripts/headscale.sh status                 # Status check
./scripts/headscale.sh health                 # Health check
./scripts/headscale.sh logs [n]               # View logs
```

#### Setup and Maintenance
```bash
./scripts/setup.sh              # Interactive initial setup
./scripts/backup.sh             # Database backup utility
```

#### Git Hooks (`scripts/lefthook/`)
Lefthook configuration for pre-commit hooks:
- Prevents committing secrets
- Validates configuration files
- Runs linters

### Documentation Directory (`docs/`)

Comprehensive documentation organized by topic:

#### Deployment Guides
- **DEPLOYMENT.md** - Complete deployment guide (dev and prod)
- **QUICKSTART.md** - Fast setup instructions

#### nginx Documentation
- **NGINX_CONFIGURATION.md** - Complete nginx setup guide
- **NGINX_QUICK_REFERENCE.md** - Command reference
- **NGINX_ARCHITECTURE.md** - Architecture diagrams and flows
- **NGINX_REFACTORING_SUMMARY.md** - Caddy to nginx migration
- **NGINX_CONSOLIDATION.md** - nginx config consolidation

#### Project Documentation
- **CONSOLIDATION_SUMMARY.md** - Docker compose consolidation
- **REFACTORING_COMPLETE.md** - Complete refactoring summary
- **FILE_ORGANIZATION.md** - This file

#### Best Practices
- **SECURITY.md** - Security configuration and best practices
- **BEST_PRACTICES.md** - Production deployment best practices
- **DOCUMENTATION_INDEX.md** - Documentation navigation

#### Advanced Topics
- **NETWORKING.md** - Advanced networking configuration
- **DEBUG_REPORT.md** - Debugging and troubleshooting

### Configuration Directory (`config/`)

Headscale server configuration:

- **config.yaml** - Main Headscale configuration
  - Server URL
  - Database connection (PostgreSQL)
  - DERP server settings
  - MagicDNS configuration
  - IP prefixes

- **acl.example.json** - Example ACL policy
  - Group definitions
  - Tag owners
  - Access rules

### Data Directory (`data/`)

Runtime data (gitignored):

- **headscale.db** - SQLite database (if not using PostgreSQL)
- Keys and state files

### Logs Directory (`logs/`)

Application logs (gitignored):

- **nginx/access.log** - nginx access logs
- **nginx/error.log** - nginx error logs

### SSL Certificates (`certbot/`)

Let's Encrypt certificates (gitignored):

- **conf/** - Certificate storage
- **www/** - ACME challenge files for domain verification

### Backups Directory (`backups/`)

Database backups (gitignored):

- **database_YYYYMMDD_HHMMSS.sql** - Timestamped SQL dumps

## Gitignored Files

The following files are excluded from version control:

### Sensitive Data
- `.env` - Environment variables (passwords, API keys)
- `headplane/config.yaml` - Headplane configuration with secrets

### Generated/Runtime Data
- `data/` - Headscale runtime data and database
- `logs/` - Application logs
- `certbot/` - SSL certificates
- `backups/` - Database backups

### Development Overrides
- `docker-compose.override.yml` - Personal dev settings

### System Files
- `.DS_Store` - macOS metadata
- `*.log` - Log files
- `*.tmp` - Temporary files
- `.history/` - Shell history

## Version Controlled Files

The following files ARE tracked in git:

### Configuration
- `docker-compose.yml` (production)
- `docker-compose.override.example.yml` (dev template)
- `.env.example` (environment template)
- `.gitignore`
- `nginx.conf` (production)
- `nginx.dev.conf` (development)

### Code
- `scripts/*.sh` (all helper scripts)
- `scripts/lefthook/` (git hooks)

### Documentation
- `CLAUDE.md`
- `README.md`
- `docs/*.md` (all documentation)

### Headscale Config
- `config/config.yaml.example` (if exists)
- `config/acl.example.json`

## File Naming Conventions

### Scripts
- **Format**: `<action>.sh`
- **Examples**: `nginx.sh`, `headscale.sh`, `setup.sh`, `backup.sh`
- **Location**: `scripts/` directory
- **Execution**: `./scripts/<script>.sh`
- **Permissions**: Executable (chmod +x)

### Documentation
- **Format**: `<TOPIC>_<SUBTOPIC>.md` or `<TOPIC>.md`
- **Examples**: `NGINX_CONFIGURATION.md`, `DEPLOYMENT.md`
- **Location**: `docs/` directory or root (CLAUDE.md, README.md)
- **Case**: UPPERCASE for important docs, Title Case for guides

### Configuration
- **Format**: `<service>.conf` or `config.yaml`
- **Examples**: `nginx.conf`, `nginx.dev.conf`, `config.yaml`
- **Location**: Root or `config/` directory

### Compose Files
- **Format**: `docker-compose.<variant>.yml`
- **Examples**: `docker-compose.yml`, `docker-compose.override.yml`
- **Location**: Root directory

## Path References

### In Documentation
Always use relative paths from the root directory:

```bash
# Correct
./scripts/nginx.sh status
./scripts/headscale.sh users list

# Incorrect (old format)
./nginx.sh status
./headscale.sh users list
```

### In Scripts
Scripts reference each other using relative paths:

```bash
# From root
./scripts/nginx.sh

# From within scripts/
../scripts/backup.sh
```

### In Docker Compose
Volume mounts use paths relative to the compose file:

```yaml
volumes:
  - ./nginx.conf:/etc/nginx/nginx.conf:ro
  - ./scripts/nginx.sh:/scripts/nginx.sh:ro
  - ./logs/nginx:/var/log/nginx
```

## Organization Philosophy

### Production-First
- Main configuration files (`docker-compose.yml`, `nginx.conf`) are production-ready
- Development is opt-in via overrides

### Separation of Concerns
- **Scripts**: Operational tools (scripts/)
- **Docs**: All documentation (docs/)
- **Config**: Service configuration (config/)
- **Data**: Runtime data (data/, logs/, certbot/, backups/)

### Documentation Co-location
- Development guidelines (CLAUDE.md, README.md) in root for visibility
- Detailed documentation in docs/ for organization

### Clear Naming
- Production files have simple names (`nginx.conf`)
- Variant files have descriptive suffixes (`nginx.dev.conf`)
- Documentation uses descriptive names (`NGINX_CONFIGURATION.md`)

## Quick Reference

### Running Scripts
```bash
# Always use scripts/ prefix
./scripts/nginx.sh <command>
./scripts/headscale.sh <command>
./scripts/setup.sh
./scripts/backup.sh
```

### Accessing Documentation
```bash
# Main docs
cat README.md
cat CLAUDE.md

# Detailed guides
cat docs/DEPLOYMENT.md
cat docs/NGINX_CONFIGURATION.md
cat docs/SECURITY.md

# Quick reference
cat docs/NGINX_QUICK_REFERENCE.md
```

### Configuration Files
```bash
# Production (default)
nginx.conf                    # nginx production config
docker-compose.yml            # Docker compose production config

# Development (override)
nginx.dev.conf                # nginx dev config
docker-compose.override.yml   # Docker compose dev overrides (create from example)

# Headscale
config/config.yaml            # Headscale configuration
config/acl.example.json       # ACL policy example
```

## Maintenance

### Adding New Scripts
1. Create script in `scripts/` directory
2. Make executable: `chmod +x scripts/new-script.sh`
3. Update this documentation
4. Update README.md if user-facing

### Adding New Documentation
1. Create markdown file in `docs/` directory
2. Use descriptive naming: `TOPIC_SUBTOPIC.md`
3. Add to `docs/DOCUMENTATION_INDEX.md`
4. Link from README.md if important

### Updating Paths
If file locations change:
1. Update this file (FILE_ORGANIZATION.md)
2. Search and replace in all documentation: `grep -r "old/path" docs/`
3. Update README.md structure section
4. Test all script references

---

This organization provides:
- ✅ Clear separation between production and development
- ✅ Logical grouping of related files
- ✅ Easy navigation and discovery
- ✅ Consistent naming conventions
- ✅ Security (sensitive files gitignored)
- ✅ Maintainability (documentation co-located)
