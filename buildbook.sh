#!/usr/bin/env bash
# ============================================================
# buildbook.sh - Pure Bash Book Builder
# ============================================================
# Description: A lightweight, pure-Bash toolchain for publishing professional PDFs and EPUBs directly from Markdown.
# Author:      Todd Emerson (todd@toddemerson.com)
# Created:     2026-03-24
# Version:     1.4.5
# License:     BSL 1.1
#
# Usage:       buildbook <manuscript.md> [format] [options]
# Dependencies: Requires pandoc texlive-xetex texlive-latex-extra texlive-fonts-extra bc (fonts-linuxlibertine)
# ============================================================
set -e

VERSION="1.4.5"

# --- Default Variables ---
FORMAT="all"
MANUSCRIPT=""
CONFIG_FILE="buildbook.conf"
METADATA_FILE="metadata.yaml"
LATEX_STYLES_FILE="examples/styles/styles.tex"
EPUB_STYLESHEET="style.css"
OUTPUT_DIR="out"
OUTPUT_FILE=""
VERBOSE=false

# --- Internal Templates (for --init) ---
# These templates provide high-quality starting points for new projects.

read -r -d '' INIT_METADATA << 'EOF' || true
---
# ============================================================
# Book Metadata 
# ============================================================
# Core book identity variables. Pandoc reads this directly.
# ============================================================

title: "New Book Title"
subtitle: "An Optional Subtitle"
author: "Your Name"
publisher: "Your Press"
date: "2026"
lang: "en-US"
description: |
  A short synopsis for e-readers. This text is often pulled 
  into the 'description' field of the EPUB metadata.
rights: "Copyright © 2026 by Your Name. All rights reserved."

# Amazon KDP / ISBN Info
identifier: "urn:isbn:000-0-000000-00-0"

# Metadata for Search Engines
keywords: [fiction, novel, publishing]
subject: "Literature"

# Cover Image (uncomment to use)
# cover-image: "cover.jpg"
---
EOF

read -r -d '' INIT_CONF << 'EOF' || true
# ==========================================
# buildbook.conf - Master Layout Config
# ==========================================

# --- PDF Page Layout ---
# Standard industry sizes: 5x8, 5.25x8, 5.5x8.5, 6x9, 7x10, 8.5x11
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
PARAGRAPH_STYLE="block" # Options: 'block' (spaced) or 'indent' (novel style)

# --- Page Headers & Footers ---
# \leftmark  = Top-level heading (#)
# \rightmark = Second-level heading (##)
# \thepage   = Page number
HEADER_EVEN_LEFT="\thepage"
HEADER_EVEN_RIGHT="\textit{\leftmark}"
HEADER_ODD_LEFT="\textit{\rightmark}"
HEADER_ODD_RIGHT="\thepage"
HEADER_RULE_WIDTH="0.4pt"

# --- Structural Breaks ---
# Options: 'right' (odd page), 'left' (even page), or 'any' (next available)
PART_BREAK="right"     
CHAPTER_BREAK="right" 

# --- External Style Files ---
# Ensure these paths are relative to where you run the script
LATEX_STYLES_FILE="styles.tex"
EPUB_STYLESHEET="style.css"
EOF

read -r -d '' INIT_TEX << 'EOF' || true
% ==========================================
% styles.tex - Custom PDF Environments
% ==========================================
% These environments provide stable containers for Markdown "divs".
% We use the list-based approach for maximum stability with Pandoc.

% --- Hero Quote (::: {.center-quote}) ---
\newenvironment{center-quote}{
  \list{}{
    \leftmargin=2em
    \rightmargin=2em
  }\item\relax\centering\itshape
}{
  \endlist
}

% --- Pull Quote (::: {.pullquote}) ---
\newenvironment{pullquote}{
  \par\vspace{1.5em}
  \list{}{
    \leftmargin=1em
    \rightmargin=1em
  }\item\relax\centering\Large\bfseries
}{
  \endlist\par\vspace{1.5em}
}

% --- Side Note (::: {.note}) ---
\newenvironment{note}{
  \list{}{
    \leftmargin=3em
    \rightmargin=3em
  }\item\relax\small\itshape\centering
}{
  \endlist
}
EOF

