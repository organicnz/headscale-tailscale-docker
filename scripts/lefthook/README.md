# Lefthook Scripts

This directory contains all Git hook scripts used by Lefthook for automated security checks and quality assurance.

## 📁 Scripts Overview

### Pre-Commit Hooks

#### `secrets-scan.sh`
**Purpose**: Detects exposed secrets in staged files before commit

**What it checks:**
- API keys with 20+ characters
- Passwords with 20+ characters
- Tokens with 20+ characters
- Secret keys with 20+ characters

**Exclusions:**
- Files ending in `.example`
- Placeholder values like `your_*_here`, `changeme`
- Environment variable references (`${VAR}`)
- Redacted values (`[REDACTED]`)

**Usage:**
```bash
bash scripts/lefthook/secrets-scan.sh
```

**Exit codes:**
- `0` - No secrets detected
- `1` - Secrets found (blocks commit)

---

#### `env-check.sh`
**Purpose**: Prevents committing `.env` file with sensitive credentials

**What it checks:**
- Whether `.env` is in staged files

**Usage:**
```bash
bash scripts/lefthook/env-check.sh
```

**Exit codes:**
- `0` - `.env` not being committed
- `1` - `.env` found in staging (blocks commit)

---

#### `headplane-config-check.sh`
**Purpose**: Prevents committing `headplane/config.yaml` with secrets

**What it checks:**
- Whether `headplane/config.yaml` is in staged files

**Usage:**
```bash
bash scripts/lefthook/headplane-config-check.sh
```

**Exit codes:**
- `0` - Config not being committed
- `1` - Config found in staging (blocks commit)

---

#### `ds-store-check.sh`
**Purpose**: Prevents committing macOS `.DS_Store` metadata files

**What it checks:**
- Whether any `.DS_Store` files are staged

**Actions:**
- Automatically unstages `.DS_Store` files if found

**Usage:**
```bash
bash scripts/lefthook/ds-store-check.sh
```

**Exit codes:**
- `0` - No `.DS_Store` files
- `1` - `.DS_Store` files found and removed (blocks commit to show message)

---

#### `example-files-check.sh`
**Purpose**: Verifies example configuration files exist

**What it checks:**
- Existence of `.env.example`
- Existence of `headplane/config.yaml.example`

**Usage:**
```bash
bash scripts/lefthook/example-files-check.sh
```

**Exit codes:**
- `0` - Always succeeds (warnings only)

---

#### `yaml-lint.sh`
**Purpose**: Validates YAML syntax in staged files

**Requirements:**
- Python 3 (for YAML parsing)

**What it checks:**
- YAML syntax validity
- Structural correctness

**Usage:**
```bash
bash scripts/lefthook/yaml-lint.sh
```

**Exit codes:**
- `0` - All YAML files valid or no Python available
- `1` - Invalid YAML syntax found (blocks commit)

---

### Pre-Push Hooks

#### `final-secrets-scan.sh`
**Purpose**: Comprehensive security scan of ALL tracked files before push

**What it checks:**
- All files tracked by Git
- Same patterns as `secrets-scan.sh` but more thorough

**Usage:**
```bash
bash scripts/lefthook/final-secrets-scan.sh
```

**Exit codes:**
- `0` - No secrets in tracked files
- `1` - Secrets found (blocks push)

---

#### `gitignore-check.sh`
**Purpose**: Verifies critical patterns are in `.gitignore`

**Required patterns:**
- `.env`
- `headplane/config.yaml`
- `data/`
- `*.log`

**Usage:**
```bash
bash scripts/lefthook/gitignore-check.sh
```

**Exit codes:**
- `0` - Always succeeds (warnings only)

---

#### `large-files-check.sh`
**Purpose**: Warns about files larger than 1MB being pushed

**What it checks:**
- File sizes in staging area
- Threshold: 1MB (1048576 bytes)

**Usage:**
```bash
bash scripts/lefthook/large-files-check.sh
```

