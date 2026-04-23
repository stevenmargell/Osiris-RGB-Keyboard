# Acer 516 GE (Osiris) RGB Keyboard Linux Controller
Script to get rainbow effect on keyboard of Acer 516 GE (Osiris) Chromebook running Ubuntu 26.04

## Installation Instructions
curl -s [https://raw.githubusercontent.com/stevenmargell/osiris-rgb/main/install_rgb.sh](https://raw.githubusercontent.com/stevenmargell/Osiris-RGB-Keyboard/refs/heads/main/install_rgb.sh) | bash


## Technical Logic: How it Works

The Acer 516 GE uses a unique Embedded Controller (EC) mapping that differs from standard RGB keyboards:

* **Zone Interpolation:** The keyboard is wired in a daisy-chain. By targeting specific "anchor" IDs (**1, 5, 9, 12**), the hardware firmware automatically calculates a smooth color gradient between them.
* **The Global ID:** ID **0** is the "Master" index. Sending a color here overrides all zones for a solid look.
* **Decimal Color Math:** The hardware requires **24-bit Decimal Integers** rather than Hex. 
    * *Formula:* $(R \times 65536) + (G \times 256) + B$.
* **Priority Override:** Hardware-level animations (Demo Mode) take priority. Manual colors only work if `demo 0` is sent first.

## Why this `ectool` version?

Not all `ectool` binaries are equal. This setup compiles the source from **DHowett**, which is specifically compatible with the `rgbkbd` subcommands required for multi-zone Chromebook boards. Compiling locally prevents "Protocol Mismatch" errors found in generic pre-compiled binaries.

## Solid Color Reference
To set the **whole keyboard** to one color, use: `sudo ectool rgbkbd 0 [Value]`

| Color | Decimal Value | Command |
| :--- | :--- | :--- |
| **White** | `16777215` | `sudo ectool rgbkbd 0 16777215` |
| **Red** | `16711680` | `sudo ectool rgbkbd 0 16711680` |
| **Yellow** | `16776960` | `sudo ectool rgbkbd 0 16776960` |
| **Green** | `65280` | `sudo ectool rgbkbd 0 65280` |
| **Cyan** | `65535` | `sudo ectool rgbkbd 0 65535` |
| **Blue** | `255` | `sudo ectool rgbkbd 0 255` |
| **Magenta** | `16711935` | `sudo ectool rgbkbd 0 16711935` |
| **Off** | `0` | `sudo ectool rgbkbd 0 0` |


## Hardware Demo Modes

The Osiris firmware includes built-in animations that run at the hardware level. These are useful if you want dynamic effects without running a background script.

**Note:** Enabling a demo mode will override your static colors. You must run `sudo ectool rgbkbd demo 0` to return to your custom settings.

| Command | Effect |
| :--- | :--- |
| `sudo ectool rgbkbd demo 0` | **Disable Demos** (Required for static colors) |
| `sudo ectool rgbkbd demo 1` | **Cascading Rainbow** (Classic wave effect) |
| `sudo ectool rgbkbd demo 3` | **Breathing/Pulse** (Slow fade in/out) |
