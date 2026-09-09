#!/usr/bin/env bash
# cx doctor — waarom ziet cx geen projecten of sessies?
#
#   curl -fsSL https://raw.githubusercontent.com/ogerik/cx/main/doctor.sh | bash
#
# Verandert niets aan je systeem: leest alleen en print wat het vindt.

V_STAT=0; V_HIST=0; V_CODE=0; V_DEP=0; V_ENC=0; V_LINK=0

echo "=== 1. systeem ==="
uname -s; echo "bash: $BASH_VERSION"
echo
echo "=== 2. stat-variant (cx gebruikt de BSD-vorm) ==="
if stat -f '%m' /etc/hosts >/dev/null 2>&1; then
  echo "BSD/macOS stat  -> OK, cx werkt hier"
elif stat -c '%Y' /etc/hosts >/dev/null 2>&1; then
  echo "GNU/Linux stat  -> PROBLEEM: cx gebruikt 'stat -f' en vindt zo nooit sessies"; V_STAT=1
else
  echo "onbekende stat-variant -> PROBLEEM: cx kan geen tijdstempels lezen"; V_STAT=2
fi
echo
echo "=== 3. afhankelijkheden ==="
for d in claude fzf jq git; do
  if command -v "$d" >/dev/null 2>&1; then echo "  OK      $d"; else echo "  ONTBREEKT $d"; [ "$d" = git ] || V_DEP=1; fi
done
echo
echo "=== 4. claude-historie ==="
echo "CLAUDE_CONFIG_DIR = '${CLAUDE_CONFIG_DIR:-(niet gezet)}'"
PROJ="$HOME/.claude/projects"
if [ -d "$PROJ" ]; then
  echo "$PROJ bestaat, $(find "$PROJ" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') mappen, $(find "$PROJ" -name '*.jsonl' 2>/dev/null | wc -l | tr -d ' ') sessiebestanden"
else
  echo "$PROJ BESTAAT NIET -> cx kan niets vinden"; V_HIST=1
fi
echo
echo "=== 5. projectmap ==="
CODE="${CX_CODE_DIR:-$HOME/code}"
echo "CX_CODE_DIR = '${CX_CODE_DIR:-(niet gezet, dus ~/code)}'  ->  $CODE"
if [ -d "$CODE" ]; then
  echo "$CODE bestaat, $(find "$CODE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') mappen erin"
else
  echo "$CODE BESTAAT NIET -> cx toont een lege lijst. Waar staan je projecten wel?"; V_CODE=1
  ls -d "$HOME"/*/ 2>/dev/null | head -15
fi
echo
echo "=== 6. koppeling project -> historie (dit is wat cx doet) ==="
hit=0; miss=0; shown=0
[ -d "$CODE" ] && for dir in "$CODE"/*/; do
  [ -d "$dir" ] || continue
  p="${dir%/}"; enc="$PROJ/${p//\//-}"
  if [ -d "$enc" ]; then
    n=$(find "$enc" -maxdepth 1 -name '*.jsonl' 2>/dev/null | wc -l | tr -d ' ')
    hit=$((hit+1))
    [ "$shown" -lt 10 ] && { echo "  OK     $(basename "$p")  ($n sessies)"; shown=$((shown+1)); }
  else
    miss=$((miss+1))
    [ "$shown" -lt 10 ] && { echo "  GEEN   $(basename "$p")  -> zocht $(basename "$enc")"; shown=$((shown+1)); }
  fi
done
echo "  totaal: $hit met historie, $miss zonder"
[ "$hit" = 0 ] && V_LINK=1
echo

echo "=== 7. codeert cx paden hetzelfde als Claude Code? ==="
mis=0; tot=0
for d in "$PROJ"/*/; do
  [ -d "$d" ] || continue
  f=$(find "$d" -maxdepth 1 -name '*.jsonl' 2>/dev/null | head -1); [ -n "$f" ] || continue
  cwd=$(grep -ahm1 '"cwd":' "$f" 2>/dev/null | sed -n 's/.*"cwd":"\([^"]*\)".*/\1/p'); [ -n "$cwd" ] || continue
  tot=$((tot+1)); enc="${cwd//\//-}"
  if [ "$enc" != "$(basename "$d")" ]; then
    mis=$((mis+1))
    [ "$mis" -le 3 ] && { echo "  MISMATCH"; echo "    echte map : $(basename "$d")"; echo "    cx maakt  : $enc"; echo "    cwd       : $cwd"; }
  fi
done
echo "  gecontroleerd: $tot, mismatches: $mis"
[ "$mis" -gt 0 ] && V_ENC=1
echo
echo "=== 8. cx zelf ==="
command -v cx || echo "cx niet in PATH"
cx version 2>&1 | head -1
echo
echo "=== CONCLUSIE ==="
found=0
if [ "$V_STAT" != 0 ]; then
  if [ "$V_STAT" = 1 ]; then
    echo "* OORZAAK: cx gebruikt macOS-stat en jij draait Linux/WSL."
  else
    echo "* OORZAAK: je stat kent de vorm niet die cx gebruikt."
  fi
  echo "  Daardoor vindt cx nooit sessies, ongeacht wat er in je historie staat."
  echo "  Moet in cx zelf gerepareerd worden - stuur deze uitvoer naar Rinke."
  found=1
fi
if [ "$V_DEP" = 1 ]; then
  echo "* OORZAAK: een verplichte afhankelijkheid ontbreekt (zie 3). Installeer die eerst."
  found=1
fi
if [ "$V_HIST" = 1 ]; then
  echo "* OORZAAK: er is geen ~/.claude/projects. Start eerst een keer 'claude' in een"
  echo "  projectmap; cx toont alleen historie die Claude Code zelf heeft geschreven."
  [ -n "${CLAUDE_CONFIG_DIR:-}" ] && echo "  Let op: je hebt CLAUDE_CONFIG_DIR gezet; cx kijkt daar (nog) niet naar."
  found=1
fi
if [ "$V_CODE" = 1 ]; then
  echo "* OORZAAK: $CODE bestaat niet. cx kijkt alleen daar. Wijs het naar je eigen map:"
  echo "    echo 'export CX_CODE_DIR=\"\$HOME/jouw-map\"' >> ~/.zshrc && exec zsh"
  found=1
fi
if [ "$V_LINK" = 1 ] && [ "$V_CODE" = 0 ] && [ "$V_STAT" = 0 ]; then
  echo "* OORZAAK: geen enkel project in $CODE heeft een historiemap. Je hebt daar dus"
  echo "  nog nooit 'claude' gedraaid, of je draait het vanuit een andere map."
  found=1
fi
if [ "$V_ENC" = 1 ]; then
  echo "* OORZAAK: cx codeert projectpaden anders dan Claude Code (zie 7). Stuur deze"
  echo "  uitvoer naar Rinke - dit moet in cx gerepareerd worden."
  found=1
fi
[ "$found" = 0 ] && echo "Geen bekende oorzaak gevonden. Stuur de volledige uitvoer naar Rinke."
echo
echo "=== EINDE - plak alles hierboven terug ==="
