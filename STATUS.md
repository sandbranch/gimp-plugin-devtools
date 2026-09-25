# Status of the GIMP 3 plug-in work

Where everything stands, and what comes next. Last updated 2026-09-25.

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
| GIMP-Lensfun | lens correction with the Lensfun database | gimp3 (default) | rewritten for GIMP 3, works, installed |
| gegl-underwater | original underwater color correction filter | main | skeleton, research and design done; no processing yet |

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

- **Test scripts into the repos.** The functional tests used during the
  ports (e.g. LQR's 16-bit check) are not yet committed; each plug-in
  should get a `tests/` folder.
- **Upstream pull requests.** Wavelet Denoise: upstream already has a
  pull request #6 by Arvil (8-bit only); plan is to open ours from
  `gimp3-upstream` and comment on #6. Wavelet Sharpen: open from
  `gimp3-upstream`. LQR and Lensfun: after the polish below.
- **Menu labels**: the wavelet plug-ins use the old style ("Wavelet
  sharpen ...") instead of GIMP 3 Title Case ("Wavelet Sharpen..."); both
  versions sit in Filters > Enhance. Sharpen's default amount to review.
- **Liquid Rescale polish**:
  - `meson.build` says `GPL-3.0-or-later`, but COPYING and the sources
    are GPL 2 or later: fix the license string;
  - `-DDEBUG` is always on in `meson.build`;
  - the port dropped the help registration;
  - `GTK_STOCK_EDIT` / `GTK_STOCK_NEW` in `src/page_advanced.c` are
    deprecated stock icons; use icon names.
- **Packaging**: release tarballs, and Flatpak packages so the filters
  work on other computers with Flatpak GIMP. Postponed until the filters
  settle.
- **Not started**: BIMP (batch processing) and Focus Blur.

## Things learned the hard way

- `gimp_procedure_dialog_fill_box_list(..., NULL)` means *all*
  arguments; a custom box needs a hidden placeholder label.
- `GEGL_PATH` replaces GEGL's default path, and meson's JSON files in a
  build folder crash GEGL: for command line tests, copy the `.so` into a
  clean folder and use `GEGL_PATH=<folder>:/app/lib/gegl-0.4`.
- Paper summaries from web tools have invented content: read the PDF
  itself (`pdftotext`, or the page images for scanned patents).