read -r -d '' INIT_CSS << 'EOF' || true
/* BuildBook - Unified Stylesheet */
body { font-family: "Linux Libertine O", Georgia, serif; line-height: 1.6; margin: 1em; color: #1a1a1a; }
h1 { font-size: 1.8em; font-weight: bold; text-align: center; margin-top: 3em; margin-bottom: 1em; page-break-before: always; }
h2 { font-size: 1.4em; font-weight: bold; text-align: center; margin-top: 2em; margin-bottom: 0.8em; page-break-before: always; }
h3 { font-size: 1.1em; font-weight: bold; margin-top: 1.5em; margin-bottom: 0.5em; }
p { margin-bottom: 1em; }

/* Custom containers */
.copyrightpage { margin-top: 30%; font-size: 0.85em; text-align: center; page-break-before: always; }
.dedicationpage { text-align: center; margin-top: 30%; font-style: italic; page-break-before: always; }
.center-quote { text-align: center; font-style: italic; margin: 2em auto; }
.pullquote { font-size: 1.3em; font-weight: bold; text-align: center; margin: 2em 10%; }

/* Standard elements */
blockquote { border-left: 4px solid #eee; padding-left: 1em; font-style: italic; color: #444; }
img { max-width: 100%; height: auto; display: block; margin: 1.5em auto; }
code { background: #f4f4f4; padding: 2px 4px; border-radius: 3px; font-family: monospace; }
EOF

read -r -d '' INIT_MD << 'EOF' || true
# Introduction

::: {.dedicationpage}
To the ones who build tools.
:::

::: {.copyrightpage}
Copyright © 2026. All rights reserved.
:::

\tableofcontents

# Part One: The Journey Begins

# Chapter 1: Hello World
This is the start of your journey. Using the `buildbook` toolchain, this chapter 
will automatically start on a right-hand page in your print PDF.

::: {.center-quote}
"The journey of a thousand pages begins with a single line of Markdown."
:::

You can define custom styles in `styles.tex` and `style.css` and use them 
immediately in your manuscript.
EOF

# --- Helper Functions ---

cleanup() {
    [ -f "$H_FILE" ] && rm -f "$H_FILE"
}
trap cleanup EXIT

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
    BuildBook converts Markdown manuscripts into print-ready PDFs and flowable EPUBs.
    It handles automated gutter calculations, professional typography, and 
    standard frontmatter layouts.

ARGUMENTS
    manuscript.md
        The source Markdown file containing your book content.

    format
        pdf     Builds a print-ready PDF via XeLaTeX.
        epub    Builds a digital EPUB.
        all     Builds both formats (Default).

OPTIONS
    -c, --config <file>
        Specify a custom configuration file (Default: buildbook.conf).

    -o, --output <file>
        Specify a custom output path.

    --init [dir]
        Scaffold a new project in the specified directory.

    --verbose
        Show detailed command output.

    -v, --version
        Check system dependencies and display version info.

EXAMPLES
    buildbook manuscript.md pdf
    buildbook novel.md -c settings/kdp-6x9.conf
    buildbook --init my-new-book
EOF
    exit 0
}

check_status() {
    echo "BuildBook v$VERSION Status Check:"
    echo "------------------------------------------------------------"
    local DEPS=("pandoc" "xelatex" "bc" "fc-list")
    local MISSING=0
    for dep in "${DEPS[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo "  [OK] $dep is installed."
        else
            echo "  [!!] $dep is MISSING."
            MISSING=$((MISSING + 1))
        fi
    done
    
    # Check for specific fonts
    if command -v fc-list >/dev/null 2>&1; then
        if fc-list | grep -qi "Linux Libertine O"; then
            echo "  [OK] Linux Libertine O font found."
        else
            echo "  [!!] Linux Libertine O font NOT found."
        fi
    fi
    
    echo "------------------------------------------------------------"
    if [ "$MISSING" -eq 0 ]; then
        echo "Status: System is ready for building."
    else
        echo "Status: $MISSING dependency missing. Build may fail."
    fi
    exit 0
}

init_project() {
    local dir="${1:-.}"
    if [ "$dir" != "." ]; then
        echo "Creating project directory: $dir"
        mkdir -p "$dir" && cd "$dir"
    fi
    echo "Initializing project files..."
    [ ! -f "metadata.yaml" ] && echo "$INIT_METADATA" > metadata.yaml && echo "  [+] metadata.yaml"
    [ ! -f "buildbook.conf" ] && echo "$INIT_CONF" > buildbook.conf && echo "  [+] buildbook.conf"
    [ ! -f "styles.tex" ] && echo "$INIT_TEX" > styles.tex && echo "  [+] styles.tex"
    [ ! -f "style.css" ] && echo "$INIT_CSS" > style.css && echo "  [+] style.css"
    [ ! -f "manuscript.md" ] && echo "$INIT_MD" > manuscript.md && echo "  [+] manuscript.md"
    echo "Scaffolding complete. Run 'buildbook manuscript.md' to build."
    exit 0
}

# --- Argument Parsing ---

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        --init) shift; init_project "$1" ;;
        --verbose) VERBOSE=true ;;
        -v|--version) check_status ;;
        -c|--config) CONFIG_FILE="$2"; shift ;;
        -o|--output) OUTPUT_FILE="$2"; shift ;;
        pdf|epub|all) FORMAT="$1" ;;
        *.md) MANUSCRIPT="$1" ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$MANUSCRIPT" ] || [ ! -f "$MANUSCRIPT" ]; then
    echo "Error: Manuscript file not found."
    echo "Usage: buildbook <file.md> [format]"
    exit 1
