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
| gegl-underwater | underwater filters: marine snow removal (works), color correction (skeleton) | main | marine snow done and tested; color waits on photos |
| gimp-plugin-bimp | BIMP, batch processing | gimp3 (default) | ported; 31 batch tests pass; window tested; installed |
| gegl-depth-blur | Depth Blur: blur by a depth map (successor to Focus Blur) | main | first version works (command line and GIMP); on GitHub |

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

This is the one in progress. Its own `PLAN.md` has the full list; in order:

1. **Test photos (waiting on David).** Put them in `tests/images/` (not
   committed without the photographer's permission; the README there
   lists what helps). Also useful to know per photo: where the dive was,
   camera and raw or JPEG, strobe or ambient light.
2. `tests/run.sh`: before/after sheets and simple measurements per photo.
3. Milestone 2: statistics, red restoration (Ancuti Eq. 4, verified
   against the paper), white balance. Then milestone 3: water color,
   backscatter, keep water color.
4. Milestone 4b: "reduce red noise" with the wavelet denoise algorithm,
   and a separate `underwater:marine-snow` operation. The speck detection
   rule of Farhadifard et al. 2017 and the patent check are done and
   written up in `docs/research.md`: the only marine snow patents
   (US 11,710,245 and US 12,217,439) need optical flow between video
   frames, so a single-photo filter is outside them.

Patents to keep clear of, with the reasons, are in `docs/design.md` and
`docs/research.md`. Any change to the pipeline is checked against them.

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
- **Liquid Rescale polish**: the license string and `-DDEBUG` are fixed;
  still open: the port dropped the help registration, and
  `GTK_STOCK_EDIT` / `GTK_STOCK_NEW` in `src/page_advanced.c` are
  deprecated stock icons.
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
