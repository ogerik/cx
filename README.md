# cx

Een kleine, snelle launcher voor [Claude Code](https://claude.com/claude-code). Puur lokaal: `cx` leest alleen je bestaande `~/.claude/projects/` historie en start de `claude` CLI. Geen API, geen daemon, geen achtergrondproces.

Bedacht omdat alles in één map starten (en tien sessies tegelijk open hebben) onoverzichtelijk werd. `cx` geeft je per project terug *waar je was* en *waar het over ging*. Enter op een project opent de drill-in: de sessielijst van dát project, doorzoekbaar en met preview, zodat je elke sessie kunt hervatten en niet alleen de laatste.

## Wat het doet

```
★ webshop          main*            11u   Kortingscode op de checkout aanzetten
★ api-gateway      feat/rate-lim*   5d    Rate limiting toevoegen in een worktree
  dotfiles                          nu    Nieuwe zsh-prompt uitproberen
  admin-panel      master*          9m    Exportknop toevoegen aan het dashboard
```

Elke regel is een projectmap onder `~/code`, met:

- **★ favorieten** bovenaan, daarna gesorteerd op laatste activiteit;
- de **git-branch** (met `*` als er ongecommitte wijzigingen zijn);
- **wanneer** je er voor het laatst was;
- de **AI-titel** van de laatste sessie als label (Claude Code genereert die zelf; fallback: het eerste bericht);
- een **preview** met titel, metadata en het gespreksbegin naast de lijst.

Alles in kleur (★ geel, branch groen of rood bij wijzigingen, tijden gedimd); uit te zetten met `CX_COLOR=0`.

Enter op een project opent de **sessielijst van dat project** (nieuwste bovenaan, dus enter-enter = verder waar je was):

```
   11u geleden                wil je de open dag van de website afhalen
   2d geleden                 maak de header sticky op mobiel
   5d geleden   ↳feat-nav ·   probeer de nieuwe navigatie in een worktree
   1w geleden                 fix de sitemap voor /vacatures
```

Daar: `enter` = open die sessie, `ctrl-n` = nieuwe sessie, `ctrl-f` = full-text zoeken in de inhoud van dit project, `esc` = terug naar het projectoverzicht. Sessies uit **submappen en worktrees** onder het projectpad tellen mee en krijgen een `↳`-label; bij openen springt cx naar de juiste map. (De globale `cx sessions`, `cx grep` en `cx ask` kijken alleen naar de projectroots; submap-sessies vind je via de drill-in en `ctrl-f`.)

Bij het openen van een sessie print cx eerst een **recap-card**, die boven Claude Code in je scrollback blijft staan:

```
▌ webshop · main* · 11u geleden
▌ Kortingscode op de checkout aanzetten
▌
▌ Jij, als laatste:   en haal ook de banner van de home
▌ Claude bleef bij:   banner verwijderd, sitemap nog open…

→ open sessie in webshop
```

Uit te zetten met `CX_RECAP=0`.

## Commando's

| Commando | Wat het doet |
|---|---|
| `cx` | Projectoverzicht. Enter = drill-in naar de sessielijst van dat project, `ctrl-n` = verse sessie. |
| `cx sessions` | Alle recente sessies over álle projecten heen, met preview; opent een specifieke (`claude --resume`). |
| `cx sessions <proj>` | De sessielijst van één project (zelfde als enter in `cx`). |
| `cx grep <term>` | Full-text zoeken door al je sessie-transcripts; opent de gevonden sessie. |
| `cx ask "<vraag>"` | Semantisch zoeken: Claude kiest de best passende sessie(s) uit je historie, ook zonder exact trefwoord. Gebruikt je eigen Claude Code (`claude -p`), geen API. |
| `cx skills` | Doorzoekbaar overzicht van al je skills (user / plugins / project) met bron en SKILL.md-preview. |
| `cx pin <proj>` / `cx unpin <proj>` | Project als favoriet bovenaan zetten of losmaken. |
| `cx new [naam]` | Maakt `~/code/<naam>` met een kale `CLAUDE.md` en start claude. |
| `cx <projectnaam>` | Direct de sessielijst van dat project openen zonder menu. |
| `cx version` | Toon de versie. |
| `cx help` | Korte uitleg. |

## Installatie

```sh
git clone https://github.com/ogerik/cx.git ~/code/cx && ~/code/cx/install.sh
```

Daarna werkt `cx` overal in je shell. Het install-script zet een symlink
`~/.local/bin/cx` naar de gekloonde map, maakt de scripts in `bin/` uitvoerbaar en
controleert de afhankelijkheden. De repo blijft dus staan waar je hem kloont — verplaats
of verwijder hem niet, of draai `install.sh` daarna opnieuw.

**Staat `~/.local/bin` niet in je `PATH`?** Het install-script zegt het als dat zo is.
Toevoegen:

```sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && exec zsh
```

**Ergens anders installeren** (bijvoorbeeld in `/usr/local/bin`, voor alle gebruikers):

```sh
CX_BIN_DIR=/usr/local/bin ~/code/cx/install.sh
```

**Bijwerken:**

```sh
git -C ~/code/cx pull
```

De symlink wijst naar de repo, dus een `pull` is genoeg; `install.sh` opnieuw draaien
hoeft alleen als je de doelmap wilt wijzigen.

**Verwijderen:**

```sh
rm ~/.local/bin/cx && rm -rf ~/code/cx
```

Je sessie-historie blijft daarbij intact: die is van Claude Code zelf en staat in
`~/.claude/projects`. Alleen `~/.claude/cx-favorites` blijft als los bestandje achter.

### Afhankelijkheden

- [`claude`](https://claude.com/claude-code) (de Claude Code CLI)
- [`fzf`](https://github.com/junegunn/fzf) — fuzzy picker (`brew install fzf`)
- `jq` — JSON parsing (`brew install jq`)
- `git` — voor de branch-kolom (optioneel)

## Werkt het niet?

Ziet `cx` geen projecten of geen sessies, draai dan de diagnose. Die verandert niets,
leest alleen en zegt wat er mis is:

```sh
curl -fsSL https://raw.githubusercontent.com/ogerik/cx/main/doctor.sh | bash
```

Of, als je de repo al hebt: `~/code/cx/doctor.sh`.

Twee veelvoorkomende oorzaken die de diagnose vindt:

- **Je projecten staan niet in `~/code`.** Zet `CX_CODE_DIR` naar je eigen map. `cx`
  zegt dit sinds 1.6.0 ook zelf, met de juiste map er al bij ingevuld.
- **Je draait Linux of WSL.** `cx` leest tijdstempels met de macOS-vorm van `stat`;
  op Linux vindt het daardoor geen sessies. Nog niet opgelost.

## Instellingen

Te overschrijven via env-vars, bijvoorbeeld in je `~/.zshrc`:

| Env-var | Default | Wat |
|---|---|---|
| `CX_SKIP_PERMISSIONS` | `1` | Start claude altijd met `--dangerously-skip-permissions` (`0` = uit). |
| `CX_CODE_DIR` | `~/code` | Waar je projectmappen staan. |
| `CX_ASK_LIMIT` | `120` | Aantal recentste sessies dat `cx ask` aan Claude voorlegt. |
| `CX_COLOR` | `1` | Kleur in lijsten, preview en recap-card (`0` = uit). |
| `CX_RECAP` | `1` | Recap-card tonen vóór het openen van een sessie (`0` = uit). |
| `CX_ANIM` | `1` | Subtiele animaties: spinners bij wachten, recap-intro, sweeps (`0` = uit; ook automatisch uit als de output geen terminal is). |
| `CX_SESSION_COLOR` | `1` | Elke sessie krijgt een eigen prompt-bar kleur, per project (`0` = uit). |
| `CX_JOBS` | aantal cores (max 12) | Hoeveel projecten `cx` tegelijk uitleest bij het opbouwen van het overzicht. |

Bekijk alle animaties in één keer met `cx _animdemo`.

Favorieten worden bewaard in `~/.claude/cx-favorites` (één projectnaam per regel).

## Sessiekleuren

Met tien tabs open is de vraag niet *waar was ik*, maar *welke tab is dit*. `cx` geeft
daarom elke nieuwe sessie een kleur mee op de prompt-bar, gekoppeld aan het **project**
(git-root van je werkmap): `webshop` is altijd blauw, `api-gateway` altijd oranje.
Twee tabs in hetzelfde project delen dus een kleur; de naam op het promptvak — die
Claude Code zelf tijdens het gesprek bijwerkt — onderscheidt ze verder.

Dat gebeurt in twee scriptjes in `bin/`:

- `bin/claude-session-args` — bepaalt de extra vlaggen waarmee een sessie start
  (`--session-id` en een `/color <kleur>` prompt). Doet niets bij headless runs
  (`-p`, `--version`), bij `--continue` zonder id, of binnen een lopende sessie.
- `bin/session-color` — deelt de kleuren uit en houdt bij welke projecten open staan,
  in `~/.claude/project-colors` en `~/.claude/session-colors`. Draai
  `bin/session-color --list` voor een overzicht.

Zet `CLAUDE_SESSION_COLOR_MODE=session` voor een kleur per tab in plaats van per
project, of `CX_SESSION_COLOR=0` om het helemaal uit te zetten.

Wil je dat een kale `claude` (zonder `cx`) dezelfde kleur krijgt, zet dan deze wrapper
in je `~/.zshrc` — `install.sh` print hem met het juiste pad erin:

```sh
claude() {
  local -a extra=(); local line
  while IFS= read -r line; do [ -n "$line" ] && extra+=("$line"); done \
    < <("$HOME/code/cx/bin/claude-session-args" "$@" 2>/dev/null)
  command claude "$@" "${extra[@]}"
}
```

## Hoe het werkt

Per project moet `cx` drie dingen weten: de git-branch, of er ongecommitte wijzigingen
zijn, en de titel van de laatste sessie. Dat is een `git status` en het lezen van een
sessiebestand per project — tientallen milliseconden elk, wat bij honderd projecten
oploopt tot seconden. `cx` bouwt die regels daarom parallel op, in zoveel workers als je
cores hebt (max 12, te sturen met `CX_JOBS`). Bij minder dan acht projecten, of als
`xargs -P` ontbreekt, gebeurt het gewoon serieel.


Claude Code bewaart per werkmap een sessie-historie in `~/.claude/projects/<gecodeerd-pad>/`, als `.jsonl`-bestanden. `cx` leest die bestanden om labels, tijden en previews te tonen, en roept vervolgens gewoon `claude` aan in de juiste map met de juiste vlaggen. Niets meer.

Omdat het gecodeerde pad per exacte werkmap verschilt, horen sessies uit een submap of worktree bij een andere historiemap. De drill-in vindt die door historiemappen met dezelfde naamprefix te controleren op de `cwd` die in de jsonl staat: ligt die op of onder het projectpad, dan telt de sessie mee (en onderscheidt dat meteen `~/code/foo/bar` van buurproject `~/code/foo-bar`).

De labels komen uit de `ai-title`-regels die Claude Code zelf in de sessiebestanden schrijft (de laatste wint); de recap-card leest je laatste vraag en Claude's laatste antwoord uit de staart van de jsonl.

## Licentie

MIT — zie [LICENSE](LICENSE).
