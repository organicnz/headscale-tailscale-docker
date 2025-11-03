# Git Hooks with Lefthook

This repository uses [Lefthook](https://github.com/evilmartians/lefthook) to manage Git hooks for automated security checks and quality assurance.

## What is Lefthook?

Lefthook is a fast and powerful Git hooks manager that runs checks before commits and pushes to prevent common mistakes like accidentally committing secrets.

## Installation

### macOS
```bash
brew install lefthook
```

### Linux
```bash
# Using npm
npm install -g lefthook

# Or download binary
curl -1sLf 'https://dl.cloudsmith.io/public/evilmartians/lefthook/setup.deb.sh' | sudo -E bash
sudo apt install lefthook
```

### Windows
```powershell
# Using npm
npm install -g lefthook

# Or using Scoop
scoop install lefthook
```

## Setup

After cloning the repository, install the hooks:

```bash
lefthook install
```

This creates the necessary Git hooks in `.git/hooks/`.

## What Gets Checked

### Pre-Commit Hooks

Before each commit, Lefthook automatically checks:

1. **Secrets Scan** 🔍
   - Scans for exposed API keys, passwords, and tokens
   - Prevents hardcoded secrets in committed files
   - Allows placeholders and example values

2. **Environment File Check** 🔒
   - Ensures `.env` is not committed
   - Protects sensitive configuration

3. **Headplane Config Check** 🔒
   - Ensures `headplane/config.yaml` is not committed
   - Redirects to use `headplane/config.yaml.example`

4. **Cleanup Check** 🧹
   - Prevents `.DS_Store` files from being committed
   - Auto-removes them from staging

5. **Example Files Check** 📄
   - Verifies `.env.example` and other example files exist
   - Ensures documentation is up to date

6. **YAML Validation** ✅
   - Validates YAML syntax in all `.yml` and `.yaml` files
   - Catches syntax errors before commit

### Pre-Push Hooks

Before pushing to remote, Lefthook checks:

1. **Final Security Scan** 🛡️
   - Comprehensive scan of all tracked files
   - Last line of defense against exposed secrets

2. **Gitignore Verification** 📋
   - Ensures critical patterns are in `.gitignore`
   - Validates security configuration

3. **Large Files Check** 📦
   - Warns about files larger than 1MB
   - Suggests using Git LFS if needed

### Commit Message Hooks

When writing commit messages:

1. **Format Validation** 📝
   - Ensures commit message is not empty
   - Requires minimum 10 characters
   - Promotes meaningful commit messages

## Usage Examples

### Normal Workflow

```bash
# Make changes
vim config/config.yaml

# Stage changes
git add config/config.yaml

# Commit - hooks run automatically
git commit -m "Update configuration"

# Push - additional checks run
git push
```

### If Secrets Are Detected

```bash
$ git commit -m "Add API configuration"

🔍 Scanning for exposed secrets...
❌ ERROR: Potential secrets detected in staged files!
Please remove hardcoded secrets and use environment variables instead.

config/config.yaml:10:  api_key: "abc123secretkey456"
```

**Fix:** Move secrets to `.env` and use environment variables.

### Skipping Hooks (Not Recommended)

If you absolutely need to skip hooks:

```bash
# Skip all hooks
git commit --no-verify -m "Emergency fix"

# Skip specific hook
LEFTHOOK_EXCLUDE=secrets-scan git commit -m "Update docs"
```

⚠️ **Warning:** Only skip hooks if you're certain your changes are safe!

## Configuration

All hook configuration is in `lefthook.yml`. You can customize:

- Add new checks
- Modify existing patterns
- Enable/disable specific hooks
- Add file-specific validations

### Example: Add a new check

```yaml
pre-commit:
  commands:
    my-custom-check:
      tags: validation
      run: |
        echo "Running custom validation..."
        # Your custom script here
```

## Troubleshooting

### Hooks Not Running

```bash
# Reinstall hooks
lefthook install

# Verify installation
lefthook run pre-commit
```

### False Positives

If legitimate code triggers the secrets check, you can:

1. Update the pattern in `lefthook.yml`
2. Use environment variables instead
3. Add the specific pattern to exclusions

### Updating Lefthook

```bash
# macOS
brew upgrade lefthook

# npm
npm update -g lefthook

# Reinstall hooks after update
lefthook install
```

## Benefits

✅ **Security**: Automatically prevents committing secrets
✅ **Quality**: Enforces code and documentation standards
✅ **Fast**: Runs checks in parallel for speed
✅ **Customizable**: Easy to add project-specific checks
✅ **Team-friendly**: Ensures everyone follows the same standards

## CI/CD Integration

You can run Lefthook checks in CI/CD:

```yaml
# GitHub Actions example
- name: Install Lefthook
  run: npm install -g lefthook

- name: Run Lefthook checks
  run: lefthook run pre-push
```

## Additional Resources

- [Lefthook Documentation](https://github.com/evilmartians/lefthook/blob/master/docs/full_guide.md)
- [Configuration Examples](https://github.com/evilmartians/lefthook/blob/master/docs/configuration.md)
- [Best Practices](https://evilmartians.com/chronicles/lefthook-knock-your-teams-code-back-into-shape)

## Maintenance

### Updating Hook Rules

1. Edit `lefthook.yml`
2. Run `lefthook install` to update hooks
3. Test with `lefthook run pre-commit`
4. Commit the changes

### Sharing with Team

Everyone on the team should run after cloning:

```bash
lefthook install
```

Consider adding this to your onboarding documentation!

---

**Note**: These hooks help prevent common mistakes but are not a replacement for proper security practices. Always review your commits carefully and never commit sensitive data.
