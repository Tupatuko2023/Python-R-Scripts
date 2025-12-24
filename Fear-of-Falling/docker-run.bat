@echo off
REM Helper script to run R scripts in Docker (Windows version)
REM Usage: docker-run.bat K11
REM        docker-run.bat all

setlocal enabledelayedexpansion

echo ================================
echo FOF R Analysis - Docker Runner
echo ================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not running. Please start Docker Desktop.
    exit /b 1
)

REM Build image if it doesn't exist
docker image inspect fof-r-analysis:latest >nul 2>&1
if errorlevel 1 (
    echo Building Docker image this may take 10-15 minutes...
    docker-compose build
    if errorlevel 1 (
        echo Error building Docker image
        exit /b 1
    )
    echo Image built successfully
    echo.
)

REM Check arguments
if "%~1"=="" (
    echo Usage: %~nx0 ^<script_name^>
    echo        %~nx0 all
    echo.
    echo Examples:
    echo   %~nx0 K11         # Run K11 only
    echo   %~nx0 all         # Run all K6-K16
    echo.
    exit /b 1
)

REM Handle "all" option
if "%~1"=="all" (
    echo Running all scripts K6-K16...
    echo.

    for /L %%k in (6,1,16) do (
        echo Running K%%k...
        docker-compose run --rm fof-runner Rscript R-scripts/K%%k/K%%k.R
        if errorlevel 1 (
            echo K%%k failed
        ) else (
            echo K%%k completed successfully
        )
        echo.
    )

    echo All scripts completed
    exit /b 0
)

REM Run single script
set SCRIPT=%~1

REM Add K prefix if not present
echo %SCRIPT% | findstr /b "K" >nul
if errorlevel 1 (
    set SCRIPT=K%SCRIPT%
)

echo Running %SCRIPT%...
docker-compose run --rm fof-runner Rscript R-scripts/%SCRIPT%/%SCRIPT%.R

if errorlevel 1 (
    echo %SCRIPT% failed
    exit /b 1
) else (
    echo %SCRIPT% completed successfully
)

echo.
echo Done!
