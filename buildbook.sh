#!/usr/bin/env bash
# ============================================================
# buildbook.sh - Pure Bash Book Builder
# ============================================================
# Description: A lightweight, pure-Bash toolchain for publishing professional PDFs and EPUBs directly from Markdown.
# Author:      Todd Emerson (todd@toddemerson.com)
# Created:     2026-03-24
# Version:     1.0.0
# License:     BSL 1.1
#
# Usage:       ./buildbook.sh <manuscript.md> [format] [options]
# Dependencies: Requires pandoc texlive-xetex texlive-latex-extra texlive-fonts-extra (fonts-linuxlibertine)
#
set -e

# --- Default Variables ---
FORMAT="all"
MANUSCRIPT=""
CONFIG_FILE="buildbook.conf"
METADATA_FILE="metadata.yaml"
OUTPUT_FILE=""

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--config) CONFIG_FILE="$2"; shift ;;
        -o|--output) OUTPUT_FILE="$2"; shift ;;
        epub|pdf|all) FORMAT="$1" ;;
        *.md) MANUSCRIPT="$1" ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$MANUSCRIPT" ] || [ ! -f "$MANUSCRIPT" ]; then
    echo "Usage: $0 manuscript.md [epub|pdf|all] [-c buildbook.conf] [-o output_name]"
    exit 1
fi

# --- Load Configuration ---
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Deriving defaults if config variables are missing
PAPER_W=${PAPER_W:-"6in"}
PAPER_H=${PAPER_H:-"9in"}
FONT_SIZE=${FONT_SIZE:-"11pt"}
MAIN_FONT=${MAIN_FONT:-"Linux Libertine O"}
OUTPUT_DIR="out"
BASENAME=$(basename "$MANUSCRIPT" .md)
mkdir -p "$OUTPUT_DIR"

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

% Styling for chapter/part opening pages
\fancypagestyle{plain}{\fancyhf{}\fancyfoot[C]{\thepage}\renewcommand{\headrulewidth}{0pt}}

% Custom environments for Markdown ::: blocks
\newenvironment{copyright}{
  \clearpage\thispagestyle{empty}\vspace*{\fill}\begin{center}
}{
  \end{center}\vspace*{\fill}\clearpage
}

\newenvironment{dedication}{
  \clearpage\thispagestyle{empty}\vspace*{0.3\textheight}\begin{center}\itshape
}{
  \end{center}\clearpage
}
LATEXEOF

    if [ "$PART_BREAK" = "left" ]; then
        echo "\let\originalpart\part"
        echo "\renewcommand{\part}[1]{\cleardoublepage\ifodd\value{page}\hbox{}\thispagestyle{empty}\newpage\fi\originalpart{#1}}"
    fi
}

# --- Build Targets ---
build_epub() {
    local OUT="${OUTPUT_FILE:-${OUTPUT_DIR}/${BASENAME}.epub}"
    echo "Building EPUB -> $OUT"
    pandoc "$MANUSCRIPT" --metadata-file="$METADATA_FILE" --css="${EPUB_STYLESHEET:-style.css}" \
        --toc --toc-depth="${EPUB_TOC_DEPTH:-2}" -o "$OUT"
}

build_pdf() {
    local OUT="${OUTPUT_FILE:-${OUTPUT_DIR}/${BASENAME}.pdf}"
    echo "Building PDF -> $OUT"
    HEADER_FILE=$(mktemp /tmp/book-header-XXXXX.tex)
    build_latex_header > "$HEADER_FILE"
    
    pandoc "$MANUSCRIPT" --metadata-file="$METADATA_FILE" --pdf-engine=xelatex \
        -V documentclass=book -V "papersize=${PAPER_W},${PAPER_H}" \
        -V "geometry=top=${MARGIN_TOP:-0.75in},bottom=${MARGIN_BOT:-0.75in},left=${MARGIN_LEFT:-0.75in},right=${MARGIN_RIGHT:-0.5in}" \
        -V "fontsize=$FONT_SIZE" -V "mainfont=$MAIN_FONT" -H "$HEADER_FILE" -o "$OUT"
    rm -f "$HEADER_FILE"
}

case "$FORMAT" in
    epub) build_epub ;;
    pdf)  build_pdf ;;
    all)  build_epub; build_pdf ;;
esac