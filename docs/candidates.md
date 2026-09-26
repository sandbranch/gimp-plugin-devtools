# Abandoned GIMP 2 plug-ins with an unmet need in GIMP 3: a fact-checked sweep

Date of research: 2026-09-26. Current GIMP: 3.2.6 (2026-09-10); 3.2.0 was released 2026-03-14.

Excluded as already done or in progress: Wavelet Denoise, Wavelet Sharpen, Liquid Rescale, GIMP-Lensfun, BIMP, Focus Blur (Depth Blur), underwater correction and marine snow. Also excluded: G'MIC, Jigsaw. Resynthesizer facts are in the "checked and not needed" section.

Everything below was checked against primary sources (source headers, LICENSE files, git history, package trackers, GitHub/GitLab/AUR APIs, the GIMP and GEGL source trees at current master). Items that could not be checked are marked **UNVERIFIED**.

## 0. Cross-cutting facts that shape the whole list

1. **Why old scripts are broken, not just old.** GIMP 3.0 removed the `plug_in_compat.pdb` wrappers (`plug-in-gauss`, `plug-in-unsharp-mask`, `plug-in-colors-channel-mixer`, `plug-in-mblur`, `plug-in-edge`, `plug-in-sobel`, `plug-in-hsv-noise` and others): present at tag `GIMP_2_10_38`, absent at `GIMP_3_0_0` and `GIMP_3_2_0`. The GIMP 3.2 `scripts/init/plug-in-compat.scm` is "INTENDED TO BE EMPTY FOR GIMP 3.0". `gimp-image-get-active-layer` is gone too. So Script-Fu is not "a few changes": 72 of 121 FX Foundry scripts, 18 of 24 elsamuko scripts, Smart Separate Sharpen and layerfx.py all call removed procedures. Python 2 GimpFu is simply gone.
2. **Distro packaging collapsed.** Debian `gimp-plugin-registry` 9.20240808 is sid-only, removed from testing 2024-09-25, with an unsatisfiable `libgimp2.0-dev` build dependency (https://tracker.debian.org/pkg/gimp-plugin-registry). Its bundle list (from `debian/control` in https://salsa.debian.org/debian/gimp-plugin-registry): DBP, add-filmgrain, btn4ws, bw-simulation, cmyk-tiff-2-pdf, contact-sheet, diana-holga2, elsamuko, exposure-blend, ez-perspective, fix-ca, gimp-fx-foundry, gimp-mask, hdroberts-tone-adjust, layer-effects, lqr, openraster, planet-render, resynthesizer, safe-for-web, separate+, smart-seperate-sharpen, streak, traditional-orton, wavelet-denoise. Fedora retired (per each `dead.package`): save-for-web ("replaced by Gimp built-in export"), separate+ ("Obsolete add-on for GIMP 3"), lensfun, lqr-plugin, wavelet-decompose, layer-via-copy-cut, dds-plugin, wavelet-denoise-plugin, normalmap, focusblur, gimp-gap, dbp. Many AUR packages still declare `depends=('gimp')` while building against `gimptool-2.0`, so they are silently broken on Arch's GIMP 3.
3. **Flathub reality check.** Of the `org.gimp.GIMP.Plugin.*` repos, only **GMic, Resynthesizer and Fourier** have a manifest with `"branch": "3"` (GIMP 3). BIMP, Lensfun, LiquidRescale and FocusBlur are `"branch": "2-40"` only, last pushed 2024-03. A widely read blog post (marcrphoto.wordpress.com, 2025-12-10) claims BIMP, LQR and NormalMap are available for GIMP 3 on Flatpak; the manifests show that is wrong for BIMP and LQR.
4. **pgei.de "for GIMP 3.2" labels are false.** Its SeparatePlus download is a 2018 Win64 build linked to `libgimp-2.0-0.dll`; its "Save for Web" is a 32-bit exe linked to `libgimp-2.0-0.dll`; its Smart Separate Sharpen is byte-identical to the 2012 V2.8 script. None can run on GIMP 3.
5. **GEGL filters with an aux input are forced destructive in GIMP today.** Verified in GIMP master `app/tools/gimpfiltertool.c`: if the op has an `aux` pad, `merge_filter = TRUE` with the UI reason "Disabled because this filter depends on another image" (a TODO says this lifts once GimpDrawable can be serialized). GIMP's operation tool does create pickers for any number of `aux`, `aux2`, `aux3`... pads (`gimpoperationtool.c`, regex `^aux(\d*)$`). Consequence: single-input filters (sharpeners, scalers, colour ops) get full non-destructive editing; multi-image ops (exposure fusion, focus stacking) can be GEGL ops but will apply destructively until GIMP fixes that TODO.
6. **G'MIC-Qt passes float data to GIMP 3** (`src/Host/Gimp/host_gimp.cpp` uses `R'G'B'A float` formats), so G'MIC coverage is high bit depth, but it is always destructive and lives in one big dialog.

## 1. Ranked candidates

Score = need (0 to 3) x popularity (1 to 3) / effort (small 1, medium 2, large 3). Scores are a judgement aid, not a measurement.

| # | Candidate | Need | Pop | Effort | Score | Best fit |
|---|---|---|---|---|---|---|
| 1 | Error Level Analysis (GIMP-ELA / elsamuko ELA) | 3 | 2 | S | 6.0 | Plug-in (+ tiny GEGL diff op) |
| 2 | Ofnuts path tools (unported half) | 2 | 3 | S | 6.0 | Plug-ins (coordinate with author) |
| 3 | Pixel art scalers (hqx, xBR) | 3 | 2 | S/M | 4.0 | GEGL ops + plug-in |
| 4 | Saturation Equalizer + Advanced Unsharp Mask (Tibor Bamhor) | 3 | 2 | S/M | 4.0 | GEGL ops |
| 5 | Save for Web | 3 | 3 | M/L | 3.6 | Plug-in |
| 6 | Exposure fusion (Mertens) + focus stacking, replacing Exposure Blend | 3 | 2 | M | 3.0 | GEGL op(s) + plug-in front end |
| 7 | Refocus (FIR Wiener deconvolution) | 2 | 3 | M | 3.0 | GEGL op |
| 8 | PhotoRestore (faded dye restoration) | 3 | 2 | M | 3.0 | Plug-in, later GEGL op |
| 9 | gimp-data-extras (official graveyard) port and release | 2 | 3 | M | 3.0 | Script-Fu v3 / Python 3, upstream MR |
| 10 | Smart Separate Sharpen | 2 | 1.5 | S | 3.0 | GEGL op/graph |
| 11 | Contact Sheet | 1.5 | 2 | S | 3.0 | Plug-in |
| 12 | APNG export | 1.5 | 2 | S | 3.0 | Upstream file-png or plug-in |
| 13 | DCamNoise2 | 2 | 2 | S/M | 2.7 | GEGL op |
| 14 | DivideScannedImages | 2 | 2 | S/M | 2.7 | Plug-in |
| 15 | Separate+ (plate-level CMYK, spot, GCR/UCR) | 2 | 3 | L | 2.0 | Plug-in + GEGL GCR op |
| 16 | User Filter (Filter Factory) | 2 | 2 | M | 2.0 | Plug-in (maybe GEGL) |
| 17 | Fix-CA as a non-destructive op | 1 | 2 | S | 2.0 | GEGL op |
| 18 | Automatic line-based perspective ("upright") | 3 | 1.5 | M/L | 1.8 | Plug-in using GEGL |
| 19 | Valve VTF format (gimp-vtf) | 2 | 1.5 | M | 1.5 | File plug-in |
| 20 | MathMap | 1.5 | 1.5 | L | 0.75 | Plug-in |

### 1. Error Level Analysis (GIMP-ELA; elsamuko ELA)
- **What:** JPEG error level analysis for image forensics: re-encode at a known quality, amplify the difference to show edited regions.
- **Author and license:** GIMP-ELA by Alfredo Torre, `plugin-ela.py` "The MIT License (MIT) Copyright (c) 2012-2013 Alfredo Torre", MIT LICENSE file (https://github.com/sentenza/GIMP-ELA). elsamuko's `elsamuko-error-level-analysis.scm`: "Copyright (C) 2010 elsamuko", GPL-3+.
- **Last activity:** GIMP-ELA 2018-10-02; elsamuko ELA script 2014-12-07.
- **Popularity:** GIMP-ELA 75 stars, 13 forks, open issue #3 "Will not work in Gimp 3.04 Apple M1" (2025-09). elsamuko script shipped in Debian's registry bundle. SourceForge "Gimp Forensics" (ELA + JPEG ghost, GIMP 2) 1,601 downloads.
- **GIMP 3 status:** no port found; not native; no ELA in G'MIC stdlib. elsamuko's in-progress `gimp-3` branch still has the old `file-jpeg-save` call in the ELA script.
- **Need:** yes (niche but steady: journalism, education, forensics hobbyists), fully unmet.
- **Effort/fit:** small. Plug-in (needs a JPEG encode round trip via `file-jpeg-export` to a temp file, then a Difference layer); the amplify step could be a trivial GEGL op. A JPEG-ghost mode is an easy extra.

### 2. Ofnuts path tools (unported)
- **What:** large Python-Fu set; the path tools (path-edits, text-along-path, path-arrows, path-csv, bend-path, symmetries) are the most distinctive.
- **Author and license:** Ofnuts; `LICENSING.md` (2025-06-15): GPL-3+, with a request that redistributed changes remove the `ofn3` prefixes. Per-file headers not opened.
- **Last activity:** GIMP 2 sets updated up to 2025-04; GIMP 3 set (sourceforge.net/projects/gimp3-tools) last file 2025-06-10.
- **Popularity:** SourceForge totals: gimp-tools 215,866, gimp-path-tools 102,386; ofn-path-edits 9,229, ofn-text-along-path 8,347, ofn-tiles 8,446, ofn-srgb 5,870.
- **GIMP 3 status:** author has ported 8 scripts (layer-tiles, export-layers, list-guides, align-layers, colormap-to-paths, interleave-layers, mirror-layers, resource-manager). **No path scripts ported yet.**
- **Need:** yes, but the author is alive and porting, so this is a "help him" item, not a fork. Score assumes coordination.
- **Effort/fit:** small per script, Python 3 plug-ins.

### 3. Pixel art scalers (hqx, xBR, scaleNx)
- **What:** integer upscalers for pixel art.
- **Author and license:** bbbbbr; repo LICENSE GPL-3.0; embedded hqx (Maxim Stepin et al.) and xBR (Hyllian, from FFmpeg) files are LGPL-2.1+.
- **Last activity:** v1.1 2019-12-14, last commit 2020-08-25. Author active on other GIMP repos (gimp-rom-bin, 2026-08-24).
- **Popularity:** 105 stars; open issue #8 "GIMP 3 / GTK3 migration" (2020); PR #9 closed unmerged; issue #17 asks for MMPX (2025-12).
- **GIMP 3 status:** no port; not native; G'MIC has only "Upscale [Scale2x]" (no hqx, no xBR).
- **Need:** yes.
- **Effort/fit:** small to medium; the lookup tables are GIMP-independent. Very natural as GEGL ops (fixed-factor upscale, non-destructive only if canvas resize is handled, so a plug-in wrapper that resizes the image then applies the op is the practical UX). Upstream PR plausible.

### 4. Saturation Equalizer and Advanced Unsharp Mask (Tibor Bamhor)
- **What:** Sat EQ adjusts saturation by each pixel's current saturation (6-band curve) plus temperature and auto-align; AUMask is equalizer-style sharpening with a selective-blur mask.
- **Author and license:** Sat EQ repo LICENSE GPL-3.0 (github.com/tibor95/gimp-plugin-satequalizer, 2 stars, last push 2016-06-07). AUMask 0.9.2 source says only "Copyright Tibor Bamhor", registry tag says GPLv3: **source license UNVERIFIED**.
- **Popularity:** registry static mirror comment counts: Sat EQ 70 (7th highest overall), AUMask 60. AUR `gimp-plugin-satequalizer` 5 votes, out of date.
- **GIMP 3 status:** no port; no saturation-by-saturation curve in GIMP 3.2 (the new Vibrance filter is related but a fixed curve).
- **Need:** yes for Sat EQ; partial for AUMask.
- **Effort/fit:** small to medium each (about 1.5k lines C each). Both are single-input point/neighbourhood ops: ideal GEGL ops with full NDE.

### 5. Save for Web (Aurimas Juska)
- **What:** one dialog comparing JPEG/PNG8/PNG24/GIF settings with live preview and file size, plus resize, crop, metadata strip.
- **Author and license:** `src/webx_main.c`: LGPL-2+; `cursors.c` and `webx_prefs.c` GPL-2+; the repo COPYING is a contradictory MIT-style text (issue #8). Treat the combination as GPL-2+.
- **Last activity:** last commit 2021-08-12; only tag 0.29.0 (2009).
- **Popularity:** #2 on registry.gimp.org all-time "Popular content" (Wayback 2015-01-02). 94 stars. Issue #25 (2025-05) asks for GIMP 3. pixls.us 2025-04 thread: "Nothing yet for Gimp 3.0".
- **GIMP 3 status:** no port. Native: JPEG export has in-canvas preview and "File size without metadata"; WebP and AVIF export exist but without preview or size; PNG/GIF have neither; no side-by-side comparison. Fedora's retirement reason ("replaced by built-in export") overstates it.
- **Need:** yes for multi-format comparison with size readout.
- **Effort/fit:** medium to large (5.3k lines C, GTK2 custom widgets); should be rewritten around `file-*-export` procedures with GimpProcedureConfig, adding WebP/AVIF/JPEG XL. Plug-in only.

### 6. Exposure fusion and focus stacking (replacing Exposure Blend)
See section 2 for the full HDR/stacking landscape. Summary: GIMP has no bracket merge; the old Exposure Blend script (J.D. Smith, 2006, GPL-2+, 589 lines of Script-Fu, 3 fixed exposures, mask-based) is dead. A Mertens exposure-fusion core (Laplacian pyramid blend of weight maps) also does focus stacking by switching the weights to local contrast only, which is exactly what `enfuse` does. Medium effort; GEGL op with aux pads (destructive in GIMP until the aux TODO is fixed) plus a plug-in that takes N layers and optionally pre-aligns.

### 7. Refocus (Ernst Lippe)
- **What:** FIR Wiener-filter deconvolution with circle (defocus) and Gaussian PSF.
- **Author and license:** `src/refocus.c`: "Copyright (C) 1999-2003 Ernst Lippe", GPL-2+ (read from Debian `refocus_0.9.0.orig.tar.gz`); bundles CLAPACK.
- **Last activity:** 0.9.0 (2003); JoesCat/gimp-refocus-plugin V-0-9-1 (2024-10) still GIMP 2.
- **Popularity:** SourceForge 98,546 downloads; FreeBSD port still exists (GIMP 2); Debian `gimp-refocus` long gone.
- **GIMP 3 status:** no port of Refocus. Refocus-it (Lukas Kunc, iterative) has a JoesCat `gimp3` branch "compiles, needs more work" (2026-02-28). No deconvolution op in GEGL (grep for deconvol/wiener/richardson finds nothing). G'MIC covers deconvolution: "Sharpen [Richardson-Lucy]", "Sharpen [Deblur]", "Sharpen [Gold-Meinel]", community "Deconvolve" with a PSF layer.
- **Need:** partial: nothing native or non-destructive, no one-click defocus-disc Wiener filter. Also relevant for microscopy.
- **Effort/fit:** medium. Excellent GEGL op: compute the FIR kernel once from the PSF parameters, then convolve; fast and NDE.

### 8. PhotoRestore (Geoff Daniell)
- **What:** estimates dye fading in old slides/prints and restores colour automatically.
- **Author and license:** Geoff Daniell, published by stongey; `Restore2.py` GPL-3+, LICENSE GPL-3.0.
- **Last activity:** 2019-07-23.
- **Popularity:** 70 stars; issues #2 "Gimp 3.0" (2025-01) and #1 "Migration to Python3" unanswered.
- **GIMP 3 status:** no port; nothing equivalent native or in G'MIC (G'MIC checked by grep only).
- **Need:** yes (family archive scanning is common; algorithm documented in white papers in the repo).
- **Effort/fit:** medium (about 3k lines Python 2, PixelRgn to GeglBuffer/numpy). Python plug-in first; the correction itself could later be a GEGL op fed with computed parameters.

### 9. gimp-data-extras (official GNOME "graveyard")
- **What:** the logo/effect Script-Fu scripts removed from core (alien-glow, chrome-logo, neon, truchet, select-to-brush/pattern/image, predator, and about 50 more) plus Python 2 plug-ins clothify, shadow_bevel, sphere, whirlpinch.
- **License:** COPYING GPL-3.0; clothify.py GPL-3+.
- **Last activity:** commits to 2023-08-20; last tag 2.0.4 (2018). None of the GIMP 3-era moves were ever released.
- **Popularity:** Debian popcon 2,550, the highest of any GIMP add-on (gimp-plugin-registry is 940). AUR `gimp-extras` 65 votes (GIMP 2). Fedora still ships it through f45 (runtime compatibility UNVERIFIED).
- **Need:** partial (much is legacy logo art), but the demand signal is large and the fix is upstreamable.
- **Effort/fit:** medium in total, repetitive. Upstream MR to gitlab.gnome.org/GNOME/gimp-data-extras and a 3.x release.

### 10. Smart Separate Sharpen (Martin Egger, Michael Kolodny)
- **What:** edge-masked unsharp mask with separate light and dark halo control.
- **License:** GPL-3+ (header of `Eg-SmartSeparateSharpen.scm`, 2012).
- **Popularity:** Debian bundle; gimpchat thread. Download counts UNVERIFIED.
- **GIMP 3 status:** broken (4 removed `plug-in-*` calls). A related new C plug-in, v-lavrentikov/gimp-smart-sharpening (BSD-3, 2 stars, 2026-08), exists. G'MIC has similar but not identical sharpeners.
- **Need:** partial. **Effort/fit:** small; best as a GEGL meta-op (edge detect, blur mask, unsharp, light/dark split) for NDE. Fits naturally next to the Wavelet Sharpen work.

### 11. Contact Sheet (Robin Gilham)
- **License:** GPL-2+ (contactsheet.py 2.16, Debian copy). Last activity 2011.
- **Popularity:** Debian bundle; GIMP issue #9281 "Restore contact sheet plugin to supported status" (open). GIMP's own contactsheet.scm was moved to scripts/test and only installed in unstable builds (commit 60a584f9, 2024-04-24).
- **GIMP 3 status:** a new, unrelated GIMP 3 plug-in by Chuck Henrich (v1, 2026-02-17) exists; **its license and source repo are UNVERIFIED**.
- **Need:** partial. **Effort/fit:** small Python 3 plug-in.

### 12. APNG export
- **Status:** GIMP master `file-png.c` has `file-apng-load` only; no APNG export procedure (checked in source; the 3.2 release notes mention APNG support generically). Old gimp-apng: 40,092 SourceForge downloads (license declared GPL on SourceForge, source header UNVERIFIED). A new Python GIMP 3 exporter, wobbo/gimp-apng (MIT, 0 stars, 2026-08-18), exists.
- **Need:** partial. **Effort/fit:** small; best as an upstream MR adding export to file-png.c, or help/package wobbo's plug-in.

### 13. DCamNoise2 (Peter Heckert, 2005)
- **License:** GPL-2+ (source header; archived at bitbucket.org/stativ/gimp-plugin-dcamnoise2).
- **Popularity:** AUR `gimp-plugin-dcamnoise2` 68 votes (5th most voted GIMP plug-in package), PKGBUILD still uses `gimptool-2.0`.
- **GIMP 3 status:** no port. GEGL `noise-reduction` and G'MIC denoisers exist, but not this FIR luminance/chroma approach.
- **Need:** partial (overlaps Wavelet Denoise). **Effort/fit:** small to medium (1,332-line C++ file); single-input GEGL op.

### 14. DivideScannedImages (Francois Malan, after Rob Antonishen)
- **License:** GPL-2+ (header of `DivideScannedImages.scm`; no LICENSE file).
- **Popularity:** 131 stars, 23 forks; issues #14 and #22 "Support for GIMP 3.x" (2026-05-20). AUR 6 votes.
- **GIMP 3 status:** two brand-new unvetted ports (aschenzle/GIMP-3.x-DivideScannedImages, 2026-05-19, 0 stars; lilcheeks fork). G'MIC "Extract Objects" partly covers the split. Deskew itself is already ported (see below), so a combined split + deskew plug-in is easy.
- **Need:** yes, shrinking. **Effort/fit:** small to medium; plug-in.

### 15. Separate+ (Alastair Robinson, Yoshinori Yamakawa)
- **License:** GPL-2+ (`separate-core.c` header).
- **Last activity:** 0.5.8, about 2010.
- **Popularity:** #12 on the registry all-time popular list; FreeBSD port still exists (GIMP 2); recurring GNOME Discourse and Arch wiki demand.
- **GIMP 3 status:** native CMYK export for JPEG/TIFF/PSD/JPEG XL via the soft-proof profile, soft-proof pop-over, CMYK picker, Total Ink Coverage readout (3.2). Still missing: CMYK PDF export, editable plates, CMYK TIFF import as plates (it is converted to RGB on load), spot channels (roadmap: "No"), GCR/UCR (GEGL `gray-component-replacement` exists only in the unbuilt workshop), device links, duotone.
- **Need:** partial but real for print people. **Effort/fit:** large; rethink on GIMP 3's babl CMYK rather than port literally: a plug-in for plates/duotone, plus a GEGL GCR/UCR op with ink limit.

### 16. User Filter (Photoshop Filter Factory interpreter)
- **Author/license:** Jens Restemeier (1997), later cholfatyarh; SourceForge declares GPLv2/LGPLv2; **source header UNVERIFIED**.
- **Popularity:** 21,403 SourceForge downloads; named as a must-have next to Resynthesizer, G'MIC and MathMap in a 2025-03 pixls.us thread.
- **Status:** last release 0.9.7 (2008); no GIMP 3 port.
- **Effort/fit:** medium; the expression evaluator could even back a GEGL op, with a plug-in for importing .8bf/.afs filter files.

### 17. Fix-CA as a non-destructive op
- The plug-in itself is covered (see below: JoesCat/gimp3-fix-ca 5.0). The only new value would be a GEGL op (per-channel radial resample, about 1k lines of logic) so lateral CA correction becomes an editable filter. GEGL has no CA op; G'MIC's "Chromatic Aberrations" is a simulation. Small; coordinate with Jose Da Silva.

### 18. Automatic line-based perspective correction
- **Status:** GIMP 3's 3D Transform (camera, vanishing point, XYZ angles) covers EZ Perspective's numeric approach; nothing detects lines automatically. darktable's `src/iop/ashift.c` (GPL-3+, LSD line detector, ShiftN-inspired) does. GIMP issue #2026 (symmetric perspective correction) open since 2018.
- **Effort/fit:** medium to large; plug-in that runs line detection and fits `gimp_item_transform_perspective`, reusing ashift math with attribution.

### 19. Valve VTF (gimp-vtf, Tom Edwards)
- **License:** LGPL-2.1+ in source headers (no LICENSE file). 84 stars, last push 2015. Issue #16 "Gimp 3 support" has 12 reactions, the most of any porting issue found.
- **Effort/fit:** medium (port C, meson, make VTFLib build on Linux). File plug-in; niche (Source engine modding).

### 20. MathMap (Mark Probst)
- **License:** GPL-2+ (`mathmap.c`). Last commit 2022-04-19; 101 stars.
- **Status:** no port; G'MIC "Custom Code" covers expression filtering, not the node Composer.
- **Effort/fit:** large (about 39k lines, GTK2, runtime C compilation). Low ratio.

## 2. HDR merging, tone mapping, stitching and focus stacking

### What GIMP 3 already has (verified in source)
- **Tone mapping, single image:** native GEGL filters exposed in menus: `gegl:fattal02`, `gegl:mantiuk06`, `gegl:reinhard05`, `gegl:stress`, plus Retinex (`app/actions/filters-actions.c`). GIMP works in 32-bit float and loads EXR/HDR (RGBE)/TIFF float. So tone mapping of an existing HDR is covered.
- **HDR radiance merge:** GEGL has `gegl:exp-combine` ("Combine Exposures", Debevec/Robertson-style from pfscalibration, LGPL-3+, Danny Robson 2010) with dynamic multiple inputs, but GIMP does not expose it in any menu. No exposure *fusion* op.
- **Alignment:** GIMP's "Align Visible Layers" is geometric only. Content-based: G'MIC "Layers > Align Layers" (rigid or non-rigid, intensity based) and gimp-image-reg (Behnam Tabatabai; v3.0.0 for GIMP 3 released 2025-11-20; LICENSE MIT for v3, earlier versions GPL-3; 19,178 SourceForge downloads).
- **Stacking:** G'MIC "Layers > Blend [Median]", "Blend [Average All]", community "Fast Median Stack". Covers mean/median for noise and ghost removal. No sigma-clipped mean.
- **Exposure fusion inside G'MIC:** only experimental filters in the community Testing section: Iain Fergusson's "Exfusion", "Exfusion3", "Exfusion5" (fixed layer counts) and Arto Huotari's "Exposure Fusion Weight Map" (cites Mertens). Not a polished tool.
- **Focus stacking:** nothing native or in G'MIC (gimpchat thread 2025-01 confirms "no native focus stacking"; people use manual masks or CombineZP). The only GIMP 3 plug-in found is dcknuth/gimp_focus_stack (MIT, 3 stars, 2025-08): Windows-only wrapper around focus-stack.exe, 8-bit JPEG output.
- **Panorama/mosaic:** Akkana Peck's Pandora (layer arrangement for manual stitching) is ported to GIMP 3 (akkana/gimp-plugins `gimp3/pandora.py`). No automatic stitching in GIMP.

### External tools (status verified)
- **enfuse/enblend:** 4.2 (files dated 2016-03), exposure fusion and focus stacking (contrast-weight + hard mask), GPL-2+. Mature, effectively frozen.
- **Hugin:** 2025.0.1 released (2025-12), includes `align_image_stack` (feature-based alignment for brackets and focus stacks) and mosaic mode.
- **Luminance HDR:** last release v2.6.1.1; only maintenance commits since (2025-06 licence text, CMake 4). HDR merge plus many tone mappers.
- **focus-stack (Petteri Aimonen):** MIT, 666 stars, v1.5 released 2026-01-11. OpenCV-based, wavelet merge, alignment built in.
- **Fiji/ImageJ:** Grid/Collection Stitching (Preibisch, fiji/Stitching, GPL-2, active 2026-06) is the standard for microscopy tile mosaics; BigStitcher for large data; Extended Depth of Field (EPFL BIG, repo inactive since 2017) for focus stacks.
- **Old GIMP Exposure Blend** (J.D. Smith, GPL-2+): 3 exposures, blurred-luminosity masks, simple alignment mode, 2007 TinyScheme port by Alan Stewart. Last update about 2009. Broken on GIMP 3 (removed compat procedures).

### The gap and a proposed shape
1. **`gegl:exposure-fusion` (Mertens et al. 2007):** inputs `input`, `aux`, `aux2` ... ; weights for contrast, saturation, well-exposedness; multi-resolution Laplacian pyramid blend in linear float. Same op with contrast-only weights and a "hard mask" option does **focus stacking** (enfuse's method). OpenCV's `MergeMertens` (Apache-2.0) is a clean reference.
2. **Plug-in front end (GIMP 3, Python or C):** "Merge exposures / Focus stack from layers": takes all or selected layers (N inputs, not limited to 3), optional pre-alignment by calling Hugin's `align_image_stack` if installed (or G'MIC Align Layers), then runs the op. Because aux-input filters are forced destructive in GIMP today (section 0, item 5), the plug-in route is the practical UX; the op becomes NDE-capable automatically once GIMP serializes drawables.
3. **Expose HDR radiance merge:** a small plug-in that wires `gegl:exp-combine` with EV values from EXIF would give true HDR (float radiance) that the native Fattal/Mantiuk/Reinhard filters can then tone-map. Small effort, genuinely missing.
4. **Microscopy stitching inside GIMP:** no plug-in exists; realistically a wrapper around Hugin's mosaic mode or a translation-only phase-correlation stitcher. Medium to large; Fiji remains the right tool for serious grids, so the in-GIMP value is modest (quick 2 to 6 tile mosaics).
5. **Deconvolution for microscopy:** the Refocus GEGL op (candidate 7) with Gaussian and disc PSF would also serve widefield microscopy; G'MIC "Deconvolve" with a measured PSF layer covers the advanced case.

Overall need: **high** for exposure fusion and focus stacking (nothing usable in GIMP 3 beyond G'MIC test filters and one Windows-only wrapper), **medium** for radiance merge, **low to medium** for stitching.

## 3. Checked and not needed (already covered)

| Item | Why it is covered |
|---|---|
| Resynthesizer | Ported and maintained by bootchk: v3.0 (2025-05-22), v3.0.1 (2026-03-31), branch `resynthesizer3`, last commit 2026-04-09; plug-ins now Script-Fu over a C engine (heal-selection, heal-transparency, map-style, render-texture, resynth-controls, enlarge, fill-pattern, sharpen, uncrop). Flathub `branch: 3` at tag v3.0.1. 1,870 stars, 61 open issues. Gaps are packaging only: no Windows binaries on releases, no Debian package for v3, FreeBSD still 2.0.3. GIMP roadmap defers inpainting to it. |
| Fix-CA | Maintained GIMP 3 port JoesCat/gimp3-fix-ca 5.0 (2026-02-13), GPL-3+; Fedora review bug 2327257 open. Only an NDE GEGL version would add value (candidate 17). |
| Deskew | Ported upstream: gimp-plugins-justice/gimp-deskew-plugin v1.2 (2026-01-17), requires gimp-3.0. |
| XSane GIMP plug-in | GIMP 3 support merged in xsane master (MR !37, 2025-05-28), but no release since 0.999 (2020); Debian and Fedora disabled the GIMP plug-in. Workarounds: gimp-xsanecli (GPL-3+, active 2026-03), draekko's native SANE plug-in (GPL-3). Windows gets a new WIA plug-in in GIMP 3.2.4 (verified in master `plug-ins/common/wia.c`). Needs a release, not a port. |
| gimp-texturize | Ported upstream (tag 3.0, 2025-03-28); in Debian trixie as 3.0+ds-1. |
| Fourier | Ported; Flathub `branch: 3`. |
| Pandora | Ported by Akkana Peck (`gimp3/pandora.py`); only the AUR package (90 votes, 2015) is stale. |
| Arrows | Scallact/gimp-stroke-arrows (GPL-3+, v0.8 2025-12); vitforlinux arrow_V3.scm; GIMP 3.2 MyPaint arrow brush. |
| DDS | Built into GIMP since 2.10.10 (Shawn Kirst code), BC7 export in 3.2. |
| NormalMap | Native `gegl:normal-map` since 2.10.14. Kirst's extra kernels/DUDV are a small niche; extend the GEGL op upstream if wanted. |
| Layer Effects (Stipe) | Mostly covered by native GEGL Styles, Bevel, Inner Glow, Drop/Long Shadow (GEGL 0.4.50, in GIMP 3.0) and LinuxBeaver's GEGL Effects. Missing only Satin and Gradient Overlay (small GEGL ops if ever wanted). |
| Median/mean stacking | G'MIC Blend [Median] / [Average All]. |
| Image registration | gimp-image-reg v3.0.0 (2025-11-20) and G'MIC Align Layers. |
| Export Layers / DBP | Batcher (GIMP 3), BIMP work. |
| elsamuko scripts | Author porting on `gimp-3` branch; PR #9 (2026-07). Contribute there instead of forking. |
| Refocus-it | JoesCat `gimp3` branch in progress (2026-02-28). |
| GIMP-GAP | Archived on GNOME GitLab; GIMP roadmap (3.6): "Animation plug-in is dropped, this is being rewritten as a core feature". A small onion-skin helper is the only realistic niche. |
| GIMP-ML | Unmaintained for GIMP 3, but intel/openvino-ai-plugins-gimp (Apache-2.0, v3.3.0 2026-06) and others cover AI use. |
| EZ Perspective | Numeric approach covered by the native 3D Transform tool (the automatic kind is candidate 18). |
| Decor scripts (Round Corners, Add Bevel, Fuzzy Border, Old Photo, Drop Shadow legacy) | Still shipped in GIMP 3.0 and 3.2 (43 .scm files, identical at both tags). |
| Tone mapping | Native Fattal, Mantiuk, Reinhard, Stress filters. |
| Gutenprint print plug-in | Not "covered", but deprioritized: upstream says the plug-in is GIMP 2 only (commit 56f3bdc9, 2025-04), large GTK2 UI library; GIMP 3's GtkPrint dialog still reaches Gutenprint drivers via CUPS (option coverage UNVERIFIED). Large effort, partial need. |
| Beautify (hejiann) | 174 stars, but no LICENSE file and 27 MB of textures with no licence or provenance; G'MIC "Smooth [Skin]" covers the core. Blocked on licensing. |
| GIMP FX Foundry | 929,296 SourceForge downloads, but a 2008 grab bag; most effects superseded by GEGL/G'MIC. Cherry-pick only. |
| Diego Nassetti scripts | License and provenance UNVERIFIED (several are ports of others' scripts; gimpscripts.net now serves gambling spam). Blocked until the author is contacted. |
| gimp-android-xdpi | 162 stars but no license at all; trivial to reimplement if wanted. |

## 4. Notes on method and gaps
- The Wayback Machine and its CDX API were intermittently offline; registry per-plug-in download counters could not be found (the node pages do not show them). Registry popularity above uses the 2015 "Popular content" all-time ranking and comment counts from a static mirror (github.com/surh/registry.gimp.org_static), treated as relative only.
- Reddit returned no usable results.
- Process note: one research sub-agent sent a batch of requests to repology.org with the user's email in the User-Agent header. Those requests returned nothing and the retry failed to connect, so they probably never reached the server, but that cannot be proven. No Repology data was used.
