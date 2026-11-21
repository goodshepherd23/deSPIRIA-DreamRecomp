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
  Game into the opening story**. Tested by the kit author through the opening with the Chapter 1
  preview patch; not a playthrough.
- **Full Game Beta 1** (new in v0.1.2): the **Swift** build is confirmed working. It builds with the
  same configuration as the preview and runs. Setup also accepts the Original and VMU party
  status builds, but no one has reported on them yet.
- **Full speed** on a 15 W Intel i7-1355U laptop with integrated graphics.
- **Saves** go to a memory card file, `saves\vmu-a1.bin` in your
  [data folder](#where-your-files-live), outside the app folder.
- Keyboard and SDL-compatible controllers.

This is early: expect rough edges, and keep a copy of your memory card.

## What you need

- Windows 10 or 11, 64-bit, with a Vulkan-capable GPU (any recent Intel, AMD or NVIDIA).
- **deSPIRIA (Japan), T14402M**, dumped from your own disc as a **GDI** image (`.gdi` plus its
  track files).
- **The English patch applied to it** (see below), and the `.gdi` the patcher writes.
- About **3 GB** of free space and an internet connection for the first launch.

## The English patch

Get the translation team's
[**Full Game Beta 1**](https://github.com/deSPIRIA-Translation-Iniative/despiria-patcher-releases/releases/tag/v1.0.0-beta1)
(v1.0.0-beta1, `deSPIRIA-English-Translation-Setup.zip`), extract it and run
`deSPIRIA-English-Translation-Setup.exe` on your own disc dump. It takes a GDI or CHD image and
writes an English-patched `despiria.gdi`; choose that file when this kit's setup asks for your
disc.

- **The whole story is in English**, start to finish, along with menus, MIND and item names,
  battle text, maps, signposts and the translated graphics.
- **Pacing:** *Original* (retail enemy health, encounter rate and rewards) or *Swift* (shorter
  regular battles, fewer random encounters, quicker MIND visuals, rewards rebalanced). The kit
  accepts either; Swift is the one confirmed working so far.
- **VMU live party status** is an experimental option, off by default; the team asks you to try it
  only if you want to help test it.
- The setup also includes a save editor.

It is a **beta for feedback**, not the final release: expect rough edges and report them to the
team on their Discord thread, per their release notes. Old saves should load, but the team asks you
to **back up your saves first** (with this kit that's `saves\vmu-a1.bin` in your
[data folder](#where-your-files-live)).

The release zip's SHA-256 is
`3b14f7f8f58bd1a4bcb0c9d2dc1e40e7f33f6f8b37750caa16b2db40c0e9b87e`; the setup program is unsigned,
so some antivirus engines flag it.

### Still on the Chapter 1 preview?

The kit still accepts discs patched with the earlier Chapter 1 preview (any of its Original, Brisk
or Swift settings), but that preview translates only Chapter 1's story. Re-patching with Full Game
Beta 1 is the way to read the rest; if you stay on the preview,
[LunaTranslator](https://github.com/HIllya51/LunaTranslator) in OCR mode (Japanese to English,
region over the whole picture, since deSPIRIA has no fixed dialogue box) or popomocco's
[complete translated playthrough on YouTube](https://www.youtube.com/playlist?list=PLNWIo8BxEFzYPOp2jkPlwOrT1MoDREDCq)
fill in the later chapters.

Switching discs: patch the new disc, then run `deSPIRIA.exe --setup` and choose it. The game is
rebuilt for the new disc's program automatically.

## Install

**RecompLauncher:** find **deSPIRIA reBIRTH** in the catalog, install it and press Play. Updates
come through the launcher too.

**Quiver Launcher:** add deSPIRIA from the catalog and press Play.

**By hand:** extract the release zip anywhere and run `deSPIRIA.exe`.

On first launch a setup window opens:

1. It asks for your English-patched `.gdi` and checks it is deSPIRIA with the English patch
   (Full Game Beta 1, or the earlier Chapter 1 preview).
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
  work: translation by rio de popomocco; programming by DinoJesus (John) and Swamp Izzo Stan 2025;
  testing, feedback and QA by Swamp Izzo Stan 2025 and Hazric. This kit contains none of it and
  only checks that it is applied.
- deSPIRIA is © Atlus 2000. This project is not affiliated with Atlus or Sega.

This kit is GPL-2.0 (see LICENSE), like dream-recomp, whose files it contains in modified form.

Development disclosure: this kit was put together with the help of an AI coding assistant.
