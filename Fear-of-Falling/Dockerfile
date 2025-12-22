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

# Restore R packages from lockfile
# This is the time-consuming step but cached unless renv.lock changes
RUN R -e "renv::restore(prompt = FALSE, repos = 'https://cloud.r-project.org')"

# Copy the rest of the project
COPY . .

# Verify critical packages are installed
RUN R -e "library(dplyr); library(here); library(ggplot2); library(lme4); cat('✓ Critical packages loaded successfully\n')"

# Create outputs directories
RUN mkdir -p R-scripts/{K6,K7,K8,K9,K10,K11,K12,K13,K14,K15,K16}/outputs

# Set proper permissions
RUN chmod -R 755 /project

# Default command: Start R console
CMD ["R"]
