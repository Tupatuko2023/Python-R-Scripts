# Dockerfile for Fear of Falling R Analysis Environment
# Base image: rocker/tidyverse with R 4.4.2
# Purpose: Reproducible environment for K6-K16 scripts

FROM rocker/tidyverse:4.4.2

# Metadata
LABEL maintainer="FOF Analysis Team"
LABEL description="Reproducible R environment for Fear of Falling analysis"
LABEL version="1.0"

# Set environment variables
ENV RENV_CONFIG_REPOS_OVERRIDE="https://cloud.r-project.org"
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Graphics and fonts
    libcairo2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    # XML and web
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    # Office document generation
    libgit2-dev \
    # Build tools
    pkg-config \
    cmake \
    # Utilities
    git \
    wget \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Create project directory
WORKDIR /project

# Copy renv infrastructure first (for better layer caching)
COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# Install renv
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org')"

# Remove system rprojroot from all library locations to avoid version conflicts
# The base image has rprojroot 2.0.4, but we need >= 2.1.0 from renv
RUN rm -rf /usr/local/lib/R/site-library/rprojroot \
    && rm -rf /usr/local/lib/R/library/rprojroot

# Restore R packages from lockfile
# This is the time-consuming step but cached unless renv.lock changes
# Force rebuild to ensure lockfile versions override system packages
RUN R -e "renv::restore(prompt = FALSE, rebuild = TRUE, repos = 'https://cloud.r-project.org')"

# Set R_LIBS to include renv library even with --vanilla
# This ensures scripts run with --vanilla can still find renv packages
ENV R_LIBS=/project/renv/library/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu:/usr/local/lib/R/site-library:/usr/local/lib/R/library

# Copy the rest of the project
COPY . .

# Verify critical packages are installed and check versions
RUN R -e "library(rprojroot); cat('rprojroot version:', as.character(packageVersion('rprojroot')), '\n'); library(dplyr); library(here); library(ggplot2); library(lme4); cat('✓ Critical packages loaded successfully\n')"

# Generate mock data for CI/CD (replaces encrypted real data)
# This ensures smoke tests can run in Docker without git-crypt keys
RUN Rscript tests/generate_mock_data.R data/external/KaatumisenPelko.csv && \
    echo "✓ Mock data generated for Docker image"

# Create outputs directories
RUN mkdir -p R-scripts/{K1,K2,K3,K4,K6,K7,K8,K9,K10,K11,K12,K13,K14,K15,K16}/outputs

# Set proper permissions
RUN chmod -R 755 /project

# Default command: Start R console
CMD ["R"]
