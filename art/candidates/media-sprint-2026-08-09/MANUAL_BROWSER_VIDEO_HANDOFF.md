# Manual browser video handoff

**Status:** reconciled 10 August 2026: eight results returned, two absent. Usable
results and existing fallbacks are recorded in `manifest.json`; raw returns remain in
`manual-browser-video-results/`. Do not submit further audio or video jobs.

Use Gemini web Video mode with the listed source image and prompt. Request **10
seconds**. Preserve the source composition. Generated sound is not part of the asset:
strip its audio track by default during post-processing. Return the untouched download
as an MP4 to:

`/Users/cobro/code/irish/art/candidates/media-sprint-2026-08-09/manual-browser-video-results/`

The source images remain in their canonical project locations rather than being
duplicated. All ten paths below were verified on 10 August 2026.

## 1. `video.mayo-clew-bay-return`

- **Source image:** `/Users/cobro/code/irish/art/candidates/media-sprint-2026-08-09/mayo-return-clew-bay--t02.png`
- **Prompt:** Animate this still for 10 seconds: calm Atlantic swell, faint cloud drift and subtle light movement toward a clearer horizon; fixed camera, seamless-feeling ambient motion, no new people, boats, buildings, text or historical action.
- **Target:** 10 seconds, portrait 9:16.
- **Use:** Mayo chapter 9 return opening; muted loop with the source still as fallback.
- **Return as:** `video.mayo-clew-bay-return--manual-t01.mp4`
- **Post-processing:** Preserve raw download first; strip generated audio by default, then review motion and crop before any delivery encode.

## 2. `video.meath-ringwork-fortress`

- **Source image:** `/Users/cobro/code/irish/art/candidates/media-sprint-2026-08-09/meath-ringwork-fortress--t03.png`
- **Prompt:** Animate this still for 10 seconds: light river movement, grass and reeds shifting gently, thin morning mist lifting; fixed human-height camera, preserve every fortification form, add no bridge, people, tools, buildings or text.
- **Target:** 10 seconds, portrait 9:16.
- **Use:** Meath chapter 4 ringwork opening; muted loop with the source still as fallback.
- **Return as:** `video.meath-ringwork-fortress--manual-t01.mp4`
- **Post-processing:** Preserve raw download first; strip generated audio by default, then review for altered fortification forms before any delivery encode.

## 3. `video.mayo-galway-bay-trading`

- **Source image:** `/Users/cobro/code/irish/ios/AnTuras/Assets.xcassets/mayo-galway-bay-trading.imageset/mayo-galway-bay-trading.jpg`
- **Prompt:** Animate this still for 10 seconds: slow harbour-water ripple and restrained cloud drift only; fixed camera, preserve vessels and shoreline exactly, no new people, cargo action, text or camera move.
- **Target:** 10 seconds, landscape 16:9.
- **Use:** Mayo chapter 4 power-at-sea opening; muted loop with still fallback.
- **Return as:** `video.mayo-galway-bay-trading--manual-t01.mp4`
- **Post-processing:** Strip generated audio by default; reject vessel, shoreline or participant changes.

## 4. `video.mayo-tudor-pressure`

- **Source image:** `/Users/cobro/code/irish/ios/AnTuras/Assets.xcassets/mayo-tudor-pressure.imageset/mayo-tudor-pressure.jpg`
- **Prompt:** Animate this still for 10 seconds: low cloud moving slowly over the coastal stone precinct and slight vegetation movement; locked camera, no figures, smoke, construction, flags, text or architectural change.
- **Target:** 10 seconds, landscape 16:9.
- **Use:** Mayo chapter 5 pressure opening; muted loop with still fallback.
- **Return as:** `video.mayo-tudor-pressure--manual-t01.mp4`
- **Post-processing:** Strip generated audio by default; reject new architecture, activity or symbols.

## 5. `video.mayo-royal-court-interior`

- **Source image:** `/Users/cobro/code/irish/ios/AnTuras/Assets.xcassets/mayo-royal-court-interior.imageset/mayo-royal-court-interior.jpg`
- **Prompt:** Animate this still for 10 seconds: a restrained shift of window light and a few dust motes; locked camera, empty room, no people, fire, object movement, text or invented audience action.
- **Target:** 10 seconds, landscape 16:9.
- **Use:** Mayo chapter 8 royal-answer opening; muted loop with still fallback.
- **Return as:** `video.mayo-royal-court-interior--manual-t01.mp4`
- **Post-processing:** Strip generated audio by default; reject figures or changed objects.

