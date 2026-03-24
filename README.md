# BuildBook
A lightweight, pure-Bash toolchain for publishing professional PDFs and EPUBs directly from Markdown.

BuildBook wraps the power of [Pandoc](https://pandoc.org/) into a simple, maintainable workflow. 
It completely eliminates the need for complex Python parsing scripts, relying instead on native Bash configuration files and targeted LaTeX injection to give you beautiful print and digital books from a single Markdown source.

**If you are new here, check out the** `examples/` **directory!** It contains a fully working sample book, configuration templates, and a dedicated guide to help you run your first build in seconds.

## Features

- **Unified Styling:** Use Markdown ::: divs to style frontmatter (dedications, copyright pages) for both EPUB and print PDF simultaneously..
- **Precise TOC Control:** Drop your Table of Contents exactly where you want it (e.g., after the copyright page).
- **Advanced Print Layout:** Granular control over trim sizes, margins, headers, footers, and page breaks (e.g., forcing Parts to start on left pages and Chapters on right pages).

## Prerequisites & Installation
BuildBook relies on [Pandoc](https://pandoc.org/) (the universal document converter) and a [LaTeX engine](https://www.latex-project.org/) (specifically XeLaTeX) to generate PDFs. 

### For Windows Users (WSL)

If you are on Windows, this script is designed to run in a Linux environment. The easiest way to do this is to install [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install) and open an Ubuntu terminal.

### 1. Install Dependencies
On Ubuntu/Debian-based systems, install the dependencies for the script.

```sh
sudo apt update
sudo apt install pandoc texlive-xetex texlive-latex-extra texlive-fonts-extra fonts-linuxlibertine
```
*(Note: `fonts-linuxlibertine` is recommended if you use the default `Linux Libertine O` font.)*

### 2. Download BuildBook
Clone this repository to your computer and navigate to the new folder:
```bash
git clone [https://github.com/yourusername/buildbook.git](https://github.com/yourusername/buildbook.git)
cd buildbook
```

### 3. Make the Script Executable
By default, Linux prevents downloaded text files from running as programs. You need to grant the script "executable" permissions:

```bash
chmod +x buildbook.sh
```

## Quick Start: The `examples` Directory

The best way to understand BuildBook is to run the example. We have included a complete, minimal working example in the `examples/` folder.

From the root directory of this project, run the following command:

```bash
./buildbook.sh examples/sample-book.md all -c examples/buildbook.conf
```

*(**Note:** The `./` tells Linux to execute the script located in your current directory).*

Once it finishes, look inside the newly created `out/` directory. You will see a professionally formatted `sample-book.pdf` and a flowable `sample-book.epub`!



## Usage
When you are ready to build your own books, the basic syntax is:

```bash
./buildbook.sh <manuscript.md> [format] [options]
```

### Formats
- `pdf`: Builds a print-ready PDF.
- `epub`: Builds a digital EPUB.
- `all`: Builds both formats (Default).

### Options
- `-c, --config <file>`: Specify a custom configuration file (Defaults to buildbook.conf).
- `-o, --output <name>`: Specify a custom output filename (Defaults to out/<manuscript-basename>.<format>).

### Examples
```bash
# Build both PDF and EPUB using default configurations
./buildbook.sh my-book.md

# Build only a PDF with a specific configuration file
./buildbook.sh my-book.md pdf -c print-layout.conf

# Build an EPUB with a custom output name
./buildbook.sh my-book.md epub -o final-draft.epub
```

## Configuration Architecture
BuildBook separates your book's data from its visual layout:
- `metadata.yaml`: Contains standard book data (Title, Author, Publisher). Pandoc reads this directly.
- `buildbook.conf`: A Bash-sourced configuration file that dictates trim sizes, fonts, headers/footers, and structural breaks.
- `style.css`: Controls the visual layout for the EPUB format and shares unified class naming conventions with the PDF LaTeX environments.

## Markdown Formatting Guide
BuildBook supports custom Markdown environments to handle frontmatter gracefully in both PDF and EPUB formats.

### Table of Contents
To place your PDF Table of Contents precisely where you want it (instead of being forced to the very beginning), add this raw LaTeX block to your Markdown file:

```
`​`​`{=latex}
\tableofcontents
`​`​`
```

### Custom Page Environments
Use fenced divs (`:::`) to create specialized pages. BuildBook will map these to CSS classes for EPUB and custom LaTeX environments for PDF.C

#### Copyright Page (Vertically centered, no page numbers)
```
:::: {.copyright}
Copyright © 2026 by Jane Doe. All rights reserved.
Published by Example Books.
:::
```

#### Dedication Page (Italicized, offset from the top, no page numbers)
```
:::: {.dedication}
For my family, who supported me through this journey.
:::
```

#### Advanced Page Headers
By default, the PDF engine automatically maps your top-level headings (`#`) to the `\leftmark` header variable and your second-level headings (`##`) to the `\rightmark` header variable.

If you want the body of the page to say "Chapter 1: Hello World", but you want the header at the top of the page to only say "Hello World", you can override the header text using a raw LaTeX command immediately after your heading:

```markdown
## Chapter 1: Hello World
`​`​`{=latex}
\markright{Hello World}
`​`​`
```

**(Use `\markright{}` for `##` headings, and `\markboth{}{}` for `#` headings).*