**Exit codes:**
- `0` - Always succeeds (warnings only)

---

### Commit Message Hooks

#### `commit-msg-format.sh`
**Purpose**: Validates commit message quality

**What it checks:**
- Message is not empty
- Message has at least 10 characters
- Detects conventional commit format (optional)

**Usage:**
```bash
bash scripts/lefthook/commit-msg-format.sh <commit-msg-file>
```

**Exit codes:**
- `0` - Valid commit message
- `1` - Invalid message (blocks commit)

---

## 🧪 Testing Scripts

You can test scripts individually:

```bash
# Test secrets scanner
echo "api_key: test123456789012345678901234567890" > test.txt
git add test.txt
bash scripts/lefthook/secrets-scan.sh
git restore --staged test.txt
rm test.txt

# Test YAML linter
echo "invalid: yaml: : syntax" > test.yml
git add test.yml
bash scripts/lefthook/yaml-lint.sh
git restore --staged test.yml
rm test.yml

# Test commit message validator
echo "short" > /tmp/test-msg.txt
bash scripts/lefthook/commit-msg-format.sh /tmp/test-msg.txt
rm /tmp/test-msg.txt
```

## 🔧 Customization

### Adding Exclusions to Secrets Scanner

Edit `secrets-scan.sh` or `final-secrets-scan.sh` and add patterns to `EXCLUDE_PATTERNS`:

```bash
EXCLUDE_PATTERNS=(
  ".example"
  "your_.*_here"
  "changeme"
  # Add your custom exclusion here
  "MY_CUSTOM_PATTERN"
)
```

### Changing File Size Threshold

Edit `large-files-check.sh` and modify the size check:

```bash
if [ "$size" -gt 1048576 ]; then  # 1MB - change this value
```

### Adding Required .gitignore Patterns

Edit `gitignore-check.sh` and add to `REQUIRED_PATTERNS`:

```bash
REQUIRED_PATTERNS=(
  ".env"
  "headplane/config.yaml"
  # Add your custom pattern here
  "my-sensitive-dir/"
)
```

## 🐛 Troubleshooting

### Scripts Not Executing

Check permissions:
```bash
ls -l scripts/lefthook/*.sh
```

Make executable if needed:
```bash
chmod +x scripts/lefthook/*.sh
```

### Python Not Found

YAML validation requires Python 3:
```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt install python3

# Fedora/RHEL
sudo dnf install python3
```

### False Positives in Secret Scanner

1. Check if the pattern is legitimate
2. Add exclusion to `EXCLUDE_PATTERNS` in script
3. Use environment variables instead of hardcoded values

## 📝 Adding New Hooks

1. Create new script in `scripts/lefthook/`
2. Make it executable: `chmod +x scripts/lefthook/your-script.sh`
3. Add entry to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    your-check:
      tags: your-category
      run: bash scripts/lefthook/your-script.sh
```

4. Test it: `lefthook run pre-commit`
5. Document it in this README

## 🔄 CI/CD Integration

These scripts can be run in CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Run Lefthook Checks
  run: |
    npm install -g lefthook
    lefthook run pre-push
```

Or run individual scripts:

```yaml
- name: Check for Secrets
  run: bash scripts/lefthook/final-secrets-scan.sh
```

## 📚 Best Practices

1. **Keep scripts focused**: Each script should do one thing well
2. **Provide clear error messages**: Users should know what went wrong and how to fix it
3. **Use exit codes properly**: `0` for success, `1` for failure
4. **Make scripts idempotent**: Safe to run multiple times
5. **Add comments**: Explain complex logic
6. **Test thoroughly**: Verify both success and failure cases

## 🔗 Related Documentation

- [Main Lefthook Documentation](../../LEFTHOOK.md)
- [Lefthook Configuration](../../lefthook.yml)
- [Project README](../../README.md)

---

**Need help?** Check the main LEFTHOOK.md documentation or open an issue.
