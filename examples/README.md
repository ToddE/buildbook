# BuildBook Examples
This directory contains a complete, minimal working example to help you get started with BuildBook.

## Files in this Example
- `sample-book.md`: The manuscript. Notice the use of the `{.copyrightpage}` and `{.dedicationpage}` blocks, as well as the explicit `\tableofcontents` placement.
- `metadata.yaml`: The book's core metadata.
- `buildbook.conf`: The layout configuration for print and digital.
- `style.css`: The stylesheet for the EPUB output.

## How to Run the Example
From the root directory of the repository, run:
```bash
./buildbook.sh examples/sample-book.md all -c examples/buildbook.conf
```

Check the `out/` directory in the root of the project to see your generated `sample-book.pdf` and `sample-book.epub` files.

## Controlling Page Headers (Parts and Chapters)

By default, the PDF engine maps your top-level headings (`#`) to the `\leftmark `variable and your second-level headings (`##`) to the `\rightmark` variable.

If you use `#` for Parts and `##` for Chapters, writing `` Chapter 1: Hello World` will normally inject that entire string into your page header.

If you want the body of the page and the Table of Contents to say "Chapter 1: Hello World", but you want the header at the top of the page to only say "Hello World", you can override the header text using a raw LaTeX command immediately after your heading:

```markdown
## Chapter 1: Hello World
`​`​`{=latex}
\markright{Hello World}
`​`​`
```

- `\markright{...}`: Overrides the `\rightmark` (used for `##` headings).

- `\markboth{...}{}`: Overrides the `\leftmark` (used for `#` headings).

## Images and Page Breaks

BuildBook fully supports standard Markdown images. Additionally, inserting a horizontal rule (`---`) creates a page break in your document.

This combination can be used for specific pacing and layout requirements. For example, if you wanted to mock up a children's book where images always appear on the left page and text on the right, you could alternate images and text separated by page breaks:

```markdown
![A little fox sleeping](fox.jpg)

---

The little fox was very tired after a long day of playing.

---

![A bear catching a fish](bear.jpg)

---

Meanwhile, the bear was busy looking for dinner.
```


***Note:** While you can use BuildBook for this kind of alternating image/text layout, the toolchain is primarily optimized for text-heavy manuscripts like novels, manuals, or technical books. It might not be the best tool for producing highly visual, complex, or image-dominant layouts like a final children's book.*

## Example File Templates
If you are starting a new project from scratch, you can copy these files as a baseline.

1. `metadata.yaml`
```yaml
---
title: "The Art of the Build"
author: "A. Developer"
publisher: "Open Source Press"
date: "2026"
lang: en-US
---
```

2. buildbook.conf
```bash
# --- PDF Page Layout ---
TRIM_SIZE="6x9"
PAPER_W="6in"
PAPER_H="9in"
MARGIN_TOP="0.75in"
MARGIN_BOT="0.75in"
MARGIN_LEFT="0.75in"
MARGIN_RIGHT="0.5in"

# --- Typography ---
FONT_SIZE="11pt"
LINE_SPACING="1.15"
MAIN_FONT="Linux Libertine O"

# --- Page Headers & Footers ---
HEADER_EVEN_LEFT="\thepage"
HEADER_EVEN_RIGHT="\textit{\leftmark}"
HEADER_ODD_LEFT="\textit{\rightmark}"
HEADER_ODD_RIGHT="\thepage"
HEADER_RULE_WIDTH="0.4pt"

# --- Structural Breaks ---
PART_BREAK="left"     # Parts start on left pages
CHAPTER_BREAK="right" # Chapters start on right pages

# --- EPUB Specifics ---
EPUB_STYLESHEET="examples/epub-style.css"
EPUB_TOC_DEPTH="2"
```

3. `sample-book.md`
```markdown
# Title Page Info 

::: {.copyright}
Copyright © 2026 by A. Developer. All rights reserved.

Published by Open Source Press
:::

::: {.dedication}
For the open source community.
:::

`​`​`{=latex}
\tableofcontents
`​`​`

# Part One: The Beginning

## Chapter 1: Hello World

This is the first paragraph of the book. Because of our `buildbook.conf` settings, this chapter will automatically start on a right-hand page in the PDF.
```

4. `style.css`
```css
/* Core text */
body {
  font-family: Georgia, serif;
  line-height: 1.6;
  margin: 1em;
}

/* Custom environments */
.copyrightpage {
  margin-top: 30%;
  font-size: 0.85em;
  text-align: center;
  page-break-before: always;
}

.dedicationpage {
  text-align: center;
  margin-top: 30%;
  font-style: italic;
  page-break-before: always;
  page-break-after: always;
}
```
