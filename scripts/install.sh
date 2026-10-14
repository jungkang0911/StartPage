#!/bin/sh
# Install / update StartPage on macOS / Linux (page only; the PowerShell integrations are Windows-oriented).
#   sh scripts/install.sh                 # -> ~/StartPage
#   sh scripts/install.sh ~/Sites/start   # custom folder
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/jungkang0911/StartPage/main/scripts/install.sh | sh
set -e
TARGET="${1:-${STARTPAGE_TARGET:-$HOME/StartPage}}"
REPO="${STARTPAGE_REPO:-jungkang0911/StartPage}"
BRANCH="${STARTPAGE_BRANCH:-main}"

ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd || true)"
if [ ! -f "$ROOT/assets/index.html" ]; then
  # Piped from curl: download the source first
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" | tar -xz -C "$TMP"
  ROOT="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
fi

mkdir -p "$TARGET"
[ -f "$TARGET/index.html" ] && cp "$TARGET/index.html" "$TARGET/index.html.bak"
cp "$ROOT/assets/index.html" "$TARGET/index.html"
[ -f "$TARGET/options.js" ] || cp "$ROOT/examples/options.example.js" "$TARGET/options.js"

echo "Installed: $TARGET/index.html"
echo "URL: file://$TARGET/index.html"
