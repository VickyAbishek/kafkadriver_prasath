#!/usr/bin/env pwsh

# Kafka Driver Quick Start Script for Windows PowerShell
# This script automates the setup and startup process

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Kafka Driver - Quick Start Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "[1/4] Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker is installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    exit 1
}

# Navigate to docker-compose directory
$dockerComposeDir = "src\main\java\com\example\kafkadriver"
if (Test-Path $dockerComposeDir) {
    Set-Location $dockerComposeDir
    Write-Host "✓ Found docker-compose directory" -ForegroundColor Green
} else {
    Write-Host "✗ docker-compose directory not found at $dockerComposeDir" -ForegroundColor Red
    exit 1
}

# Start Docker containers
Write-Host ""
Write-Host "[2/4] Starting Docker containers..." -ForegroundColor Yellow
Write-Host "  • Starting Zookeeper, Kafka, and PostgreSQL..." -ForegroundColor Gray

docker-compose down -v 2>$null | Out-Null
docker-compose up -d

# Wait for services to be ready
Write-Host "  • Waiting for services to initialize..." -ForegroundColor Gray
$maxAttempts = 30
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $kafkaReady = docker-compose logs kafka 2>$null | Select-String "started" -Quiet
    $postgresReady = docker-compose logs postgres_kafkadb 2>$null | Select-String "ready to accept" -Quiet

    if ($kafkaReady -and $postgresReady) {
        Write-Host "✓ All services are ready" -ForegroundColor Green
        break
    }

    Write-Host "  • Waiting... (attempt $($attempt + 1)/$maxAttempts)" -ForegroundColor Gray
    Start-Sleep -Seconds 2
    $attempt++
}

if ($attempt -eq $maxAttempts) {
    Write-Host "⚠ Services might not be fully ready, but continuing..." -ForegroundColor Yellow
}

# Verify containers are running
Write-Host ""
Write-Host "  Container Status:" -ForegroundColor Gray
docker-compose ps | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }

# Return to project root
Set-Location "..\..\..\..\..\..\.."

# Check Maven
Write-Host ""
Write-Host "[3/4] Checking Maven installation..." -ForegroundColor Yellow
try {
    $mvnVersion = mvn --version | Select-Object -First 1
    Write-Host "✓ Maven is installed: $mvnVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Maven is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Maven from https://maven.apache.org/download.cgi" -ForegroundColor Red
    exit 1
}

# Build project
Write-Host ""
Write-Host "[4/4] Building project..." -ForegroundColor Yellow
mvn clean install -DskipTests -q

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Project built successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Build failed" -ForegroundColor Red
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
Write-Host "  • Kafka: localhost:9092" -ForegroundColor Cyan
Write-Host "  • Zookeeper: localhost:2181" -ForegroundColor Cyan
Write-Host "  • PostgreSQL: localhost:5432 (kafkauser/kafkapass123)" -ForegroundColor Cyan
Write-Host "  • Spring Boot: localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stop services:" -ForegroundColor Yellow
Write-Host "   docker-compose -f src/main/java/com/example/kafkadriver/docker-compose.yml down" -ForegroundColor Cyan
Write-Host ""

