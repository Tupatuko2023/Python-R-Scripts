# Docker Quick Start - 5 Minutes to Running Scripts

**Goal:** Get K6-K16 scripts running in a reproducible environment
**Time:** ~20 minutes total (15 min build + 5 min testing)

---

## Step 1: Prerequisites (2 minutes)

### Install Docker Desktop

**Windows/Mac:** Download and install from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)

**Linux:**

```bash
sudo apt-get update
sudo apt-get install docker.io docker-compose
sudo usermod -aG docker $USER  # Add yourself to docker group
# Log out and back in
```

### Verify Installation

```bash
docker --version  # Should show: Docker version 20.10+
docker-compose --version  # Should show: docker-compose version 1.29+
```

---

## Step 2: Build Docker Image (15 minutes, one-time)

```bash
cd Fear-of-Falling

# Build the Docker image (downloads R packages, ~15 min)
docker-compose build
```

**What's happening:**

- Downloads base R image
- Installs system dependencies
- Restores all R packages from renv.lock
- Sets up project structure

**Coffee break time! ☕**

---

## Step 3: Run a Script (2 minutes)

### Windows

```cmd
docker-run.bat K11
```

### Mac/Linux

```bash
./docker-run.sh K11
```

**Output:**

- Script executes in Docker container
- Results saved to `R-scripts/K11/outputs/`
- Manifest updated automatically
- Console output displayed

---

## Step 4: Verify Success (1 minute)

```bash
# Check outputs were created
ls R-scripts/K11/outputs/

# Check manifest was updated
tail manifest/manifest.csv

# Run smoke tests (optional)
docker-compose --profile test up fof-test
```

---

## Common Commands

```bash
# Run single script
./docker-run.sh K11

# Run multiple scripts
./docker-run.sh K11 K12 K13

# Run all K6-K16
./docker-run.sh all

# Interactive R console
docker-compose run --rm fof-r-analysis

# Run smoke tests
docker-compose --profile test up fof-test

# Rebuild image (after package changes)
docker-compose build --no-cache
```

---

## Troubleshooting

**"docker: command not found"**

- Make sure Docker Desktop is installed and running

**"Cannot connect to Docker daemon"**

- Start Docker Desktop application
- Linux: `sudo systemctl start docker`

**Build is slow**

- This is normal for first build (~15 minutes)
- Subsequent builds are much faster (use cache)

**Script fails**

- Check logs for specific error
- Run interactively: `docker-compose run --rm fof-r-analysis R`
- See full guide: `DOCKER_SETUP.md`

---

## What's Next?

1. ✅ Build completed successfully?
2. ✅ Test script ran?
3. ✅ Outputs created?

**You're ready!** See `DOCKER_SETUP.md` for advanced usage.

---

## Why Docker?

| Without Docker              | With Docker                  |
| --------------------------- | ---------------------------- |
| ❌ "Works on my machine"    | ✅ Works everywhere          |
| ❌ Package conflicts        | ✅ Isolated environment      |
| ❌ Manual setup (30-60 min) | ✅ Automatic setup (15 min)  |
| ❌ Different versions       | ✅ Exact versions locked     |
| ❌ System dependency hell   | ✅ All dependencies included |

---

**Need help?** See `DOCKER_SETUP.md` for detailed documentation.
