# linuxmotehook - cemuhook-compliant wiimote motion provider for linux
## Please see [linuxmotehook2](https://github.com/v1993/linuxmotehook2) for successor to this project.
[![CircleCI](https://img.shields.io/circleci/build/github/v1993/linuxmotehook)](https://circleci.com/gh/v1993/linuxmotehook)
[![GitHub Releases](https://img.shields.io/github/downloads/v1993/linuxmotehook/latest/total)](https://github.com/v1993/linuxmotehook/releases/latest)
[![Ko-Fi](https://img.shields.io/badge/sponsor-Ko--Fi-brightgreen)](https://ko-fi.com/v19930312)

Being unable to use WiiMote as motion source under Linux with cemu, I decided to move on and write motion provider by myself, so here we have it.

# Requiments

* WiiRemote (MotionPlus is VERY recommended)
* Lua 5.3
* Lua libraries (they are included in bundle or alternatively can be installed with luarocks manually):
* * [`lgi`](https://github.com/pavouk/lgi) for Lua 5.3 (preferably from git master): Licensed under MIT
* * [`lua-xwiimote`](https://github.com/v1993/lua-xwiimote) for Lua 5.3: Licensed under MIT
* * [`crc32`](https://luarocks.org/modules/hjelmeland/crc32) for Lua 5.3: Licensed under MIT
* * [`luajson`](https://github.com/harningt/luajson) for Lua 5.3: Licensed under MIT (not included into bundle as can be installed as Ubuntu package)
* * [`LPeg`](https://luarocks.org/modules/gvvaughan/lpeg) for Lua 5.3 (optional): Licensed under MIT
* I think you got this, but Linux machine with recent kernel which can be paired with WiiMote

To use bundle, following packages should be installed on Ubuntu (checked with minimal installation):

* `lua5.3`
* `libxwiimote2`
* `lua-json`

# Usage

1. Install requiments listed above
2. Download this project
3. Copy `config.template.json` to `config.json` and edit it if you wish to (read GitHub Wiki for details on this)
4. Connect your WiiMotes with MotionPlus one-by-one and calibrate each using `autocalibrate.lua`, writing results to `Calibration` in config (for your WiiMote MAC of course)
5. Run `main.lua` in terminal
6. Get PadTest and test all of your WiiMotes with MotionPlus, inverting some or all axles if required (try changin values 5, 6 and 7 in calibration fields to `-1`)
7. Use Cemu with Cemuhook as you would with any other motion provider!

WiiMotes can be connected and disconnected both before starting or while working.

# Features

1. Finally working WiiMoteHook but for Linux!
2. Highly configurable nature allowing to map buttons, accelerometer and gyro axles at your will.
3. Ability to calibrate axis values to prevent oversensitivity (real life example: stop chaotic jumping in New SMB U).
4. Usable as button source as well, including joysticks.
5. Support for few WiiMotes (require tesing).
6. Standalone bundle which can be run with minimal setup.
7. Atuocalibration script which help to stop constant slow rotation.

# Known problems and limitations

1. I have only one WiiMote with built-in MotionPlus, so some aspects of program may not work as expected. If they do, file an issue, please!
2. Nunchuck is not supported, but is planned to. Due to limits of xwiimote version in Ubuntu repository, however, this feature is delayed.
3. WiiMote may fail to disconnect correctly sometimes and you have to restart program if this happens.
4. Built-in MotionPlus have different axis directions between models, so PadTest must be used to fix directions.
Canonical ones (separate MPlus reports) are unknown to me, so ones used correspond to built-in MPlus I own.
They are really wanted tho, so if you have separate MPlus, make sure to report which axles you had to reverse!
5. Autocalibration scipt have a lot of potential improvements, from adding proper support for few WiiMotes plugged in to making it GUI.

# Software it was tested with

1. PadTest -- program used to test motion sources. Leaving gyro noise aside, works flawlessly.
2. Cemu(hook) itself -- tested with few games, works fine.
3. Citra -- tested with Kirby: Planet Robobot, may loose orientation a bit but is still very playable (much better than right mouse button).
4. Dolphin -- tested with few games. Buttons are functioning flawlessly and motion is working ok, but it is recommended to use built-in means
of connecting WiiMote unless required otherwise. `Dolphin` profile is made specifically for this emulator.
