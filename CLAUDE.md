# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a port of the Free Vision (FV) text-mode UI framework from Free Pascal to modern Delphi (10.x, 11.x, 12.x). Free Vision is a classic console-based GUI toolkit originally from Turbo Pascal.

**Key constraint**: The port maintains the legacy Turbo Pascal `OBJECT` syntax - do not convert to `CLASS`.

## Original source code

The original sourcecode for free vision is in C:\temp\fpc\fpc\packages\fv reference it as necessary.

## Build Commands

Use the MCP build tool with **Win32** platform and **Debug** configuration:

`mcp__dbuildmcp__msbuild with projectfile="C:/projects/fv-delphi/FVTest.dproj", platform="Win32", config="Debug"`

**Important**: Always use Win32/Debug during development. The project targets 32-bit Windows.

## Testing

There is no automated test suite. Testing is done via the interactive `FVTest.exe` application:

```bash
# Run after building
FVTest.exe
```

The test app exercises all ported widgets through menu options (Test menu). Debug output is written to `fvtest.log`.

## Architecture

### Core Layering (bottom to top)
1. **FVCommon.pas** - Platform types (`Sw_Word`, `Sw_String = ShortString`, `PString`)
2. **Objects.pas** - Base object system, streams, collections (`TObject`, `TStream`, `TCollection`)
3. **Video.pas** - Console output via Windows Console API
4. **Drivers.pas** - Input handling (keyboard, mouse, event queue)
5. **Views.pas** - View hierarchy (`TView`, `TGroup`, `TWindow`, `TDesktop`)
6. **Menus.pas** - Menu system (`TMenuBar`, `TMenuBox`, `TStatusLine`)
7. **App.pas** - Application framework (`TProgram`, `TApplication`)
8. **Dialogs.pas** - Dialog controls (`TDialog`, `TButton`, `TInputLine`, `TCheckBoxes`, etc.)

### Extended Components
- **MsgBox.pas, StdDlg.pas** - Standard dialogs (message boxes, file dialogs)
- **Validate.pas** - Input validators
- **Gadgets.pas** - `TClockView`, `THeapView`
- **Tabs.pas** - Tab control
- **TimedDlg.pas** - Auto-closing dialogs
- **ColorTxt.pas, InpLong.pas, AsciiTab.pas** - Specialized widgets

### Platform Abstraction
`src/platform.inc` handles compiler/platform detection. Key defines:
- `PPC_DELPHI` / `PPC_FPC` - Compiler type
- `BIT_32` / `BIT_64` - Architecture
- `OS_WINDOWS` - Target OS

## Code Conventions

### Type System
- Use `ShortString` (aliased as `Sw_String`) for FV string types
- Use `PString` (pointer to ShortString) with `NewStr`/`DisposeStr` from Objects.pas
- Use `THandle` from `Winapi.Windows` for file handles
- CPU-native types: `CPUWord`, `CPUInt`, `PtrInt`

### Compiler Directives
- Range checking OFF (`{$R-}`) in units with pointer arithmetic
- Warnings suppressed for legacy patterns (see platform.inc)
- Include `{$I platform.inc}` at the top of source units

### Memory Management
- Views are owned by their parent `TGroup` and disposed automatically
- Use `New(PTypeName, Init(...))` pattern for object creation
- Call `Dispose(Ptr, Done)` for cleanup

## Porting Status

See `PORTING_STATUS.txt` for detailed status. Core functionality is complete. Recently ported:
- **Editors.pas** - Text editor (compiles, needs testing)
- **ColorSel.pas** - Color selection dialogs
- **Outline.pas** - Tree view (with mousewheel support)

## Known Issues

- Console window resize causes visual artifacts (resize not handled)
- Some units use FPC-specific features like `get_caller_frame` that need alternatives in Delphi