fi

[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
BASENAME=$(basename "$MANUSCRIPT" .md)

# --- Logic Modules ---

validate_gutter() {
    local chars=$(wc -m < "$MANUSCRIPT")
    local imgs=$(grep -c "!\[" "$MANUSCRIPT")
    # Rough estimate: 1600 chars per page, + 0.5 page per image
    local est=$(( (chars / 1600) + (imgs / 2) + 4 ))
    
    local req="0.25"
    if [ "$est" -ge 24 ]  && [ "$est" -le 75 ];  then req="0.375"; fi
    if [ "$est" -ge 76 ]  && [ "$est" -le 150 ]; then req="0.5"; fi
    if [ "$est" -ge 151 ] && [ "$est" -le 300 ]; then req="0.625"; fi
    if [ "$est" -ge 301 ] && [ "$est" -le 500 ]; then req="0.75"; fi
    if [ "$est" -ge 501 ] && [ "$est" -le 700 ]; then req="0.875"; fi
    if [ "$est" -ge 701 ]; then req="1.0"; fi
    
    local cur=$(echo "$MARGIN_LEFT" | sed 's/in//g')
    echo "------------------------------------------------------------"
    echo "PRE-FLIGHT: ~$est estimated pages."
    echo "Gutter (Inside Margin): ${cur}in | KDP Requirement: ${req}in"
    
    if (( $(echo "$cur < $req" | bc -l) )); then
        echo "WARNING: Your gutter is thinner than KDP recommendations."
        read -p "Update MARGIN_LEFT to ${req}in? (y/N): " choice
        [[ "$choice" =~ ^[Yy]$ ]] && MARGIN_LEFT="${req}in" && echo "  [OK] Updated to ${req}in"
    fi
    echo "------------------------------------------------------------"
}

build_latex_header() {
    cat << LATEXEOF
% --- Core Layout & Headers ---
\usepackage{fancyhdr}
\pagestyle{fancy}\fancyhf{}
\fancyhead[LE]{${HEADER_EVEN_LEFT:-}}
\fancyhead[RE]{${HEADER_EVEN_RIGHT:-}}
\fancyhead[LO]{${HEADER_ODD_LEFT:-}}
\fancyhead[RO]{${HEADER_ODD_RIGHT:-}}
\renewcommand{\headrulewidth}{${HEADER_RULE_WIDTH:-0.4pt}}

% Ensure blank pages inserted by \cleardoublepage are truly empty
\usepackage{emptypage}
\fancypagestyle{plain}{\fancyhf{}\fancyfoot[C]{\thepage}\renewcommand{\headrulewidth}{0pt}}

% Typography & Spacing
\usepackage{setspace}\setstretch{${LINE_SPACING:-1.15}}
\usepackage{etoolbox}
LATEXEOF

    if [ "$PARAGRAPH_STYLE" = "block" ]; then 
        echo "\usepackage{parskip}" 
    else
        echo "\usepackage{indentfirst}\setlength{\parindent}{1.5em}"
    fi

    cat << LATEXEOF
% Standard Frontmatter Environments
\newenvironment{copyrightpage}{
  \cleardoublepage\thispagestyle{empty}\vspace*{\fill}\begin{center}
}{
  \end{center}\vspace*{\fill}\clearpage
}

\newenvironment{dedicationpage}{
  \cleardoublepage\thispagestyle{empty}\vspace*{0.3\textheight}\begin{center}\itshape
}{
  \end{center}\clearpage
}

% External Style Inclusion
LATEXEOF
    
    if [ -f "$LATEX_STYLES_FILE" ]; then
        cat "$LATEX_STYLES_FILE"
    else
        echo "% WARNING: External styles file not found at $LATEX_STYLES_FILE"
    fi

    # Chapter/Part Breaks logic using patchcmd
    # This ensures that # and ## divisions respect the conf file's break settings.
    if [ "$CHAPTER_BREAK" = "right" ]; then 
        echo "\patchcmd{\chapter}{\clearpage}{\cleardoublepage}{}{}"
    fi
    if [ "$PART_BREAK" = "right" ]; then 
        echo "\patchcmd{\part}{\clearpage}{\cleardoublepage}{}{}"
    fi
}

build_pdf() {
    local OUT="${OUTPUT_FILE:-${OUTPUT_DIR}/${BASENAME}.pdf}"
    mkdir -p "$OUTPUT_DIR"
    
    # Only run gutter check for PDF
    validate_gutter
    
    echo "Building PDF -> $OUT"
    H_FILE=$(mktemp /tmp/h-XXXX.tex)
    build_latex_header > "$H_FILE"
    
    local CMD="pandoc \"$MANUSCRIPT\" \
        --metadata-file=\"$METADATA_FILE\" \
        --pdf-engine=xelatex \
        --top-level-division=chapter \
        -V documentclass=book \
        -V classoption=twoside \
        -V classoption=openright \
        -V \"papersize=${PAPER_W:-6in},${PAPER_H:-9in}\" \
        -V \"geometry=top=${MARGIN_TOP:-0.75in},bottom=${MARGIN_BOT:-0.75in},left=${MARGIN_LEFT},right=${MARGIN_RIGHT:-0.5in}\" \
        -V \"fontsize=${FONT_SIZE:-11pt}\" \
        -V \"mainfont=${MAIN_FONT:-Linux Libertine O}\" \
        -V \"monofont=${MONO_FONT:-DejaVu Sans Mono}\" \
        -H \"$H_FILE\" \
        -o \"$OUT\""
        
    if [ "$VERBOSE" = true ]; then eval "$CMD"; else eval "$CMD" >/dev/null 2>&1; fi
    
    echo "  [DONE] PDF generated successfully."
}

build_epub() {
    local OUT="${OUTPUT_FILE:-${OUTPUT_DIR}/${BASENAME}.epub}"
    mkdir -p "$OUTPUT_DIR"
    echo "Building EPUB -> $OUT"
    
    local CMD="pandoc \"$MANUSCRIPT\" \
        --metadata-file=\"$METADATA_FILE\" \
        --css=\"${EPUB_STYLESHEET:-style.css}\" \
        --toc \
        -o \"$OUT\""
        
    if [ "$VERBOSE" = true ]; then eval "$CMD"; else eval "$CMD" >/dev/null 2>&1; fi
    
    echo "  [DONE] EPUB generated successfully."
}

# --- Execution ---
case "$FORMAT" in 
    pdf) build_pdf ;; 
    epub) build_epub ;; 
    all) build_epub; build_pdf ;; 
esac

echo "Build complete. Your files are in the ${OUTPUT_DIR}/ directory."