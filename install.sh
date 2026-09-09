#!/usr/bin/env bash
# Installeer cx: symlink het script in ~/.local/bin en controleer afhankelijkheden.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${CX_BIN_DIR:-$HOME/.local/bin}"
TARGET="$BIN_DIR/cx"

mkdir -p "$BIN_DIR"
ln -sf "$REPO_DIR/cx" "$TARGET"
echo "✓ symlink: $TARGET -> $REPO_DIR/cx"

# cx roept deze twee zelf aan vanuit bin/; na een kloon staat het x-bit er niet
# altijd op.
chmod +x "$REPO_DIR/bin/claude-session-args" "$REPO_DIR/bin/session-color" 2>/dev/null || true

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "! let op: $BIN_DIR staat niet in je PATH. Voeg toe aan ~/.zshrc:"
     echo "    export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

echo ""
echo "Afhankelijkheden:"
for dep in claude fzf jq git; do
  if command -v "$dep" >/dev/null 2>&1; then
    echo "  ✓ $dep"
  else
    echo "  ✗ $dep ontbreekt$( [ "$dep" = git ] && echo ' (optioneel, voor git-kolom)' )"
  fi
done

echo ""
echo "Optioneel: geef ook een kale \`claude\` dezelfde sessiekleur, met in ~/.zshrc:"
echo "    claude() {"
echo "      local -a extra=(); local line"
echo "      while IFS= read -r line; do [ -n \"\$line\" ] && extra+=(\"\$line\"); done \\"
echo "        < <(\"$REPO_DIR/bin/claude-session-args\" \"\$@\" 2>/dev/null)"
echo "      command claude \"\$@\" \"\${extra[@]}\""
echo "    }"

echo ""
echo "Klaar. Start een nieuwe shell (of 'rehash' in zsh) en typ: cx"
