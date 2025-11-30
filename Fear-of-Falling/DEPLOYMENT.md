# Deployment and Configuration Guide

## Database Configuration

### Local Development

1. Copy the configuration template:

   ```bash
   cp config/database.yml.example config/database.yml
   ```

2. Edit `config/database.yml` with your local database credentials.

3. The file is protected by `.gitignore` and will never be committed to version
   control.

### Production Deployment (Recommended)

**Do NOT commit `config/database.yml` with actual credentials to version
control.**

Instead, use environment variables to provide database configuration at runtime:

#### Using DATABASE_URL Environment Variable

Set the `DATABASE_URL` environment variable in your deployment platform:

```bash
export DATABASE_URL="postgresql://user:password@prod-db.example.com:5432/mydb"
```

Supported formats:

- **PostgreSQL**: `postgresql://user:password@host:port/database`
- **MySQL**: `mysql+pymysql://user:password@host:port/database`
- **SQLite**: `sqlite:///./database.db`

#### Using Docker

In your `Dockerfile` or `docker-compose.yml`:

```yaml
environment:
  DATABASE_URL: postgresql://user:password@db-service:5432/mydb
```

#### Using .env File (Development Only)

If using a `.env` file locally, load it with a library like `python-dotenv`:

```python
import os
from dotenv import load_dotenv

load_dotenv()  # Load .env file
database_url = os.getenv('DATABASE_URL')
```

**IMPORTANT**: `.env` files are listed in `.gitignore` and must never be
committed.

## Security Best Practices

1. **Never commit secrets**: Database credentials, API keys, and other secrets
   should never be stored in version control.

2. **Use environment variables**: All sensitive configuration should be loaded
   from environment variables or secure secret management systems.

3. **Rotate credentials regularly**: When a secret is exposed, rotate it
   immediately.

4. **Use a secret management system**: For production, consider using:

   - AWS Secrets Manager
   - Azure Key Vault
   - HashiCorp Vault
   - GitHub Secrets (for CI/CD)

5. **Code review**: Always review changes to configuration files and
   `.gitattributes` in pull requests.

## For This Repository

The `git-crypt` filter has been removed from `config/database.yml` to encourage
secure handling of credentials through environment variables rather than
encrypted files in version control.

## Repository Cleanup Instructions

To finalize the migration away from encrypted credentials:

1. Remove the tracked `config/database.yml` file from git history:

   ```bash
   git rm --cached Fear-of-Falling/config/database.yml
   git commit -m "Stop tracking database config (use .env or env vars instead)"
   ```

2. Force-push if necessary:

   ```bash
   git push origin chore/make-portable-mkdir --force-with-lease
   ```

3. Audit git history for any exposed credentials:

   ```bash
   git log --all -S "password" -- Fear-of-Falling/config/
   ```

4. Rotate/revoke git-crypt keys and re-encrypt remaining `data/external/**`
   files with new keys.
