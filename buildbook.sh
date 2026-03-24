#!/usr/bin/env bash
# ============================================================
# buildbook.sh - Pure Bash Book Builder
# ============================================================
# Description: A lightweight, pure-Bash toolchain for publishing professional PDFs and EPUBs directly from Markdown.
# Author:      Todd Emerson (todd@toddemerson.com)
# Created:     2026-03-24
# Version:     1.1.0
# License:     BSL 1.1
#
# Usage:       ./buildbook.sh <manuscript.md> [format] [options]
# Dependencies: Requires pandoc texlive-xetex texlive-latex-extra texlive-fonts-extra bc (fonts-linuxlibertine)
#
#!/usr/bin/env bash
# ============================================================
# buildbook - Pure Bash Book Builder with Gutter Validation
# ============================================================
set -e

VERSION="1.1.0"

# --- Default Variables ---
FORMAT="all"
MANUSCRIPT=""
CONFIG_FILE="buildbook.conf"
METADATA_FILE="metadata.yaml"
OUTPUT_FILE=""

# --- Status & Version Check ---
check_status() {
    echo "BuildBook Version: $VERSION"
    echo "------------------------------------------------------------"
    echo "System Dependency Check:"
    local DEPS=("pandoc" "xelatex" "bc" "wget")
    local MISSING=0

    for dep in "${DEPS[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo "  [OK] $dep is installed"
        else
            echo "  [!!] $dep is MISSING"
            MISSING=$((MISSING + 1))
        fi
    done

    echo "------------------------------------------------------------"
    if [ "$MISSING" -eq 0 ]; then
        echo "Status: System is ready to build books."
    else
        echo "Status: $MISSING dependency/dependencies missing. Please check the README."
    fi
    exit 0
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--version) check_status ;;
        -c|--config) CONFIG_FILE="$2"; shift ;;
        -o|--output) OUTPUT_FILE="$2"; shift ;;
        epub|pdf|all) FORMAT="$1" ;;
        *.md) MANUSCRIPT="$1" ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$MANUSCRIPT" ] || [ ! -f "$MANUSCRIPT" ]; then
    echo "Usage: buildbook manuscript.md [epub|pdf|all] [-c buildbook.conf] [-o output_path] [-v]"
    exit 1
fi

# --- Load Configuration ---
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Deriving defaults if config variables are missing
PAPER_W=${PAPER_W:-"6in"}
PAPER_H=${PAPER_H:-"9in"}
FONT_SIZE=${FONT_SIZE:-"11pt"}
MAIN_FONT=${MAIN_FONT:-"Linux Libertine O"}
MARGIN_LEFT=${MARGIN_LEFT:-"0.75in"}
OUTPUT_DIR="out"
BASENAME=$(basename "$MANUSCRIPT" .md)

# --- Page Count & Gutter Validator ---
validate_gutter() {
    local chars=$(wc -m < "$MANUSCRIPT")
    local imgs=$(grep -c "!\[" "$MANUSCRIPT")
    local est=$(( (chars / 1600) + (imgs / 2) + 4 ))
    
    local req="0.25"
    if [ "$est" -ge 25 ]  && [ "$est" -le 75 ];  then req="0.375"; fi
    if [ "$est" -ge 76 ]  && [ "$est" -le 150 ]; then req="0.5"; fi
    if [ "$est" -ge 151 ] && [ "$est" -le 300 ]; then req="0.625"; fi
    if [ "$est" -ge 301 ] && [ "$est" -le 500 ]; then req="0.75"; fi
    if [ "$est" -ge 501 ] && [ "$est" -le 700 ]; then req="0.875"; fi
    if [ "$est" -ge 701 ]; then req="1.0"; fi

    local current_val=$(echo "$MARGIN_LEFT" | sed 's/in//g')

    echo "------------------------------------------------------------"
    echo "PRE-FLIGHT ESTIMATE:"
    echo "  Estimated Pages:  ~$est pages"
    echo "  Current Gutter:   ${current_val}in (MARGIN_LEFT)"
    echo "  KDP Recommended:  ${req}in"
    
    if (( $(echo "$current_val < $req" | bc -l) )); then
        echo ""
        echo "WARNING: Your inside margin (gutter) is thinner than recommended."
        read -p "Would you like to use the recommended ${req}in margin for this build? (y/N): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            MARGIN_LEFT="${req}in"
            echo "Proceeding with MARGIN_LEFT=$MARGIN_LEFT"
        else
            echo "Proceeding with your custom config ($MARGIN_LEFT)"
        fi
    else
        echo "  Status:           Gutter is sufficient."
    fi
    echo "------------------------------------------------------------"
    echo ""
}

# --- LaTeX Header Generation ---
build_latex_header() {
    cat << LATEXEOF
\usepackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\fancyhead[LE]{${HEADER_EVEN_LEFT:-}}
\fancyhead[RE]{${HEADER_EVEN_RIGHT:-}}
\fancyhead[LO]{${HEADER_ODD_LEFT:-}}
\fancyhead[RO]{${HEADER_ODD_RIGHT:-}}
\renewcommand{\headrulewidth}{${HEADER_RULE_WIDTH:-0.4pt}}
\fancypagestyle{plain}{\fancyhf{}\fancyfoot[C]{\thepage}\renewcommand{\headrulewidth}{0pt}}
\newenvironment{copyright}{\clearpage\thispagestyle{empty}\vspace*{\fill}\begin{center}}{\end{center}\vspace*{\fill}\clearpage}
\newenvironment{dedication}{\clearpage\thispagestyle{empty}\vspace*{0.3\textheight}\begin{center}\itshape}{\end{center}\clearpage}
LATEXEOF
    if [ "$PART_BREAK" = "left" ]; then
        echo "\let\originalpart\part\renewcommand{\part}[1]{\cleardoublepage\ifodd\value{page}\hbox{}\thispagestyle{empty}\newpage\fi\originalpart{#1}}"
    fi
}

# --- Build Targets ---
build_epub() {
    local OUT="${OUTPUT_FILE:-${OUTPUT_DIR}/${BASENAME}.epub}"
    mkdir -p "$(dirname "$OUT")"
    echo "Building EPUB -> $OUT"
    pandoc "$MANUSCRIPT" --metadata-file="$METADATA_FILE" --css="${EPUB_STYLESHEET:-style.css}" \
        --toc --toc-depth="${EPUB_TOC_DEPTH:-2}" -o "$OUT"
}

build_pdf() {
    local OUT="${OUTPUT_FILE:-${OUTPUT_DIR}/${BASENAME}.pdf}"
    mkdir -p "$(dirname "$OUT")"
    echo "Building PDF -> $OUT"
    HEADER_FILE=$(mktemp /tmp/book-header-XXXXX.tex)
    build_latex_header > "$HEADER_FILE"
    
    pandoc "$MANUSCRIPT" --metadata-file="$METADATA_FILE" --pdf-engine=xelatex \
        -V documentclass=book -V "papersize=${PAPER_W},${PAPER_H}" \
        -V "geometry=top=${MARGIN_TOP:-0.75in},bottom=${MARGIN_BOT:-0.75in},left=${MARGIN_LEFT},right=${MARGIN_RIGHT:-0.5in}" \
        -V "fontsize=$FONT_SIZE" -V "mainfont=$MAIN_FONT" -H "$HEADER_FILE" -o "$OUT"
    rm -f "$HEADER_FILE"
}

# --- Execution ---
[ "$FORMAT" != "epub" ] && validate_gutter

case "$FORMAT" in
    epub) build_epub ;;
    pdf)  build_pdf ;;
    all)  build_epub; build_pdf ;;
esac

echo "Build complete."