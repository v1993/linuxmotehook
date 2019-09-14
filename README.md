# linuxmotehook - cemuhook-compliant wiimote motion provider for linux [![CircleCI](https://img.shields.io/circleci/build/github/v1993/linuxmotehook)](https://circleci.com/gh/v1993/linuxmotehook)

Being unable to use WiiMote as motion source under Linux with cemu, I decided to move on and write motion provider by myself, so here we have it.

# Requiments

* WiiRemote (MotionPlus is VERY recommended)
* Lua 5.3
* Lua libraries (they are included in bundle or alternatively can be installed with luarocks manually):
* * [`lgi`](https://github.com/pavouk/lgi) for Lua 5.3 (preferably from git master)
* * [`lua-xwiimote`](https://github.com/v1993/lua-xwiimote) for Lua 5.3
* * [`crc32`](https://luarocks.org/modules/hjelmeland/crc32) for Lua 5.3
* I think you got this, but Linux machine with recent kernel which can be paired with WiiMote

# Usage

1. Install requiments listed above
2. Download this project
3. Copy `config.template.lua` to `config.lua` and edit it if you wish to
4. Run `main.lua` in terminal

WiiMotes can be connected and disconnected both before starting or while working.

# Features

1. Finally working WiiMotehook but for Linux!
2. Highly configurable nature allowing to map one buttons, accelerometer and gyro axises at your will.
3. Ability to calibrate axis values to prevent oversensitivity (real life example: stop chaotic jumping in NSMB: WiiU).
4. Usable as button source as well.
5. Support for few WiiMotes (require tesing).

# Known problems and limitations

1. I have only one WiiMote with built-in MotionPlus, so some aspects of program may not work as expected. If they do, file an issue, please!
2. Nunchuck is not supported, but is planned to.
3. WiiMote may fail to disconnect correctly sometimes and you have to restart program if this happens.
4. Joysticks are not tested (yet), so be ready to find bugs with them.
5. While all-in-one bundle does exist, it is not publicly accesible. Release should be made for this.

# Software it was tested with

1. PadTest -- program used to test motion sources. Leaving gyro noise aside, works flawlessly.
2. Cemu(hook) itself -- tested with few games, works fine.
