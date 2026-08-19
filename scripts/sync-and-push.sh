#!/usr/bin/env bash
set -e

# Warna output terminal
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN} freebuff-proxy: Sync, Build & Push Script${NC}"
echo -e "${CYAN}==========================================${NC}"

# ==============================================================================
# 1. AUTO-DETECT: Remote Origin, Username & Repo Name
# ==============================================================================
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
DETECTED_USER=""
DETECTED_REPO=""

if [ -n "$ORIGIN_URL" ]; then
    CLEAN_URL=$(echo "$ORIGIN_URL" | sed -E 's#^.*(github\.com[:/])##; s#\.git$##')
    DETECTED_USER=$(echo "$CLEAN_URL" | cut -d'/' -f1)
    DETECTED_REPO=$(echo "$CLEAN_URL" | cut -d'/' -f2)
fi

# Fallback jika tidak terdeteksi dari git
[ -z "$DETECTED_USER" ] && DETECTED_USER="ridhoarmand"
[ -z "$DETECTED_REPO" ] && DETECTED_REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")

# Default values
DOCKER_USER="${DOCKER_USER:-$DETECTED_USER}"
IMAGE_NAME="${IMAGE_NAME:-$DETECTED_REPO}"
TAG="latest"
FORCE=false
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# ==============================================================================
# 2. PARSING ARGUMEN
# ==============================================================================
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--user) DOCKER_USER="$2"; shift ;;
        -i|--image) IMAGE_NAME="$2"; shift ;;
        -t|--tag) TAG="$2"; shift ;;
        -f|--force) FORCE=true ;;
        -h|--help)
            echo -e "${CYAN}Penggunaan:${NC} ./scripts/sync-and-push.sh [options]"
            echo ""
            echo "Options:"
            echo "  -u, --user <username>  Override Docker Hub username (Terdeteksi: $DOCKER_USER)"
            echo "  -i, --image <name>     Override Image name (Terdeteksi: $IMAGE_NAME)"
            echo "  -t, --tag <tag>        Image tag (default: latest)"
            echo "  -f, --force            Paksa build & push meskipun tidak ada commit baru"
            echo "  -h, --help             Tampilkan bantuan ini"
            exit 0
            ;;
        *) echo -e "${RED}Unknown parameter: $1${NC}"; exit 1 ;;
    esac
    shift
done

# ==============================================================================
# 3. AUTO-DETECT: Container Engine (Docker vs Podman)
# ==============================================================================
CONTAINER_CLI=""
CONTAINER_BIN=""

if command -v docker.exe &> /dev/null; then
    CONTAINER_BIN="docker.exe"
    CONTAINER_CLI="docker"
elif command -v docker &> /dev/null; then
    CONTAINER_BIN="docker"
    CONTAINER_CLI="docker"
elif command -v podman.exe &> /dev/null; then
    CONTAINER_BIN="podman.exe"
    CONTAINER_CLI="podman"
elif command -v podman &> /dev/null; then
    CONTAINER_BIN="podman"
    CONTAINER_CLI="podman"
elif command -v where.exe &> /dev/null && where.exe podman &> /dev/null; then
    CONTAINER_BIN="$(where.exe podman | head -n 1 | tr -d '\r')"
    CONTAINER_CLI="podman"
elif command -v where.exe &> /dev/null && where.exe docker &> /dev/null; then
    CONTAINER_BIN="$(where.exe docker | head -n 1 | tr -d '\r')"
    CONTAINER_CLI="docker"
else
    echo -e "${RED}[✗] Error: 'podman' maupun 'docker' tidak ditemukan di sistem!${NC}"
    exit 1
fi

echo -e "${GRAY}[Auto-detect]${NC} Engine   : ${YELLOW}${CONTAINER_CLI}${NC} (${CONTAINER_BIN})"
echo -e "${GRAY}[Auto-detect]${NC} Registry : ${YELLOW}docker.io/${DOCKER_USER}/${IMAGE_NAME}:${TAG}${NC}"
echo -e "${GRAY}[Auto-detect]${NC} Branch   : ${YELLOW}${CURRENT_BRANCH}${NC}"
echo ""

# ==============================================================================
# 4. SINKRONISASI DENGAN UPSTREAM
# ==============================================================================
# Pastikan identitas git committer sudah ter-set
if [ -z "$(git config user.name 2>/dev/null || true)" ]; then
    git config user.name "$DOCKER_USER"
