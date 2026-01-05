#!/bin/bash

# Kafka Driver Quick Start Script for Unix/Linux/Mac
# This script automates the setup and startup process

echo "========================================"
echo "  Kafka Driver - Quick Start Script"
echo "========================================"
echo ""

# Check if Docker is running
echo "[1/4] Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "✓ Docker is installed: $DOCKER_VERSION"
else
    echo "✗ Docker is not installed or not in PATH"
    echo "Please install Docker from https://www.docker.com/get-started"
    exit 1
fi

# Navigate to docker-compose directory
DOCKER_COMPOSE_DIR="src/main/java/com/example/kafkadriver"
if [ -d "$DOCKER_COMPOSE_DIR" ]; then
    cd "$DOCKER_COMPOSE_DIR"
    echo "✓ Found docker-compose directory"
else
    echo "✗ docker-compose directory not found at $DOCKER_COMPOSE_DIR"
    exit 1
fi

# Start Docker containers
echo ""
echo "[2/4] Starting Docker containers..."
echo "  • Starting Zookeeper, Kafka, and PostgreSQL..."

docker-compose down -v 2>/dev/null
docker-compose up -d

# Wait for services to be ready
echo "  • Waiting for services to initialize..."
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    KAFKA_READY=$(docker-compose logs kafka 2>/dev/null | grep -c "started" || echo 0)
    POSTGRES_READY=$(docker-compose logs postgres_kafkadb 2>/dev/null | grep -c "ready to accept" || echo 0)

    if [ $KAFKA_READY -gt 0 ] && [ $POSTGRES_READY -gt 0 ]; then
        echo "✓ All services are ready"
        break
    fi

    echo "  • Waiting... (attempt $((ATTEMPT + 1))/$MAX_ATTEMPTS)"
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "⚠ Services might not be fully ready, but continuing..."
fi

# Verify containers are running
echo ""
echo "  Container Status:"
docker-compose ps | sed 's/^/    /'

# Return to project root
cd "../../../../../.."

# Check Maven
echo ""
echo "[3/4] Checking Maven installation..."
if command -v mvn &> /dev/null; then
    MVN_VERSION=$(mvn --version | head -1)
    echo "✓ Maven is installed: $MVN_VERSION"
else
    echo "✗ Maven is not installed or not in PATH"
    echo "Please install Maven from https://maven.apache.org/download.cgi"
    exit 1
fi

# Build project
echo ""
echo "[4/4] Building project..."
mvn clean install -DskipTests -q

if [ $? -eq 0 ]; then
    echo "✓ Project built successfully"
else
    echo "✗ Build failed"
    exit 1
fi

# Summary
echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "Next Steps:"
echo ""
echo "1. Start the Spring Boot application:"
echo "   mvn spring-boot:run"
echo ""
echo "2. Test the application:"
echo "   # Health check"
echo "   curl http://localhost:8080/api/messages/health"
echo ""
echo "   # Send a message"
echo "   curl -X POST http://localhost:8080/api/messages/produce \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"content\":\"Hello Kafka!\",\"sender\":\"You\",\"metadata\":\"test\"}'"
echo ""
echo "3. View all processed messages:"
echo "   curl http://localhost:8080/api/messages/processed"
echo ""
echo "4. View documentation:"
echo "   • README.md - Project overview and API documentation"
echo "   • TESTING-GUIDE.md - Comprehensive testing scenarios"
echo "   • Kafka-Driver-Postman-Collection.json - Postman collection"
echo ""
echo "Services Running:"
echo "  • Kafka: localhost:9092"
echo "  • Zookeeper: localhost:2181"
echo "  • PostgreSQL: localhost:5432 (kafkauser/kafkapass123)"
echo "  • Spring Boot: localhost:8080"
echo ""
echo "Stop services:"
echo "   docker-compose -f src/main/java/com/example/kafkadriver/docker-compose.yml down"
echo ""

