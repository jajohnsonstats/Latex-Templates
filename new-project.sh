#!/usr/bin/env bash
# ------------------------------------------------------------------
# Start a new LaTeX project from one of the templates in this repo.
#
#   bash new-project.sh <type> <destination> [main-name]
#
#   bash new-project.sh article ~/research/minibatch-gp
#   bash new-project.sh poster /mnt/c/Users/jacob/Research/jsm-poster
#   bash new-project.sh poster 'C:\Users\jacob\Research\jsm-poster' poster
#
# What it does:
#   1. copies <type>/ to <destination>, minus build files
#   2. renames *_template.tex to <main-name>.tex (default: main.tex)
#   3. copies a SNAPSHOT of the shared files into the project:
#        common/                    -> every project
#        beamer/ and institutions/  -> beamer-class projects (posters, talks)
#   4. creates an empty references.bib and a .gitignore
#
# The snapshot is deliberate: TeX looks in the project folder before the
# MiKTeX root, so the project keeps compiling exactly as it did even after
# you edit the shared files, and coauthors/Overleaf/arXiv get everything.
# ------------------------------------------------------------------

## Failure Mode
set -euo pipefail

## Get usage/help text
usage() {
  sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

## Error display options
die() { echo "Error: $*" >&2; exit 1; }

## Get input variables
[[ $# -ge 2 && $# -le 3 ]] || usage
type=$1
dest=$2
main=${3:-main}

## Build correct filepaths
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
shared="$repo/shared/tex/latex/jaj"
template="$repo/$type"

## Accept Windows paths (C:\... or C:/...) by converting them for WSL
if [[ "$dest" =~ ^[A-Za-z]:[\\/] ]]; then
  command -v wslpath >/dev/null 2>&1 || die "'$dest' looks like a Windows path, but wslpath is not available."
  dest="$(wslpath -u "$dest")"
fi

# Checks -----------------------------------------------------------
## Check that the template directory exists
if [[ ! -d "$template" ]]; then
  available=$(cd "$repo" && for d in */; do
    if ls "$d"*_template.tex >/dev/null 2>&1; then printf '%s ' "${d%/}"; fi
  done)
  die "no template folder '$type'. Available: $available"
fi

## Make sure that there is only one template file in the folder
shopt -s nullglob
templates=("$template"/*_template.tex)
shopt -u nullglob
[[ ${#templates[@]} -eq 1 ]] || die "expected exactly one *_template.tex in $template, found ${#templates[@]}."
template_tex=$(basename "${templates[0]}")

## Check that the destination directory is empty (or doesn't exist)
if [[ -e "$dest" && -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
  die "'$dest' already exists and is not empty."
fi

# Copy Template ----------------------------------------------------
## Create new directory and copy the template into it
mkdir -p "$dest"
cp -R "$template"/. "$dest"/

## Remove build files, the template's compiled PDF, and folder placeholders
find "$dest" -type f \( \
    -name '*.aux' -o -name '*.bbl' -o -name '*.bcf' -o -name '*.blg' -o \
    -name '*.dvi' -o -name '*.fdb_latexmk' -o -name '*.fls' -o -name '*.lof' -o \
    -name '*.log' -o -name '*.lot' -o -name '*.nav' -o -name '*.out' -o \
    -name '*.run.xml' -o -name '*.snm' -o -name '*.synctex*' -o -name '*.toc' -o \
    -name '*.vrb' -o -name '*.xdv' -o -name '*.bak' -o -name '.gitkeep' \
  \) -delete
rm -f "$dest/${template_tex%.tex}.pdf"

## Rename .tex file to main (or specified filename)
mv "$dest/$template_tex" "$dest/$main.tex"

# Snapshot Shared Files --------------------------------------------
## Check if the template is for beamer
folders=(common)
is_beamer=false
if grep -Eq '^[^%]*\\documentclass(\[[^]]*\])?\{beamer\}' "$dest/$main.tex"; then
  folders+=(beamer institutions)
  is_beamer=true
fi

## Copy shared folders
## Files in subfolders (e.g. institutions/uwmadison/) are copied flat into the project root, since TeX looks there first.
copied=()
for f in "${folders[@]}"; do
  [[ -d "$shared/$f" ]] || continue
  while IFS= read -r -d '' file; do
    name=$(basename "$file")
    [[ -e "$dest/$name" ]] && die "two shared files are both named '$name'; rename one."
    cp "$file" "$dest/"
    version=$(grep -Eo '\\Provides(Package|File)\{[^}]*\}\[[^]]*\]' "$file" | head -n1 | sed -E 's/.*\[(.*)\]/\1/' || true)
    copied+=("  $name${version:+  [$version]}")
  done < <(find "$shared/$f" -type f ! -name '.gitkeep' -print0 | sort -z)
done

## Warn (beamer projects only) about institution logos named but missing
missing=()
$is_beamer && for def in "$dest"/jaj-inst-*.def; do
  [[ -f "$def" ]] || continue
  while IFS= read -r logo; do
    if [[ -n "$logo" && ! -f "$dest/$logo" ]]; then
      missing+=("  $logo  (named in $(basename "$def"))")
    fi
  done < <(sed -nE 's/^\\def\\jajInstLogo(Wide)?\{([^}]*)\}.*/\2/p' "$def")
done

## Create an empty references.bib and .gitignore
[[ -f "$dest/references.bib" ]] || printf '%% references.bib\n%% Bibliography for this project.\n' > "$dest/references.bib"
[[ -f "$repo/.gitignore" ]] && cp "$repo/.gitignore" "$dest/.gitignore"

# Summary ----------------------------------------------------------
echo
echo "Created $type project at $dest"
echo "  Main file: $main.tex"
echo "  Shared files (snapshot):"
printf '%s\n' "${copied[@]}"
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "  Logo files not found (it still builds, without the logo):"
  printf '%s\n' "${missing[@]}"
fi
echo
echo "Open $main.tex in TeXstudio and press F5 (Build & View)."
