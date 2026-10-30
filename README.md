# deSPIRIA (Dreamcast) on dream-recomp

Play Atlus's **deSPIRIA** (Sega Dreamcast, 2000) as a native Windows program, in English, using
[dream-recomp](https://github.com/phobos665/dream-recomp) by phobos665, an experimental Dreamcast
static recompiler, and the
[deSPIRIA Translation Initiative](https://github.com/deSPIRIA-Translation-Iniative/despiria-patcher-releases)'s
English fan translation.

dream-recomp translates the game's SH-4 program into C++ ahead of time and compiles it; the
graphics and sound hardware are emulated, and the console BIOS is replaced, so **no BIOS is
needed**. This kit adds the fixes deSPIRIA needs, its tuned configuration, and a launcher.

> **You need your own game.** This kit contains no game data, no translation files and no
> dream-recomp build. On first launch it downloads dream-recomp's public source and a portable
> compiler, and builds deSPIRIA on your PC from your own disc. The compiled game stays on your PC.

## What works

- The title screen and menus, the developer logo and the opening movies with sound, and **New
  Game into the opening story**. Tested by the kit author through the opening; not a playthrough.
- **Full speed** on a 15 W Intel i7-1355U laptop with integrated graphics.
- **Saves** go to a memory card file, `saves\vmu-a1.bin` in your
  [data folder](#where-your-files-live), outside the app folder.
- Keyboard and SDL-compatible controllers.

This is early: expect rough edges, and keep a copy of your memory card.

## What you need

- Windows 10 or 11, 64-bit, with a Vulkan-capable GPU (any recent Intel, AMD or NVIDIA).
- **deSPIRIA (Japan), T14402M**, dumped from your own disc as a **GDI** image (`.gdi` plus its
  track files).
- **The English patch applied to it.** Run the translation team's
  [patcher](https://github.com/deSPIRIA-Translation-Iniative/despiria-patcher-releases/releases)
  on your disc first and keep the `.gdi` it writes. Any of its battle-speed settings works
  (Original, Brisk, Swift); the kit author tested Brisk. The patch translates Chapter 1's story;
  menus, items and maps are English throughout.
- About **3 GB** of free space and an internet connection for the first launch.

## Playing Chapter 2 onwards

The English patch translates Chapter 1's story. From Chapter 2 the dialogue is Japanese again
(menus, items and maps stay English). To read it, use
[LunaTranslator](https://github.com/HIllya51/LunaTranslator), a free tool that reads text off
the screen and machine-translates it as you play:

1. Download `LunaTranslator_x64.zip` from its
   [releases](https://github.com/HIllya51/LunaTranslator/releases), extract it anywhere and run
   `LunaTranslator.exe`.
2. In its settings, set the source language to **Japanese** and the target to **English**, and
   pick a translator (Google or Bing work without an account).
3. Switch the text input to **OCR** (reading the screen). Text hooking doesn't apply here.
4. Draw the OCR region over the **whole game picture**: deSPIRIA has no fixed dialogue box, and
   lines appear in the middle or at the top of the screen.
5. Optional: right-click the region box to turn on in-place translation and click-through, and
   minimize LunaTranslator's main bar so the OCR doesn't read it.

LunaTranslator forgets the OCR region when it closes, so draw it again each session. Machine
translation is rough next to the team's; it gets you through the story until their translation
of the later chapters is out.

## Install

**Quiver Launcher:** add deSPIRIA from the catalog and press Play.

**By hand:** extract the release zip anywhere and run `deSPIRIA.exe`.

On first launch a setup window opens:

1. It asks for your English-patched `.gdi` and checks it is deSPIRIA with the English patch.
2. It downloads the build tools into `tools\` in the data folder: a portable clang (llvm-mingw),
   CMake, Ninja, Python, SDL3 and the Vulkan headers, about 1 GB unpacked. Every download is
   pinned and checked.
3. It downloads dream-recomp at a fixed commit (`51a148c`), adds this kit's fixes and the
   deSPIRIA configuration, translates your disc's program and compiles it. That takes about 5 to
   15 minutes.
4. The game starts. Later launches start straight away.

To choose a different disc, run `deSPIRIA.exe --setup`. To rebuild, run `deSPIRIA.exe --rebuild`.

## Controls

| Dreamcast | Keyboard |
| --- | --- |
| D-pad | Arrow keys |
| A / B / X / Y | Z / X / A / S |
| Start | Enter |
| L / R triggers | Q / W |

**F1** (or a controller's select button) opens the screen for changing the bindings. **F10**
shows the frame rate, **F12** saves a screenshot, **Esc** quits.

The game draws at the Dreamcast's 640x480 and is scaled to the window, which keeps it at full
speed on integrated graphics. On a faster GPU, `deSPIRIA.exe --scale 2` (up to 4) draws at a
higher resolution.

## Where your files live

`%LOCALAPPDATA%\deSPIRIA-DreamRecomp`:

| | |
| --- | --- |
| `saves\vmu-a1.bin` | your memory card |
| `game\` | the built game and the path to your disc |
| `tools\`, `build\` | build tools and the build; safe to delete (setup fetches them again) |
| `setup.log`, `game\game.log`, `launcher.log` | logs |

A file named `portable.txt` beside `deSPIRIA.exe` keeps all of this in the app folder instead.

## What this kit changes in dream-recomp

All fixes are in `kit\overlay`, applied over dream-recomp `51a148c`:

- **Sound**: 32-bit stores to the sound chip's registers now count as 16-bit stores, as the
  hardware does. deSPIRIA's sound driver keys notes on with 32-bit stores and was silent.
- **Movies**: stride textures keep their size for texture coordinates and take only their row
  spacing from `TEXT_CONTROL`, and textures the game rewrites in place are re-read each frame.
  Movies were smeared and froze.
- **Smooth pacing** (v0.1.1): the frame pacing kept its state in a variable that had gone out
  of scope, so its target wandered, and when it fell behind it sprinted to catch up, playing
  ahead and throwing sound away. It now owns its state and forgives a hitch instead of sprinting.
- **No crackles** (v0.1.1): instead of dropping sound when the sound card's clock and the PC's
  drift apart, playback speed is nudged by at most half a percent to keep the queue steady.
- **Letterbox bars** (v0.1.1): in a wide window the right-hand bar showed the picture's last
  column smeared across it; the bars are now black.
- **Windows builds** copy the DLLs a program needs next to it.
- **Shaders**: precompiled shader headers are used when `glslc` is not installed, so no Vulkan
  SDK is needed.

The deSPIRIA configuration (`kit\game\despiria_en.toml.in`) leaves three functions to
dream-recomp's interpreter because their translations misbehave: two crash the game, and the
third, the thread library's context switch, starves the movie player. Those are workarounds for
translator defects, documented in the file.

## Credits and license

- [dream-recomp](https://github.com/phobos665/dream-recomp) by phobos665, GPL-2.0.
- The English translation is the
  [deSPIRIA Translation Initiative](https://github.com/deSPIRIA-Translation-Iniative/despiria-patcher-releases)'s
  work; this kit contains none of it and only checks that it is applied.
- deSPIRIA is © Atlus 2000. This project is not affiliated with Atlus or Sega.

This kit is GPL-2.0 (see LICENSE), like dream-recomp, whose files it contains in modified form.

Development disclosure: this kit was put together with the help of an AI coding assistant.
