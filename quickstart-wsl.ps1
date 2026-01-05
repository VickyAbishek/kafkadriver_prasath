#!/usr/bin/env pwsh

# Kafka Driver Quick Start Script for Windows with WSL Support
# This script detects WSL and uses it if available, otherwise uses native Windows approach

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Kafka Driver - Quick Start Script" -ForegroundColor Cyan
Write-Host "  (Windows with WSL Support)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if WSL is available
Write-Host "[1/5] Checking for WSL installation..." -ForegroundColor Yellow
$wslAvailable = $false
$wslDockerAvailable = $false

try {
    $wslVersion = wsl --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ WSL is installed" -ForegroundColor Green
        $wslAvailable = $true

        # Check for Docker in WSL
        try {
            $dockerInWSL = wsl docker --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Docker found in WSL" -ForegroundColor Green
                $wslDockerAvailable = $true
            }
        } catch {
            Write-Host "✗ Docker not found in WSL, will check native Docker" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "✗ WSL not found, using native Windows approach" -ForegroundColor Yellow
}

# Check for native Docker if WSL Docker not available
if (-not $wslDockerAvailable) {
    Write-Host "[1/5] Checking Docker installation (native)..." -ForegroundColor Yellow
    try {
        $dockerVersion = docker --version
        Write-Host "✓ Docker is installed (native): $dockerVersion" -ForegroundColor Green
        $dockerAvailable = $true
    } catch {
        Write-Host "✗ Docker is not installed or not in PATH" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install one of the following:" -ForegroundColor Yellow
        Write-Host "  1. WSL: https://learn.microsoft.com/windows/wsl/install" -ForegroundColor Cyan
        Write-Host "  2. Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
        Write-Host ""
        exit 1
    }
} else {
    $dockerAvailable = $true
}

Write-Host ""

# Check Maven
Write-Host "[2/5] Checking Maven installation..." -ForegroundColor Yellow
try {
    $mvnVersion = mvn --version | Select-Object -First 1
    Write-Host "✓ Maven is installed: $mvnVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Maven is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Maven from https://maven.apache.org/download.cgi" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""

# Navigate to docker-compose directory
Write-Host "[3/5] Locating docker-compose..." -ForegroundColor Yellow
$dockerComposeDir = "src\main\java\com\example\kafkadriver"

if (Test-Path "$dockerComposeDir\docker-compose.yml") {
    Write-Host "✓ Found docker-compose.yml" -ForegroundColor Green
} else {
    Write-Host "✗ docker-compose.yml not found at $dockerComposeDir" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host ""

# Start Docker containers using appropriate method
Write-Host "[4/5] Starting Docker containers..." -ForegroundColor Yellow

if ($wslAvailable -and $wslDockerAvailable) {
    Write-Host "Using WSL to run Docker..." -ForegroundColor Cyan

    # Get current directory and convert to WSL path
    $currentPath = (Get-Location).Path
    $wslPath = wsl wslpath -a $currentPath 2>$null
    $wslComposeDir = "$wslPath/$dockerComposeDir".Replace('\', '/')

    # Run docker-compose in WSL
    Write-Host "  • Stopping existing containers..." -ForegroundColor Gray
    wsl bash -c "cd '$wslComposeDir' && docker-compose down -v 2>/dev/null" | Out-Null

    Write-Host "  • Starting new containers..." -ForegroundColor Gray
    wsl bash -c "cd '$wslComposeDir' && docker-compose up -d" | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to start containers via WSL" -ForegroundColor Red
        Write-Host ""
        exit 1
    }

    Write-Host "  • Waiting for services to initialize (via WSL)..." -ForegroundColor Gray
    wsl bash -c "cd '$wslComposeDir' && for i in {1..30}; do KAFKA_READY=\$(docker-compose logs kafka 2>/dev/null | grep -c 'started' || echo 0); POSTGRES_READY=\$(docker-compose logs postgres_kafkadb 2>/dev/null | grep -c 'ready to accept' || echo 0); if [ \$KAFKA_READY -gt 0 ] && [ \$POSTGRES_READY -gt 0 ]; then echo 'Services ready'; break; fi; echo \"Attempt \$i/30...\"; sleep 2; done" | Out-Null

    Write-Host "✓ Services started (WSL)" -ForegroundColor Green

    Write-Host ""
    Write-Host "  Container Status:" -ForegroundColor Gray
    wsl bash -c "cd '$wslComposeDir' && docker-compose ps" | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
} else {
    Write-Host "Using native Docker to run containers..." -ForegroundColor Cyan

    Write-Host "  • Stopping existing containers..." -ForegroundColor Gray
    Push-Location $dockerComposeDir
    docker-compose down -v 2>$null | Out-Null

    Write-Host "  • Starting new containers..." -ForegroundColor Gray
    docker-compose up -d | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to start containers" -ForegroundColor Red
        Pop-Location
        Write-Host ""
        exit 1
    }

    Write-Host "  • Waiting for services to initialize..." -ForegroundColor Gray
    $maxAttempts = 30
    $attempt = 0

    while ($attempt -lt $maxAttempts) {
        $kafkaReady = docker-compose logs kafka 2>$null | Select-String "started" -Quiet
        $postgresReady = docker-compose logs postgres_kafkadb 2>$null | Select-String "ready to accept" -Quiet

        if ($kafkaReady -and $postgresReady) {
            Write-Host "✓ Services ready" -ForegroundColor Green
            break
        }

        Write-Host "    Attempt $($attempt + 1)/$maxAttempts..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
        $attempt++
    }

    Write-Host ""
    Write-Host "  Container Status:" -ForegroundColor Gray
    docker-compose ps | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }

    Pop-Location
}

