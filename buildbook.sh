#!/usr/bin/env bash
# ============================================================
# buildbook.sh - Pure Bash Book Builder
# ============================================================
# Description: A lightweight, pure-Bash toolchain for publishing professional PDFs and EPUBs directly from Markdown.
# Author:      Todd Emerson (todd@toddemerson.com)
# Created:     2026-03-24
# Version:     1.3.6
# License:     BSL 1.1
#
# Usage:       buildbook <manuscript.md> [format] [options]
# Dependencies: Requires pandoc texlive-xetex texlive-latex-extra texlive-fonts-extra bc (fonts-linuxlibertine)
# ============================================================
set -e

VERSION="1.3.6"

# --- Default Variables ---
FORMAT="all"
MANUSCRIPT=""
CONFIG_FILE="buildbook.conf"
METADATA_FILE="metadata.yaml"
OUTPUT_DIR="out"
OUTPUT_FILE=""

# --- Internal Templates (for --init) ---
read -r -d '' INIT_METADATA << 'EOF' || true
---
# For more information, review example at https://github.com/ToddE/buildbook/blob/main/examples/metadata.yaml
title: ""
subtitle: ""
author: ""
publisher: ""
lang: "en-US"
rights: ""
# cover-image: "cover.jpg"
---
EOF

read -r -d '' INIT_CONF << 'EOF' || true
# ==========================================
# buildbook.conf - Layout & Style Config
# ==========================================

# --- PDF Page Layout ---
TRIM_SIZE="6x9"
PAPER_W="6in"
PAPER_H="9in"
MARGIN_TOP="0.75in"
MARGIN_BOT="0.75in"
MARGIN_LEFT="0.75in"  # Inside margin/gutter
MARGIN_RIGHT="0.5in"  # Outside margin

# --- Typography ---
FONT_SIZE="11pt"
LINE_SPACING="1.15"
MAIN_FONT="Linux Libertine O"
MONO_FONT="DejaVu Sans Mono"
PARAGRAPH_STYLE="block" 

# --- Page Headers & Footers ---
# \leftmark = Chapter | \rightmark = Section | \thepage = Number
HEADER_EVEN_LEFT="\thepage"
HEADER_EVEN_RIGHT="\textit{\leftmark}"
HEADER_ODD_LEFT="\textit{\rightmark}"
HEADER_ODD_RIGHT="\thepage"
HEADER_RULE_WIDTH="0.4pt"

# --- Structural Breaks ---
PART_BREAK="right"     # Forces Parts to odd (right) pages
CHAPTER_BREAK="right"  # Forces Chapters to odd (right) pages
PART_PAGE_PLAIN="true"
CHAPTER_PAGE_PLAIN="true"

# --- EPUB Specifics ---
EPUB_STYLESHEET="style.css"
EPUB_TOC_DEPTH="2"
EPUB_SPLIT_LEVEL="2"
EOF

