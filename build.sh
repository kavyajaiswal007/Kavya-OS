#!/usr/bin/env bash
# KAVYA OS - Host Build Orchestrator
# Builds KAVYA-OS.iso inside a reproducible Debian amd64 container

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "\n${BOLD}${CYAN}=== KAVYA OS: Host Build Orchestrator ===${NC}\n"

# Verify Docker daemon is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}Docker is not responding. Checking Colima...${NC}"
    if command -v colima >/dev/null 2>&1; then
        echo -e "${GREEN}Starting Colima runtime...${NC}"
        if ! colima start --cpu 4 --memory 6; then
            echo -e "${RED}Failed to start Colima.${NC}"
        fi
    fi
fi

if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker daemon is not accessible.${NC}"
    echo "Please ensure Colima or Docker Desktop is running."
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

mkdir -p build

echo -e "${GREEN}[1/2] Building kavya-builder Docker container image...${NC}"
docker build --platform linux/amd64 -t kavya-builder -f builder/Dockerfile .

echo -e "\n${GREEN}[2/2] Running build pipeline inside container...${NC}"
DOCKER_FLAGS="-i"
if [ -t 0 ]; then
    DOCKER_FLAGS="-it"
fi

docker run --rm $DOCKER_FLAGS \
    --privileged \
    --platform linux/amd64 \
    -v "${PROJECT_DIR}:/workspace" \
    kavya-builder

echo -e "\n${BOLD}${GREEN}Build finished successfully!${NC}"
echo -e "Output image: ${BOLD}${PROJECT_DIR}/build/KAVYA-OS.iso${NC}"
echo -e "To test on your Mac via QEMU, run: ${BOLD}./tests/test-iso.sh${NC} or ${BOLD}make test${NC}\n"
