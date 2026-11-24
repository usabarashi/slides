#!/usr/bin/env bash
# Build the self-contained Reveal.js deck.
#
# `quarto render` occasionally emits an HTML that links `slides_files/` instead
# of inlining the assets, even with `self-contained: true`. The first render
# after an edit is the one that tends to do it; the next render inlines
# correctly, so this script retries once.
#
# The checks below cover the reference forms this deck actually uses
# (relative `slides_files/` paths, `<script src>` / `<img src>` URLs, and
# `url(...)` in CSS). They are a string inspection of the generated HTML, not
# a proof that the page has no network dependency at runtime.
set -euo pipefail
cd "$(dirname "$0")"

render_once() {
  rm -rf slides_files .quarto
  quarto render slides.qmd --to revealjs
}

has_no_known_external_refs() {
  ! grep -q 'slides_files' slides.html \
    && ! grep -q 'src="http' slides.html \
    && ! grep -q '<link[^>]*href="http' slides.html \
    && ! grep -q 'url(http' slides.html
}

render_once
if ! has_no_known_external_refs; then
  echo "warning: external references remained; retrying once" >&2
  render_once
fi

if ! has_no_known_external_refs; then
  echo "error: slides.html still references external files or URLs" >&2
  exit 1
fi

echo "ok: known external refs absent ($(wc -c < slides.html | tr -d ' ') bytes)"
