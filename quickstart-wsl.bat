@echo off
REM Kafka Driver Quick Start Script for Windows with WSL Support
REM This script detects WSL and uses it if available, otherwise uses native Windows approach

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   Kafka Driver - Quick Start Script
echo   (Windows with WSL Support)
echo ========================================
echo.

REM Check if WSL is available
echo [1/5] Checking for WSL installation...
wsl --version >nul 2>&1
if %errorlevel% equ 0 (
    echo + WSL is installed
    set USE_WSL=1

    REM Check for Docker in WSL
    wsl docker --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo + Docker found in WSL
        set USE_WSL_DOCKER=1
    ) else (
        echo - Docker not found in WSL, will check native Docker
        set USE_WSL_DOCKER=0
    )
) else (
    echo - WSL not found, using native Windows approach
    set USE_WSL=0
)

REM Check for native Docker if WSL Docker not available
if %USE_WSL_DOCKER% equ 0 (
    echo [1/5] Checking Docker installation (native)...
    docker --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo + Docker is installed (native)
        set DOCKER_AVAILABLE=1
    ) else (
        echo - Docker is not installed or not in PATH
        echo.
        echo Please install one of the following:
        echo   1. WSL: https://learn.microsoft.com/windows/wsl/install
        echo   2. Docker Desktop: https://www.docker.com/products/docker-desktop
        echo.
        pause
        exit /b 1
    )
) else (
    set DOCKER_AVAILABLE=1
)

echo.

REM Check for Maven
echo [2/5] Checking Maven installation...
mvn --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%A in ('mvn --version ^| findstr "Apache"') do echo + %%A
    set MAVEN_AVAILABLE=1
) else (
    echo - Maven is not installed or not in PATH
    echo.
    echo Please install Maven from https://maven.apache.org/download.cgi
    echo.
    pause
    exit /b 1
)

echo.

REM Navigate to docker-compose directory
echo [3/5] Locating docker-compose...
set DOCKER_COMPOSE_DIR=src\main\java\com\example\kafkadriver

if exist "%DOCKER_COMPOSE_DIR%\docker-compose.yml" (
    echo + Found docker-compose.yml
) else (
    echo - docker-compose.yml not found at %DOCKER_COMPOSE_DIR%
    echo.
    pause
    exit /b 1
)

echo.

REM Start Docker containers using appropriate method
echo [4/5] Starting Docker containers...

if %USE_WSL% equ 1 (
    echo Using WSL to run Docker...

    REM Convert Windows path to WSL path
    for /f "tokens=*" %%A in ('wsl wslpath -a "%cd%"') do set WSL_PATH=%%A

    REM Run docker-compose in WSL
    wsl bash -c "cd !WSL_PATH!/%DOCKER_COMPOSE_DIR% && docker-compose down -v 2>/dev/null; docker-compose up -d"

    if %errorlevel% neq 0 (
        echo - Failed to start containers via WSL
        echo.
        pause
        exit /b 1
    )

    echo + Waiting for services to initialize (via WSL)...
    wsl bash -c "cd !WSL_PATH!/%DOCKER_COMPOSE_DIR% && for i in {1..30}; do KAFKA_READY=$(docker-compose logs kafka 2>/dev/null | grep -c 'started' || echo 0); POSTGRES_READY=$(docker-compose logs postgres_kafkadb 2>/dev/null | grep -c 'ready to accept' || echo 0); if [ $KAFKA_READY -gt 0 ] && [ $POSTGRES_READY -gt 0 ]; then echo 'Services ready'; break; fi; echo \"Attempt $i/30...\"; sleep 2; done"
) else (
    echo Using native Docker to run containers...

    pushd "%DOCKER_COMPOSE_DIR%"
    docker-compose down -v 2>nul
    docker-compose up -d

    if %errorlevel% neq 0 (
        echo - Failed to start containers
        echo.
        pause
        exit /b 1
    )

    echo + Waiting for services to initialize...
    setlocal
    for /l %%i in (1,1,30) do (
        docker-compose logs kafka 2>nul | findstr "started" >nul
        set KAFKA_CHECK=!errorlevel!
        docker-compose logs postgres_kafkadb 2>nul | findstr "ready to accept" >nul
        set POSTGRES_CHECK=!errorlevel!

        if !KAFKA_CHECK! equ 0 if !POSTGRES_CHECK! equ 0 (
            echo + Services ready
            goto services_ready
        )
        echo   Attempt %%i/30...
        timeout /t 2 /nobreak >nul
    )
    :services_ready
    endlocal
    popd
)

echo.
echo + Container Status:
if %USE_WSL% equ 1 (
    wsl bash -c "cd !WSL_PATH!/%DOCKER_COMPOSE_DIR% && docker-compose ps"
) else (
    pushd "%DOCKER_COMPOSE_DIR%"
    docker-compose ps
    popd
)

echo.

REM Build project
echo [5/5] Building project...
mvn clean install -DskipTests -q

if %errorlevel% equ 0 (
    echo + Project built successfully
) else (
    echo - Build failed
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Setup Complete!
echo ========================================
echo.
echo Next Steps:
echo.
echo 1. Start the Spring Boot application:
echo    mvn spring-boot:run
echo.
echo 2. Test the application:
echo    # Health check
echo    curl http://localhost:8080/api/messages/health
echo.
echo    # Send a message
echo    curl -X POST http://localhost:8080/api/messages/produce ^
echo      -H "Content-Type: application/json" ^
echo      -d "{\"content\":\"Hello Kafka!\",\"sender\":\"You\",\"metadata\":\"test\"}"
echo.
echo 3. View all processed messages:
echo    curl http://localhost:8080/api/messages/processed
echo.
echo 4. View documentation:
echo    - README.md - Project overview and API documentation
echo    - TESTING-GUIDE.md - Comprehensive testing scenarios
echo    - Kafka-Driver-Postman-Collection.json - Postman collection
echo.
echo Services Running:
if %USE_WSL% equ 1 (
    echo   - Kafka: localhost:9092 (via WSL)
    echo   - Zookeeper: localhost:2181 (via WSL)
) else (
    echo   - Kafka: localhost:9092
    echo   - Zookeeper: localhost:2181
)
echo   - PostgreSQL: localhost:5432 (kafkauser/kafkapass123)
echo   - Spring Boot: localhost:8080
echo.
echo Stop services:
if %USE_WSL% equ 1 (
    echo   wsl bash -c "cd [path]/src/main/java/com/example/kafkadriver && docker-compose down"
) else (
    echo   docker-compose -f src/main/java/com/example/kafkadriver/docker-compose.yml down
)
echo.

pause