fi
if [ -z "$(git config user.email 2>/dev/null || true)" ]; then
    git config user.email "${DOCKER_USER}@users.noreply.github.com"
fi

if ! git remote | grep -q "^upstream$"; then
    echo -e "${YELLOW}[+] Menambahkan remote upstream (https://github.com/trefeon/freebuff-proxy.git)...${NC}"
    git remote add upstream https://github.com/trefeon/freebuff-proxy.git
fi

echo -e "${CYAN}[+] Mengambil update terbaru dari upstream...${NC}"
git fetch upstream "$CURRENT_BRANCH" 2>/dev/null || git fetch upstream main

UPSTREAM_TARGET="upstream/$CURRENT_BRANCH"
if ! git rev-parse --verify "$UPSTREAM_TARGET" &>/dev/null; then
    UPSTREAM_TARGET="upstream/main"
fi

BEHIND_COUNT=$(git rev-list HEAD.."$UPSTREAM_TARGET" --count 2>/dev/null || echo "0")

if [ "$BEHIND_COUNT" -gt 0 ] || [ "$FORCE" = true ]; then
    if [ "$BEHIND_COUNT" -gt 0 ]; then
        echo -e "${GREEN}[+] Ditemukan $BEHIND_COUNT commit baru dari upstream. Menyinkronkan...${NC}"
        git merge "$UPSTREAM_TARGET" --no-edit -m "sync: merge upstream $CURRENT_BRANCH" || {
            echo -e "${YELLOW}[!] Conflict terdeteksi saat merge normal. Mengambil versi upstream...${NC}"
            git merge --abort 2>/dev/null || true
            git reset --hard "$UPSTREAM_TARGET"
        }

        echo -e "${CYAN}[+] Mendorong (push) sinkronisasi ke fork GitHub (${CURRENT_BRANCH})...${NC}"
        git push origin "$CURRENT_BRANCH" --force
    else
        echo -e "${YELLOW}[!] Mode Force aktif. Melanjutkan build & push...${NC}"
    fi

    # Pastikan dependency Go selalu diperbarui agar build di container 100% offline & instan
    if command -v go &> /dev/null || command -v go.exe &> /dev/null; then
        echo -e "${CYAN}[+] Memperbarui modul Go lokal (go mod vendor)...${NC}"
        go mod vendor 2>/dev/null || true
    fi

    FULL_IMAGE_TAG="${DOCKER_USER}/${IMAGE_NAME}:${TAG}"
    REGISTRY_IMAGE_TAG="docker.io/${FULL_IMAGE_TAG}"

    echo -e "${GREEN}[+] Mem-build image untuk linux/amd64 (${CONTAINER_CLI}): ${YELLOW}${FULL_IMAGE_TAG}${NC}..."
    
    if [ "$CONTAINER_CLI" = "docker" ]; then
        if "$CONTAINER_BIN" buildx version &> /dev/null 2>&1; then
            "$CONTAINER_BIN" buildx build --platform linux/amd64 -t "$FULL_IMAGE_TAG" -t "$REGISTRY_IMAGE_TAG" --push .
        else
            "$CONTAINER_BIN" build --platform linux/amd64 -t "$FULL_IMAGE_TAG" -t "$REGISTRY_IMAGE_TAG" .
            "$CONTAINER_BIN" push "$REGISTRY_IMAGE_TAG"
        fi
    else
        # Podman build & push
        "$CONTAINER_BIN" build --platform linux/amd64 -t "$FULL_IMAGE_TAG" -t "$REGISTRY_IMAGE_TAG" .
        echo -e "${CYAN}[+] Mendorong image ke Docker Hub (${CONTAINER_CLI} push)...${NC}"
        "$CONTAINER_BIN" push "$REGISTRY_IMAGE_TAG"
    fi

    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN} Selesai! Image berhasil dipush ke Docker Hub:${NC}"
    echo -e "${YELLOW} ${REGISTRY_IMAGE_TAG}${NC}"
    echo -e "${GREEN} Silakan redeploy stack di Portainer VPS kamu.${NC}"
    echo -e "${GREEN}==========================================${NC}"
else
    echo -e "${GREEN}[✓] Repo lokal kamu sudah sinkron dengan upstream (tidak ada update baru).${NC}"
    echo -e "    Jika ingin tetap rebuild & push, jalankan dengan flag ${YELLOW}-f${NC} atau ${YELLOW}--force${NC}:"
    echo -e "    ${CYAN}./scripts/sync-and-push.sh -f${NC}"
fi
