# LaTeX source templates

- `preamble.tex`: your existing preamble, preserved unchanged.
- `initial.tex`: your original starter document from `Bolig 2/tex/bolig2.tex`,
  preserved unchanged, including its example title.

The installer links this directory to `~/.config/tex`.
Copy a template into a new project before editing it:

```sh
cp ~/.config/tex/initial.tex ./main.tex
pdflatex main.tex
```

`initial.tex` is self-contained and does not load `preamble.tex`.
The separate preamble has its own package choices, Dutch language setting,
and author setting; review these before using it in another document.
Do not simply combine both package lists, as their options may conflict.

To use the standalone preamble in a different document, copy it to that
project and place `\input{preamble}` after the document class and before
`\begin{document}`. A TeX installation with the preamble's packages is required.
