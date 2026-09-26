# Status of the GIMP 3 plug-in work

Where everything stands, and what comes next. Last updated 2026-09-26 (overnight).

## The plan

Plug-ins many of us used in GIMP 2 and that have not reached GIMP 3:

- A) port the abandoned ones, and fix what is wrong with them;
- B) offer the work upstream where that is possible;
- C) port them properly: 16-bit and float images, GIMP 3 dialogs, no
  8-bit shortcuts;
- D) host everything on github.com/sandbranch (public), and open the
  upstream pull requests from there.

GIMP 3 has non-destructive filters (live preview, editable later) only for
GEGL operations, not for plug-ins. So where it fits, a filter exists in
both forms: the ported plug-in (for upstream and GIMP 2 habits) and a GEGL
operation (the future).

## Repositories

All under `~/store/code/sandbranch`, pushed to github.com/sandbranch.

| Repo | What | Branch | State |
|---|---|---|---|
| gimp-plugin-devtools | build and test scripts for all of them (this repo) | main | done; used by all builds below |
| gimp-wavelet-denoise | Wavelet Denoise plug-in, ported | gimp3 (default), gimp3-upstream | works, 16-bit and float; not yet offered upstream |
| gimp-wavelet-sharpen | Wavelet Sharpen plug-in, ported | gimp3 (default), gimp3-upstream | works; not yet offered upstream |
| gegl-wavelet | `wavelet:sharpen` and `wavelet:denoise` as GEGL operations | main | work, same output as the plug-ins; installed and in use |
| gimp-lqr-plugin | Liquid Rescale | gimp3 (default) | works; builds liblqr itself (meson subproject); polish open |
| GIMP-Lensfun | lens correction with the Lensfun database, plug-in and GEGL filter | gimp3 (default) | rewritten for GIMP 3; lensfun:correct keeps it editable; installed |
| gegl-underwater | underwater filters: marine snow removal (works), color correction (first version works) | main | both tested; color tuned on 42 Commons photos |
| gimp-plugin-bimp | BIMP, batch processing | gimp3 (default) | ported; 31 batch tests pass; window tested; installed |
| gegl-depth-blur | Depth Blur: blur by a depth map (successor to Focus Blur) | main | first version works (command line and GIMP); on GitHub |
| gimp-lqr-paint | Liquid Rescale Paint: seam carving with keep (green) and remove (red) painted in its dialog, live preview | main | first version works; 38 GIMP cases + 26 unit tests pass, also under ASan; dialog tried on Broadway |

The branch `gimp3-upstream` is the port without the "this is a fork" note
in the README, ready for an upstream pull request.

Installed locally: GEGL operations `wavelet-denoise.so` and
`wavelet-sharpen.so` (the wavelet plug-ins are uninstalled on purpose; the
GEGL versions are the ones in use), plug-ins `gimp-lensfun` and
`gimp-lqr-plugin`.

## Rebuilding everything

Everything builds from a fresh clone; nothing lives outside the repos.
With the Flatpak GIMP, from each repo's folder
(`gimp-build.sh` is in this repo):

    # plug-ins
    gimp-build.sh . meson setup build -Dplugindir=\$GIMP_PLUGINDIR
    # (gimp-lqr-plugin calls the option -Dgimp_plugindir)
    gimp-build.sh . ninja -C build install

    # GEGL operations (gegl-wavelet, gegl-underwater)
    gimp-build.sh . meson setup build -Dmoduledir=\$GEGL_OPDIR
    gimp-build.sh . ninja -C build install

Restart GIMP afterwards. The script says how to install the GNOME SDK if it
is missing. For testing dialogs without a screen, see `gui/cdp.mjs` in the
README.

## Overnight queue (2026-09-25, from David)

In this order, each committed in its own repo as it goes:

1. **BIMP** port to GIMP 3 (`gimp-plugin-bimp`, branch `gimp3`, on github.com/sandbranch/gimp-plugin-bimp). No one else has started one: upstream
   is silent since 2023, `v3-dev` is older than master, no forks have
   GIMP 3 work. Adds a non-interactive procedure that runs a saved
   `.bimp` set on files, which also makes it testable headlessly.
2. **Marine snow**: `underwater:marine-snow` in gegl-underwater (PLAN 4b). Done:
   Filters > Enhance > Remove Marine Snow..., tested on a synthetic scene
   and in GIMP; next is real photos.