Write-Host ""

# Build project
Write-Host "[5/5] Building project..." -ForegroundColor Yellow
mvn clean install -DskipTests -q

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Project built successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Build failed" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Start the Spring Boot application:" -ForegroundColor White
Write-Host "   mvn spring-boot:run" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Test the application:" -ForegroundColor White
Write-Host "   # Health check" -ForegroundColor Gray
Write-Host "   curl http://localhost:8080/api/messages/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "   # Send a message" -ForegroundColor Gray
Write-Host '   curl -X POST http://localhost:8080/api/messages/produce \' -ForegroundColor Cyan
Write-Host '     -H "Content-Type: application/json" \' -ForegroundColor Cyan
Write-Host '     -d ''{"content":"Hello Kafka!","sender":"You","metadata":"test"}''' -ForegroundColor Cyan
Write-Host ""
Write-Host "3. View all processed messages:" -ForegroundColor White
Write-Host "   curl http://localhost:8080/api/messages/processed" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. View documentation:" -ForegroundColor White
Write-Host "   • README.md - Project overview and API documentation" -ForegroundColor Gray
Write-Host "   • TESTING-GUIDE.md - Comprehensive testing scenarios" -ForegroundColor Gray
Write-Host "   • Kafka-Driver-Postman-Collection.json - Postman collection" -ForegroundColor Gray
Write-Host ""
Write-Host "Services Running:" -ForegroundColor Yellow

if ($wslAvailable -and $wslDockerAvailable) {
    Write-Host "  • Kafka: localhost:9092 (via WSL)" -ForegroundColor Cyan
    Write-Host "  • Zookeeper: localhost:2181 (via WSL)" -ForegroundColor Cyan
    Write-Host "  • PostgreSQL: localhost:5432 (via WSL, kafkauser/kafkapass123)" -ForegroundColor Cyan
} else {
    Write-Host "  • Kafka: localhost:9092" -ForegroundColor Cyan
    Write-Host "  • Zookeeper: localhost:2181" -ForegroundColor Cyan
    Write-Host "  • PostgreSQL: localhost:5432 (kafkauser/kafkapass123)" -ForegroundColor Cyan
}

Write-Host "  • Spring Boot: localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stop services:" -ForegroundColor Yellow

if ($wslAvailable -and $wslDockerAvailable) {
    Write-Host '   wsl bash -c "cd [path]/src/main/java/com/example/kafkadriver && docker-compose down"' -ForegroundColor Cyan
} else {
    Write-Host "   docker-compose -f src/main/java/com/example/kafkadriver/docker-compose.yml down" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Environment: " -ForegroundColor Yellow -NoNewline

if ($wslAvailable -and $wslDockerAvailable) {
    Write-Host "WSL with Docker" -ForegroundColor Green
} else {
    Write-Host "Native Windows" -ForegroundColor Green
}

Write-Host ""

