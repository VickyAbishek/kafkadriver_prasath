#!/bin/bash

# PostgreSQL Connection Verification Script
# This script checks if PostgreSQL in Docker is accessible

echo "========================================"
echo "  PostgreSQL Connection Checker"
echo "========================================"
echo ""

DOCKER_COMPOSE_DIR="src/main/java/com/example/kafkadriver"

# Check if docker compose is running
echo "[1/3] Checking Docker containers status..."
if docker compose -f "$DOCKER_COMPOSE_DIR/docker-compose.yml" ps | grep -q "postgres_kafkadb"; then
    echo "✓ PostgreSQL container is running"
else
    echo "✗ PostgreSQL container is not running"
    echo "Starting containers..."
    docker compose -f "$DOCKER_COMPOSE_DIR/docker-compose.yml" up -d
    sleep 5
fi

echo ""
echo "[2/3] Testing connection using Docker exec..."
if docker exec postgres_kafkadb psql -U kafkauser -d kafkadb -c "SELECT 1 as connection_test;" 2>/dev/null; then
    echo "✓ Direct Docker connection successful"
else
    echo "✗ Direct Docker connection failed"
    exit 1
fi

echo ""
echo "[3/3] Testing connection from localhost..."

# Check if psql is installed locally
if ! command -v psql &> /dev/null; then
    echo "⚠ Skipping localhost test - psql client not installed locally"
    echo "  To install: brew install libpq && brew link --force libpq"
    echo "  Note: Docker exec connection (Step 2) succeeded, so PostgreSQL is working!"
else
    if PGPASSWORD=kafkapass123 psql -h localhost -U kafkauser -d kafkadb -c "SELECT 1 as connection_test;" 2>/dev/null; then
        echo "✓ Localhost connection successful"
        echo "  (This confirms the Docker port is properly exposed)"
    else
        echo "✗ Localhost connection failed"
        echo "  Possible causes:"
        echo "  • Port 5432 not exposed from Docker"
        echo "  • Firewall blocking connection"
        echo "  • Another service using port 5432"
    fi
fi

echo ""
echo "========================================"
echo "  Connection Check Complete"
echo "========================================"