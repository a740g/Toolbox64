# TOOLBOX64

This is A740G's Toolbox. A collection of useful libraries for QB64-PE.

| File name | Category | Description |
|-----------|----------|-------------|
| Common.bi | General | Common header included by everything in here |
| AnalyzerFFT.bi | Math | FFT library for audio analyzers |
| ANSIPrint.bas<br>ANSIPrint.bi | Text | ANSI escape sequence emulator library |
| Base64.bas<br>Base64.bi | Encoding | Base64 encoding, decoding and resource loading library |
| CRTLib.bas<br>CRTLib.bi | System | CRT bindings and other low level functions library |
| Easings.bi | Math | Bindings to raylib Easing functions library |
| FileOps.bas<br>FileOps.bi | File system | File, path and file system functions library |
| ImGUI.bas<br>ImGUI.bi | GUI | Immediate mode GUI library |
| WinMIDIPlayer.bas<br>WinMIDIPlayer.bi | Audio | Windows native MIDI library |
| MIDIPlayer.bas<br>MIDIPlayer.bi | Audio | Cross platform MIDI player library using Soundfonts and OPL3 emulation |
| MODPlayer.bas<br>MODPlayer.bi<br>SoftSynth.bas<br>SoftSynth.bi | Audio | Protracker and compatible MOD player library |
| ProgramArgs.bas | System | Program argument parsing library |
| VGAFont.bas<br>VGAFont.bi | Font| PSF font library |

## USAGE

Assuming you made this a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) in a directory called `include` in your source tree, do the following:

```vb
' At the top of your code include the library_name.bi file (if it has one)
'$Include:'include/library_name.bi'

' Your code here...

' At the bottom of your code include the library_name.bas file (if it has one)
'$Include:'include/library_name.bas'
```

## NOTES

- I made this for myself and as such, it is tailored to my coding style and conventions
- Expect this to keep changing and evolving
- This is not backward compatible with older versions of QB64-PE or QB64
- All files here are in source-only form and will never include any binaries
- There is no directory structure. This lends itself well to the fact that you can conveniently use this as a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- All library files have include guards. You can include these multiple times (even from your own include files)
- I do not use the `.bm` extension because GitHub does not syntax-highlight `.bm` files