read -r -d '' INIT_CSS << 'EOF' || true
/* BuildBook - Unified Stylesheet */
body { font-family: Georgia, "Linux Libertine O", serif; line-height: 1.6; margin: 1em; }
h1 { font-size: 1.8em; font-weight: bold; text-align: center; margin-top: 3em; margin-bottom: 1em; page-break-before: always; }
h2 { font-size: 1.4em; font-weight: bold; margin-top: 2em; margin-bottom: 0.8em; page-break-before: always; }
h3 { font-size: 1.1em; font-weight: bold; margin-top: 1.5em; margin-bottom: 0.5em; }
blockquote { text-align: center; font-style: italic; margin: 2em 1.5em; padding: 0; border: none; }
blockquote p { margin: 0.3em 0; }
table { border-collapse: collapse; width: 100%; font-size: 0.85em; margin: 1em 0; }
th, td { border: 1px solid #ccc; padding: 0.4em 0.6em; text-align: left; }
th { background-color: #f0f0f0; font-weight: bold; }
img { max-width: 100%; height: auto; display: block; margin: 1.5em auto; }
figcaption { text-align: center; font-size: 0.85em; font-style: italic; color: #666; margin-top: 0.5em; }
code { font-family: "Courier New", monospace; font-size: 0.9em; background-color: #f5f5f5; padding: 0.1em 0.3em; }
pre { background-color: #f5f5f5; padding: 1em; overflow-x: auto; font-size: 0.85em; line-height: 1.4; }
ul, ol { margin: 0.8em 0; padding-left: 2em; }
li { margin-bottom: 0.4em; }
hr { border: none; border-top: 1px solid #ccc; margin: 2em 0; }
.copyrightpage { margin-top: 30%; font-size: 0.85em; text-align: center; page-break-before: always; }
.dedicationpage { text-align: center; margin-top: 30%; font-style: italic; page-break-before: always; page-break-after: always; }
.center-quote { text-align: center; }
EOF

read -r -d '' INIT_MD << 'EOF' || true
# Introduction
Welcome to your new book. 

::: {.dedicationpage}
To the dreamers and the builders.
:::

::: {.copyrightpage}
Copyright © 2026 by Jane Doe.
All rights reserved.
:::

```{=latex}
\tableofcontents
\clearpage
```

# Chapter 1: The Beginning
This is where your story starts.
EOF

# --- Helper Functions ---

show_help() {
    cat << EOF
NAME
    buildbook - A lightweight toolchain for professional publishing.

SYNOPSIS
    buildbook <manuscript.md> [format] [options]
    buildbook --init [directory]
    buildbook -v | --version
    buildbook -h | --help

DESCRIPTION
    BuildBook converts Markdown manuscripts into professional print-ready PDFs 
    and flowable digital EPUBs using unified styling.

ARGUMENTS
    manuscript.md
        The source Markdown file containing your book content.

    format
        pdf     Builds a print-ready PDF.
        epub    Builds a digital EPUB.
        all     Builds both formats (Default).

OPTIONS
    -c, --config <file>
        Specify a custom configuration file (Defaults to buildbook.conf).

    -o, --output <name>
        Specify a custom output path (Defaults to out/<basename>.<format>).

    --init [dir]
        Scaffold a new project in [dir] (or current directory if omitted).

    -v, --version
        Display version number and perform a system dependency check.

    -h, --help
        Display this comprehensive help documentation.

AUTHOR
    Todd Emerson (todd@toddemerson.com)

LICENSE
    Business Source License 1.1 (BSL)
EOF
    exit 0
}

init_project() {
    local target_dir="${1:-.}"
    if [ "$target_dir" != "." ]; then
        echo "Creating directory: $target_dir"
        mkdir -p "$target_dir"
        cd "$target_dir"
    fi
    echo "Initializing new BuildBook project..."
    [ ! -f "metadata.yaml" ] && echo "$INIT_METADATA" > metadata.yaml && echo "  [+] metadata.yaml"
    [ ! -f "buildbook.conf" ] && echo "$INIT_CONF" > buildbook.conf && echo "  [+] buildbook.conf"
    [ ! -f "style.css" ] && echo "$INIT_CSS" > style.css && echo "  [+] style.css"
    [ ! -f "manuscript.md" ] && echo "$INIT_MD" > manuscript.md && echo "  [+] manuscript.md"
    echo "------------------------------------------------------------"
    echo "Done! Run: buildbook manuscript.md"
    echo "------------------------------------------------------------"
    exit 0
}

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
    [ "$MISSING" -eq 0 ] && echo "Status: System is ready." || echo "Status: $MISSING dependency missing."
    exit 0
}

# --- Argument Parsing ---

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        --init) shift; init_project "$1"; exit 0 ;;
        -v|--version) check_status ;;
        -c|--config) CONFIG_FILE="$2"; shift ;;
        -o|--output) OUTPUT_FILE="$2"; shift ;;
        epub|pdf|all) FORMAT="$1" ;;
        *.md) MANUSCRIPT="$1" ;;
        *) echo "Unknown parameter: $1. Use --help for usage info."; exit 1 ;;
    esac
    shift
done

if [ -z "$MANUSCRIPT" ] || [ ! -f "$MANUSCRIPT" ]; then
    echo "Usage: buildbook manuscript.md [epub|pdf|all] [options]"
    echo "Try 'buildbook --help' for more information."
    exit 1
fi

# --- Load Configuration ---