## 6. `video.dublin-wood-quay-settlement`

- **Source image:** `/Users/cobro/code/irish/ios/AnTuras/Assets.xcassets/dublin-wood-quay-settlement.imageset/dublin-wood-quay-settlement.jpg`
- **Prompt:** Animate this still for 10 seconds: gentle river-edge ripple, reed movement and very slight existing smoke drift; fixed camera, preserve all structures and distant figures, add no people, boats, activity or text.
- **Target:** 10 seconds, landscape 16:9.
- **Use:** Dublin chapter 2 settlement opening; muted loop with still fallback.
- **Return as:** `video.dublin-wood-quay-settlement--manual-t01.mp4`
- **Post-processing:** Strip generated audio by default; reject altered structures, figures or added action.

## 7. `video.dublin-viking-market`

- **Source image:** `/Users/cobro/code/irish/ios/AnTuras/Assets.xcassets/dublin-viking-market.imageset/dublin-viking-market.jpg`
- **Prompt:** Animate this still for 10 seconds: cloth edges stirring and subtle water movement only; fixed camera, keep every person distant and unchanged, no new gestures, trade action, objects, text or camera motion.
- **Target:** 10 seconds, landscape 16:9.
- **Use:** Dublin chapter 3 market opening; muted loop with still fallback.
- **Return as:** `video.dublin-viking-market--manual-t01.mp4`
- **Post-processing:** Strip generated audio by default; reject changed people, gestures or market activity.

## 8. `video.dublin-minting-workshop`

- **Source image:** `/Users/cobro/code/irish/ios/AnTuras/Assets.xcassets/dublin-minting-workshop.imageset/dublin-minting-workshop.jpg`
- **Prompt:** Animate this still for 10 seconds: soft charcoal glow and slow light variation across the existing die and anvil; locked camera, no hands, hammer strike, sparks, new tools, text or object movement.
- **Target:** 10 seconds, landscape 16:9.
- **Use:** Dublin chapter 5 mint opening; muted loop with still fallback.
- **Return as:** `video.dublin-minting-workshop--manual-t01.mp4`
- **Post-processing:** Strip generated audio by default; reject invented action, hands, tools or sparks.

## 9. `video.dublin-modern-archaeology`

- **Source image:** `/Users/cobro/code/irish/ios/AnTuras/Assets.xcassets/dublin-modern-archaeology.imageset/dublin-modern-archaeology.jpg`
- **Prompt:** Animate this still for 10 seconds: faint mist or dust motes moving above the excavation soil; fixed camera, preserve all archaeology and people exactly, no digging action, added objects, text or reconstruction.
- **Target:** 10 seconds, landscape 16:9.
- **Use:** Dublin chapter 6 archaeology opening; muted loop with still fallback.
- **Return as:** `video.dublin-modern-archaeology--manual-t01.mp4`
- **Post-processing:** Strip generated audio by default; reject changes to archaeology, people or excavation activity.

## 10. `video.meath-boyne-ford`

- **Source image:** `/Users/cobro/code/irish/ios/AnTuras/Assets.xcassets/meath-boyne-ford.imageset/meath-boyne-ford.jpg`
- **Prompt:** Animate this still for 10 seconds: gentle Boyne current, slight meadow movement and morning mist lifting; fixed camera, preserve the ford and landscape, no people, horses, buildings, bridge, text or historical action.
- **Target:** 10 seconds, landscape 16:9.
- **Use:** Meath chapter 1 arrival opening; muted loop with still fallback.
- **Return as:** `video.meath-boyne-ford--manual-t01.mp4`
- **Post-processing:** Strip generated audio by default; reject added crossings, structures, participants or historical action.

## Return checklist

- Keep each raw Gemini MP4 unchanged under the exact return filename.
- If Gemini fails temporarily, retry the same job without changing its prompt.
- Do not add sound, titles, captions, interpolation or synthetic camera movement.
- Return results to `manual-browser-video-results/`; review and encoding happen later.
