# LaTeX Templates

Templates for articles, posters, and presentations, sharing one set of notation macros and one set of institution branding.

```
Latex-Templates/
├── shared/                               <- registered as a MiKTeX root
│   └── tex/latex/jaj/
│       ├── common/                       copied into every project
│       │   ├── jaj-macros.sty            notation only; safe in any class
│       │   └── jaj-theorems.sty          theorem environments (articles)
│       ├── institutions/                 copied into beamer projects
│       │   ├── uwmadison/
│       │   │   ├── jaj-inst-uwmadison.def    colors, font, logo names
│       │   │   ├── UW_crest.pdf              crest: frame titles, poster header
│       │   │   └── UW_main_compact_white.pdf crest + name: title slide
│       │   └── generic/
│       │       └── jaj-inst-generic.def      neutral starting point
│       └── beamer/                       copied into beamer projects
│           ├── jaj-branding.sty          loads an institution: colors, font, logos
│           ├── beamerthemejajtalk.sty    slide layout
│           ├── beamerthemejajposter.sty  poster layout
│           ├── beamerinnerthemejaj.sty   blocks, lists, theorems (shared)
│           └── beamercolorthemejaj.sty   maps institution colors onto beamer
├── article/
├── poster/
├── presentation/
└── new-project.sh                        start a new project (run in WSL)
```

## One-time setup (Windows, MiKTeX, TeXstudio)

These instructions are for using the templates on Windows (with WSL) using MikTeX and compiling in TeXstudio.  Anyone using a different set up may need to follow a different process.

1. **Register the shared folder.** MiKTeX Console → Settings → Directories → **+** → `Latex-Templates\shared`. <br>
   Then Tasks → **Refresh file name database**. <br>
   Check with `kpsewhich jaj-branding.sty` in a Windows terminal.
2. **Install Perl** (Strawberry Perl) and the MiKTeX `latexmk` package.
3. **TeXstudio:** Options → Configure TeXstudio → Build → Default Compiler = **Latexmk**. Then F5 (Build & View) is all you need.
4. **MiKTeX Console:** Settings → General → install missing packages on-the-fly = **Always**.

Refresh the MiKTeX file name database whenever you **add** a file under `shared/` (e.g. a new institution or a logo). Edits to existing files are picked up immediately.

## Starting a project (WSL)

```bash
cd /mnt/c/path/to/Latex-Templates
bash new-project.sh article ~/research/my-paper
bash new-project.sh poster /mnt/c/Users/jacob/Research/jsm-poster
bash new-project.sh presentation /mnt/c/Users/jacob/Research/lightning-talk
bash new-project.sh poster 'C:\Users\jacob\Research\jsm-poster' poster   # Windows path, custom main-file name
```

The script copies the template, renames it to `main.tex` (or the third argument), copies a **snapshot** of the shared files into the project, and creates an empty `references.bib`. TeX uses the project's copies before the MiKTeX root, so a finished project never changes when you edit `shared/`.

Put projects you will compile from Windows on the Windows side (`/mnt/c/...`), since TeXstudio and MiKTeX cannot easily see files inside the WSL filesystem.

## Posters

- **Size:** choose a `beamerposter` line at the top of the template. `size=a0` alone is landscape.
- **Columns:** `\jajcolumns{n}` and `\jajcolumnsep{0.025}` in the preamble; in the body, `postercolumns` with `\separatorcolumn` between columns only.
- **Blocks:** `block` (filled title bar), `alertblock` (key result, shaded), `exampleblock` (quiet: references, QR code).
- **Logos:** the institution crest is on the right by default. `\logoright{}` removes it; `\logoleft{...}` adds another; `\setlength{\jajlogoheight}{6cm}` resizes.

## Presentations

- **Theme options:** `\usetheme[institution=uwmadison, nologo, nosectionslides, noslidenumbers]{jajtalk}` (all optional). <br>
  By default: crest in each frame title, a full-color slide  at every `\section`, and `n / total` in the footer.
- **Title slide:** `\title[short]{full}` (the short title goes in the footer), `\subtitle`, `\author`, `\institute`, `\event{...}`, `\date`.
- **Blocks and theorems** look the same as on posters (shared inner theme).
- **Backup slides:** put them after `\appendix`; they are not counted in the slide total.
- **Draft mode:** `\draftmodetrue` shows `\todo{...}` in red; `\draftmodefalse` hides them but lists each one in the log.
- **Aspect ratio:** `aspectratio=169` (widescreen) in `\documentclass`; use `43` for old projectors.

## Logos

The UW logo files are in `institutions/uwmadison/`. They are UW trademarks; follow the usage guidelines at brand.wisc.edu. If a logo file is missing, the templates build without it and the log says so. To use different files, change `\jajInstLogo` (the mark) and `\jajInstLogoWide` (mark + name) in the institution's `.def`.

## Switching institutions

1. Copy the `institutions/uwmadison/` (or `generic/`) folder to `institutions/<name>/` and rename the `.def` inside to `jaj-inst-<name>.def`.
2. Change the six colors, the font package (`\jajInstFonts`), and the two logo file names (put the logo files in the same folder, with names that won't clash with another institution's, e.g. a prefix like `UW_`). Keep all six color names; the themes use nothing else.
3. Refresh the MiKTeX file name database.
4. In a poster or talk: `\usetheme[institution=<name>]{jajposter}` or `\usetheme[institution=<name>]{jajtalk}`.

## Editing shared files

Bump the date in the `\ProvidesPackage` / `\ProvidesFile` line whenever you change a shared file. It is printed in every log and by `new-project.sh`, so you can tell which version a project has.

Article load order (see comments in `jaj-theorems.sty`): `amsthm` → `jaj-macros` → … → `hyperref` → `cleveref` → `jaj-theorems`.

The poster theme is derived from the Gemini theme by Anish Athalye (MIT License); the notice is kept in `beamerthemejajposter.sty`.

## Fonts

Everything compiles with pdfLaTeX using fonts included in MiKTeX: Latin Modern for articles and math, Helvetica for posters and talks. To change an institution's sans-serif font, edit `\jajInstFonts` in its `.def`.

## Troubleshooting

- **Build stuck after an error** (often a bad `.bib` entry): TeXstudio → Tools → **Clean Auxiliary Files**, then F5.
- **`$'\r': command not found`** when running the script: it was checked out with Windows line endings. `.gitattributes` prevents this for fresh clones; to fix an existing copy, run `sed -i 's/\r$//' new-project.sh`.
