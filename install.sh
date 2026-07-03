#!/usr/bin/env bash
# Thin installer entrypoint.

set -euo pipefail
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/core/bash" && pwd)/bootstrap.sh"
# shellcheck source=/dev/null
source "$AURA_REPO_DIR/features/install/main.sh"