3. **Lensfun as a GEGL filter** (live preview, non-destructive). Done:
   `lensfun:correct` in the GIMP-Lensfun repo (shares the correction code);
   the plug-in adds it with the Exif settings ("Keep as an editable
   filter"). tests/compare.sh: plug-in and filter agree.

## Next: gegl-underwater

This is the one in progress. Its own `PLAN.md` has the full list.

Done (2026-09-26): the color correction `underwater:correct` works in a
first version (milestones 1 to 3). Test photos: 42 freely licensed ones
from Wikimedia Commons, listed in `tests/images/manifest.json` and
downloaded with `tests/images/fetch.py` (the photos are not committed).
`tests/run.sh` writes before/after sheets and measurements;
`tests/gimp-test.sh` checks the filter non-destructively in GIMP (same
result as the command line). The pipeline as built, and where it
differs from the papers, is in `docs/design.md`.

Next, in order:

1. The known issues in `docs/design.md`. Fixed since the first version
   (a water color map, Oklab keep water, p = 2 white balance): green
   sunlit water, lavender blue water, khaki murk. Left: a gray reef in
   very green water (ambient-green-08), glow around subjects, a gray
   shark going warm, speed (about 4 s on 24 MP). `tests/compare.py a b`
   puts runs side by side.
2. Real dive photos from David, to check against the Commons set.
3. SQUID (Berman et al.) color charts as an accuracy test.
4. Milestone 4b: "reduce red noise" with the wavelet denoise algorithm;
   marine snow on real photos. (The Farhadifard rule and the patent
   check are in `docs/research.md`: the marine snow patents need video.)

Patents to keep clear of, with the reasons, are in `docs/design.md` and
`docs/research.md`. Any change to the pipeline is checked against them.

## Paused here (2026-09-26): gimp-lqr-paint

The user's idea: a Liquid Rescale window with a small view of the image,
green Keep and red Remove buttons to paint with, and the controls around
it. Built as a new plug-in on liblqr (repo gimp-lqr-paint), not in the
ported gimp-lqr-plugin. Done and pushed:

- `src/carve.c` (seam carving on float buffers, masks and extra images
  carved along, restore size, cancellable) and `src/masks.c` (painting,
  resampling, undo), both with unit tests; liblqr built in with a patch
  for a leak in its carver lists (report upstream).
- The plug-in: `plug-in-lqr-paint`, Layer > Liquid Rescale Paint...; masks
  stored as hidden layers found by a parasite, carved along; one undo
  step; all precisions, gray, alpha, layer masks.
- The dialog: Keep, Remove, Eraser (right button too), brush, undo,
  clear, live result carved in a thread, Size to remove the red, Restore
  the original size, Fine tune. First run on Broadway worked
  (docs/dialog-remove.png, docs/result.png).

Next, to look at together with the user:

1. The dialog on a real photo (`tests/gui/start.sh photo.jpg`) and the
   layout at other screen sizes; whether the result view should be on
   the right or switchable.
2. Done: `tests/gui/gui-test.sh` paints, sizes and rescales on Broadway
   and checks the result (6 checks pass). The dialog now starts at the
   layer's size instead of the last run's.
3. Translations (po/ is set up, no languages yet; Swedish first?).
4. Keyboard shortcuts (K, R, E, Ctrl+Z), and a keep/remove brush of
   softer edges if needed.

## Audit (2026-09-26)

Every repo was reviewed for bugs, and each has a pass/fail test suite
that runs with one command, without a display or network, in a
throwaway GIMP profile (`GIMP3_DIRECTORY`), and under AddressSanitizer
and UBSan (the Flatpak SDK has the runtimes; `flatpak run --devel`).

| Repo | Real bugs fixed | Checks |
|---|---|---|
| gegl-wavelet | CIELAB NaN, abort on unbounded input, zero settings changed the image, abort without memory | 116 (`tests/run.sh`) |
| gimp-wavelet-denoise | YCbCr round trip not exact, CIELAB NaN, indexed/groups/locked layers "succeeded" | 233 (`tests/run.sh`) |
| gimp-wavelet-sharpen | YCbCr round trip, indexed/groups/locked layers | 209 (`tests/run.sh`) |
| GIMP-Lensfun | uninitialized Lanczos table, arbitrary lens guessed, positions up to 0.3 px off, stale filter cache, database not thread safe, gray path, groups | 50 (`tests/run.sh`) |
| gimp-lqr-plugin | rigidity and enlargement step ignored, masks by name never found, Repeat always 100x100, seam colour crash, no translation, 1 px crash in liblqr, new-image masks | 74 (`tests/run.sh`, `--asan`) |
| gimp-plugin-bimp | crash on header-less .bimp, repeated manipulations, reads past arrays, use-after-free in curves, alpha added to every PNG/TIFF/WebP, GIF always failed, metadata dropped, errors counted as success | 70 plus unit tests (`tests/run.sh`, `BIMP_SANITIZE=1`) |
| gegl-depth-blur | result depended on tiling and threads, highlights and depth in the wrong color space, rotation reversed, NaN spread | 114 (`tests/run.sh`) |
| gegl-underwater | heap overflow on thin images, one NaN pixel spoiled all, marine snow depended on tiling, hang on unbounded input | 25 + 8 (`tests/check.sh`, `tests/gimp-check.sh`) |
| gimp-plugin-devtools | flatpak info translated labels broke the version, `$*` quoting, wrong key codes | 179 (`tests/run.sh`) |

Open decisions from the audit:

- Tests on `gimp3-upstream` of the wavelet plug-ins (that branch had none).
- Wavelet: YCbCr/CIELAB constants inherited from GIMP 2 (small drift in
  the GEGL ops; CIELAB assumes sRGB); colour not premultiplied by alpha.
- Lensfun filter keeps two full float copies and ignores the zoom level.
- LQR: `batch/batch-gimp-lqr.scm` is GIMP 2 Script-Fu (port or drop);
  licence headers missing in some UI files; report the liblqr 1 px
  out-of-bounds read upstream.
- BIMP: same file name from two input folders overwrites or is skipped;
  skipped files count as processed (both upstream behaviour).
- Depth Blur is slow in small render pieces (a cached region rounded to
  the tile grid would help); report GEGL's `get_source_space` ignoring
  its pad argument upstream.
- Underwater: alpha is ignored in the estimates; backscatter 0 still
  changes the photo; open water gets darker by default.

## Candidates for later

[docs/candidates.md](docs/candidates.md) (2026-09-26): a fact-checked
sweep of abandoned GIMP 2 plug-ins that still have an unmet need in GIMP
3, ranked, with licenses read from the sources, plus what exists for HDR
merging, focus stacking and stitching. Nothing chosen yet.

## Other open items

- **Tests in the repos** (done 2026-09-26): every repo has `tests/run.sh`
  (GIMP-Lensfun `tests/compare.sh`), which runs headless in the Flatpak
  GIMP and checks results.
- **Upstream pull requests.** Wavelet Denoise: upstream already has a
  pull request #6 by Arvil (8-bit only); plan is to open ours from
  `gimp3-upstream` and comment on #6. Wavelet Sharpen: open from
  `gimp3-upstream`. LQR and Lensfun: after the polish below.
- **Menu labels**: the wavelet plug-ins use the old style ("Wavelet
  sharpen ...") instead of GIMP 3 Title Case ("Wavelet Sharpen..."); both
  versions sit in Filters > Enhance. Sharpen's default amount to review.
- **Liquid Rescale polish**: done (license string, `-DDEBUG`, deprecated
  GTK stock items, help registration and per-language help install).
- **Packaging**: release tarballs, and Flatpak packages so the filters
  work on other computers with Flatpak GIMP. Postponed until the filters
  settle.
- **Focus Blur** became the GEGL filter Depth Blur, `depth:blur`
  (gegl-depth-blur, 2026-09-25): no plug-in port, since its upstream
  is gone and a GEGL filter covers it. Its own `PLAN.md` has the next
  steps; first, look at the dialog in GIMP. GIMP merges filters with an aux input on OK
  (a TODO in GIMP), so it is not kept as an editable filter.
- **BIMP** (2026-09-25/26): ported to GIMP 3, with a new non-interactive
  `plug-in-bimp-batch`. Open: a manipulation for GIMP 3's filters, which
  are GEGL operations and not procedures, so "Other GIMP procedure..."
  cannot list them (GimpDrawableFilter with its config would do it); the
  Windows installer (`nsis/`); offering the port upstream (no reply from
  the author since 2023, issue #420).

## Things learned the hard way

- `gimp_procedure_dialog_fill_box_list(..., NULL)` means *all*
  arguments; a custom box needs a hidden placeholder label.
- `GEGL_PATH` replaces GEGL's default path, and meson's JSON files in a
  build folder crash GEGL: for command line tests, copy the `.so` into a
  clean folder and use `GEGL_PATH=<folder>:/app/lib/gegl-0.4`.
- Paper summaries from web tools have invented content: read the PDF
  itself (`pdftotext`, or the page images for scanned patents).
