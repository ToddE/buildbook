# BuildBook
A lightweight, pure-Bash toolchain for publishing professional PDFs and EPUBs directly from Markdown.

BuildBook wraps the power of [Pandoc](https://pandoc.org/) into a simple, maintainable workflow. 
It completely eliminates the need for complex Python parsing scripts, relying instead on native Bash configuration files and targeted LaTeX injection to give you beautiful print and digital books from a single Markdown source.

**If you are new here, check out the** `examples/` **directory!** It contains a fully working sample book, configuration templates, and a dedicated guide to help you run your first build in seconds.

## Features

- **Unified Styling:** Use Markdown ::: divs to style frontmatter (dedications, copyright pages) for both EPUB and print PDF simultaneously..
- **Precise TOC Control:** Drop your Table of Contents exactly where you want it (e.g., after the copyright page).
- **Advanced Print Layout:** Granular control over trim sizes, margins, headers, footers, and page breaks (e.g., forcing Parts to start on left pages and Chapters on right pages).
- **Automated Gutter Validation:** Built-in protection to ensure your margins meet publisher requirements based on your book's thickness.
- **Project Scaffolding:** Use the --init flag to quickly generate the necessary configuration files for a new book.

## Prerequisites & Installation
BuildBook relies on [Pandoc](https://pandoc.org/) (the universal document converter) and a [LaTeX engine](https://www.latex-project.org/) (specifically XeLaTeX) to generate PDFs. 

### For Windows Users (WSL)
If you are on Windows, this script is designed to run in a Linux environment. The easiest way to do this is to install [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install) and open an Ubuntu terminal.

### 1. Install System Dependencies
On Ubuntu/Debian-based systems, install the dependencies for the script.

```bash
sudo apt update
sudo apt install wget pandoc texlive-xetex texlive-latex-extra texlive-fonts-extra bc fonts-linuxlibertine
```
*(Note: `fonts-linuxlibertine` is recommended if you use the default `Linux Libertine O` font.)*

### 2. Install (and Upgrade) BuildBook 
To install BuildBook to your `~/.local/bin` automatically, run:
```bash
wget -qO- https://raw.githubusercontent.com/ToddE/buildbook/main/install.sh | bash
```
**Upgrading:** To upgrade to the latest version at any time, simply run the aoove command again. It will overwrite the existing buildbook executable with the most recent version from the repository.

### 3. Verify the Installation
To verify that the installation was successful and the command is correctly in your system's search path, type the command without any arguments:

```bash
buildbook -v
```
If the installation is correct, you will see your version number followed by a "System Dependency Check" showing `[OK]` for all required tools.

***Note:** If buildbook isn't recognized (e.g., "command not found") after installation, ensure export `PATH="$HOME/.local/bin:$PATH"` is in your `~/.bashrc` or the equivalent file where your path is set.*

## Recommended Project Organization

You have two main ways to organize your work:

### Option A: Standalone Project (Professional)

Keep your book in its own dedicated folder (or even its own Git repository). This keeps your manuscript separate from the BuildBook source code.

```
my-awesome-book/
├── manuscript.md
├── buildbook.conf  (Customized for this book)
├── metadata.yaml   (Title/Author for this book)
├── style.css       (Optional custom styles for EPUB and PDF)
└── images/
```

From inside `my-awesome-book/`, run:
```bash
buildbook manuscript.md all -c buildbook.conf
```

### Option B: Subdirectory Method (Simple)

If you prefer keeping everything in one place, create a folder inside the BuildBook directory:
`buildbook/projects/my-awesome-book/`


## Usage
Once installed, the basic syntax is:

```bash
buildbook <manuscript.md> [format] [options] 
```

### Formats
- `pdf`: Builds a print-ready PDF.
- `epub`: Builds a digital EPUB.
- `all`: Builds both formats (Default).

### Options
- `-c, --config <file>`: Specify a custom configuration file (Defaults to buildbook.conf).
- `-o, --output <name>`: Specify a custom output filename (Defaults to out/<manuscript-basename>.<format>).
- `-v, --version`: Run version check and dependency scan.
- `--init [dir]`: Initialize a new project in the specified directory (or current directory if omitted).
- `-h, --help`: Display comprehensive help documentation.


### Examples
```bash
# Build both PDF and EPUB
buildbook my-book.md

# Build only a PDF with a specific configuration
buildbook my-book.md pdf -c print-layout.conf

# Build an EPUB with a custom output name
buildbook my-book.md epub -o final-draft.epub
```


## Configuration Architecture
BuildBook separates your book's data from its visual layout:
- `metadata.yaml`: Contains standard book data (Title, Author, Publisher). Pandoc reads this directly.
- `buildbook.conf`: A Bash-sourced configuration file that dictates trim sizes, fonts, headers/footers, and structural breaks.
- `style.css`: Controls the visual layout for the EPUB format and shares unified class naming conventions with the PDF LaTeX environments.


## Configuration
BuildBook uses a Bash-based configuration file. Key variables include:

### PDF Layout
- `PAPER_W` / `PAPER_H`: Physical page dimensions (e.g., 6in, 9in).

- `MARGIN_LEFT`: The inside margin or "gutter."

- `MARGIN_RIGHT` / `MARGIN_TOP` / `MARGIN_BOT`: Outer margins.

PDF Layout

PAPER_W / PAPER_H: Physical page dimensions (e.g., 6in, 9in).

MARGIN_LEFT: The inside margin or "gutter."

MARGIN_RIGHT / MARGIN_TOP / MARGIN_BOT: Outer margins.

### Structural Breaks
Control how new sections begin in the PDF:
- `CHAPTER_BREAK`: Set to `right` (standard), `left`, or `any`.

- `PART_BREAK`: Set to `right` (standard), `left`, or `any`.

### Typography

- `MAIN_FONT`: The primary serif font (e.g., `Linux Libertine O`).

- `MONO_FONT`: Used for code blocks (e.g., `DejaVu Sans Mono`).

- `LINE_SPACING`: Decimal value for leading (e.g., `1.15`).

- `PARAGRAPH_STYLE`: Set to `block` (spaced) or `indent` (first-line indent).

## Markdown Formatting Guide
Use these fenced divs to create standard book pages that are styled correctly in both PDF and EPUB.

### Copyright Page (Vertically centered, no page numbers)
```markdown
:::: {.copyrightpage}
Copyright © 2026 by Jane Doe. All rights reserved.
Published by Example Books.
:::
```

### Dedication Page (Italicized, offset from the top, no page numbers)
```markdown
:::: {.dedicationpage}
For my family, who supported me through this journey.
:::
```


### Table of Contents
To place your PDF Table of Contents precisely where you want it (instead of being forced to the very beginning), add this raw LaTeX block to your Markdown file:

```markdown
`​`​`{=latex}
\tableofcontents
`​`​`
```

### Advanced Page Headers
By default, the PDF engine automatically maps your top-level headings (`#`) to the `\leftmark` header variable and your second-level headings (`##`) to the `\rightmark` header variable.

If you want the body of the page to say "Chapter 1: Hello World", but you want the header at the top of the page to only say "Hello World", you can override the header text using a raw LaTeX command immediately after your heading:

#### For Parts or Top-Level Sections (`#`)
Use `\markboth{New Title}{}` to update the left-hand header:

````markdown
# Part One: The Journey Begins
```{=latex}
\markboth{The Journey Begins}{}
```
````


#### For Chapters or Sub-Sections (`##`)
Use `\markright{New Title}` to update the right-hand header:

````markdown
## Chapter 1: The Long Title
```{=latex}
\markright{Short Title}
```
````



## A Note on Book Covers (KDP, IngramSpark, etc.)

This toolchain is designed to generate a professional Interior Manuscript. For professional print-on-demand services like Amazon KDP:

1. **Interior (This Tool):** Use BuildBook to generate your finalized interior PDF.

2. **Spine Calculation:** Note your final page count.

3. **Check the Gutter:** As your book increases in page count, publishers require a larger inside margin (the gutter) to ensure text isn't lost in the binding.

   - **Automated Estimation:** When you run `buildbook`, the script provides a "Pre-Flight Estimate" of your page count based on character density and image frequency.  It cross-references this against industry standards (see [Amazon KDP Gutter Requirements](https://kdp.amazon.com/en_US/help/topic/G9776SBDU6CCM8KV)).

   - **Verify:** Check this estimate and ensure that your `MARGIN_LEFT` in `buildbook.conf` meets your publisher's minimum requirements for that specific page count.

4. **Cover Design (Separate):** Printed covers require a "full wrap" (Back + Spine + Front) designed as a single PDF. Use the [KDP Cover Calculator](https://kdp.amazon.com/cover-calculator) to download a template based on your page count.

5. **Digital Covers:** For EPUBs, you can simply add a `cover-image: "cover.jpg"` line to your `metadata.yaml`, and Pandoc will embed it as the digital cover.

## Uninstall
We get it — sometimes things aren't what they seem. If you installed `buildbook` and decided you want to uninstall it, you can run the `uninstall.sh` script directly from the repository:

```bash
wget -qO- https://raw.githubusercontent.com/ToddE/buildbook/main/uninstall.sh | bash
```
***Note:** This will not remove the installed dependencies or change your exported path settings.*

## Contributing & License

Contributions, updates, and improvements to the `buildbook` script are highly encouraged! We prefer that folks contribute their changes back to this repository so everyone can benefit from the improvements.

**License: Business Source License 1.1 (BSL)**

* **Permitted:** Personal, educational, and small-scale commercial use.

* **Gated:** Commercial use by entities exceeding **10 employees** OR **$200,000 USD** in annual gross revenue requires a separate agreement.

* **Automatic Conversion:** On March 24, 2030, this project automatically transitions to the **MIT License**.

See the [`LICENSE`](/LICENSE) file for full legal terms.