[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Apply logic defaults for derived variables
BASENAME=$(basename "$MANUSCRIPT" .md)
PAPER_W=${PAPER_W:-"6in"}
PAPER_H=${PAPER_H:-"9in"}
FONT_SIZE=${FONT_SIZE:-"11pt"}
LINE_SPACING=${LINE_SPACING:-"1.15"}
MAIN_FONT=${MAIN_FONT:-"Linux Libertine O"}
MONO_FONT=${MONO_FONT:-"DejaVu Sans Mono"}
PARAGRAPH_STYLE=${PARAGRAPH_STYLE:-"block"}
MARGIN_LEFT=${MARGIN_LEFT:-"0.75in"}
CHAPTER_BREAK=${CHAPTER_BREAK:-"right"}
PART_BREAK=${PART_BREAK:-"right"}

# --- Logic Modules ---

validate_gutter() {
    local chars=$(wc -m < "$MANUSCRIPT")
    local imgs=$(grep -c "!\[" "$MANUSCRIPT")
    local est=$(( (chars / 1600) + (imgs / 2) + 4 ))
    local req="0.25"
    [ "$est" -ge 25 ] && [ "$est" -le 75 ] && req="0.375"
    [ "$est" -ge 76 ] && [ "$est" -le 150 ] && req="0.5"
    [ "$est" -ge 151 ] && [ "$est" -le 300 ] && req="0.625"
    [ "$est" -ge 301 ] && [ "$est" -le 500 ] && req="0.75"
    [ "$est" -ge 501 ] && [ "$est" -le 700 ] && req="0.875"
    [ "$est" -ge 701 ] && req="1.0"
    local current_val=$(echo "$MARGIN_LEFT" | sed 's/in//g')
    echo "------------------------------------------------------------"
    echo "PRE-FLIGHT ESTIMATE: ~$est pages | Gutter: ${current_val}in | Req: ${req}in"
    if (( $(echo "$current_val != $req" | bc -l) )); then
        if (( $(echo "$current_val < $req" | bc -l) )); then
            echo "WARNING: Your inside margin (gutter) is thinner than recommended."
        else
            echo "NOTE: Your inside margin is larger than the KDP minimum."
        fi
        read -p "Would you like to adopt the KDP recommendation of ${req}in? (y/N): " choice
        [[ "$choice" =~ ^[Yy]$ ]] && MARGIN_LEFT="${req}in" && echo "Proceeding with MARGIN_LEFT=$MARGIN_LEFT"
    fi
    echo "------------------------------------------------------------"
}

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

% Line spacing support
\usepackage{setspace}
\setstretch{$LINE_SPACING}

% Paragraph styling
LATEXEOF

    if [ "$PARAGRAPH_STYLE" = "block" ]; then
        echo "\usepackage{parskip}"
    else
        echo "\usepackage{indentfirst}"
        echo "\setlength{\parindent}{1.5em}"
    fi

    cat << LATEXEOF
% Frontmatter Environments
\newenvironment{copyrightpage}{
  \cleardoublepage\thispagestyle{empty}\vspace*{\fill}\begin{center}
}{
  \end{center}\vspace*{\fill}\cleardoublepage
}

\newenvironment{dedicationpage}{
  \cleardoublepage\thispagestyle{empty}\vspace*{0.3\textheight}\begin{center}\itshape
}{
  \end{center}\cleardoublepage
}

% Structural Break Logic
LATEXEOF

    # Handle Chapter Breaks
    if [ "$CHAPTER_BREAK" = "right" ]; then
        echo "\patchcmd{\chapter}{\clearpage}{\cleardoublepage}{}{}"
    elif [ "$CHAPTER_BREAK" = "left" ]; then
        echo "\patchcmd{\chapter}{\clearpage}{\clearpage\ifodd\value{page}\hbox{}\thispagestyle{empty}\clearpage\fi}{}{}"
    fi

    # Handle Part Breaks
    if [ "$PART_BREAK" = "right" ]; then
        echo "\patchcmd{\part}{\clearpage}{\cleardoublepage}{}{}"
    elif [ "$PART_BREAK" = "left" ]; then
        echo "\patchcmd{\part}{\clearpage}{\clearpage\ifodd\value{page}\hbox{}\thispagestyle{empty}\clearpage\fi}{}{}"
    fi
}

build_epub() {
    local OUT="${OUTPUT_FILE:-${OUTPUT_DIR}/${BASENAME}.epub}"
    mkdir -p "$(dirname "$OUT")"
    echo "Building EPUB -> $OUT"
    pandoc "$MANUSCRIPT" --metadata-file="$METADATA_FILE" --css="${EPUB_STYLESHEET:-style.css}" --toc --toc-depth="${EPUB_TOC_DEPTH:-2}" -o "$OUT"
}

build_pdf() {
    local OUT="${OUTPUT_FILE:-${OUTPUT_DIR}/${BASENAME}.pdf}"
    mkdir -p "$(dirname "$OUT")"
    echo "Building PDF -> $OUT"
    HEADER_FILE=$(mktemp /tmp/book-header-XXXXX.tex)
    build_latex_header > "$HEADER_FILE"
    
    pandoc "$MANUSCRIPT" \
        --metadata-file="$METADATA_FILE" \
        --pdf-engine=xelatex \
        --top-level-division=chapter \
        -V documentclass=book \
        -V classoption=twoside \
        -V classoption=openright \
        -V "papersize=${PAPER_W},${PAPER_H}" \
        -V "geometry=top=${MARGIN_TOP:-0.75in},bottom=${MARGIN_BOT:-0.75in},left=${MARGIN_LEFT},right=${MARGIN_RIGHT:-0.5in}" \
        -V "fontsize=$FONT_SIZE" \
        -V "mainfont=$MAIN_FONT" \
        -V "monofont=$MONO_FONT" \
        -H "$HEADER_FILE" \
        -o "$OUT"
    
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