# PruExample (for Nerves!)

## Updates [WIP]

This is a fork from nuclearcanary's `pru_example` example but has been extensively modifed. The PRU C example now includes a second example showcasing async communication between Elixir and PRU1. RPmsg and an updated [pru](https://github.com/elcritch/pru) library are used to provide this async messaging support. 

Furthermore the examples also include examples of using the PRU scratchpad's from C/C++ and the pru shared ram (12kb). Neither of these examples were clear from the TI source, so a helper header has been made under `pru/lib/src/pru_support_lib/pru_support_lib.h` which includes various helpers for using both. The eventual goals are to transform the helper header into a full support library mimicking the Arduino coding environment as far feasible. 

## Targets

Can only be used on the BeagleBone boards.

## Hardware

  * BeagleBone Black/Green
  * LED
  * 470 ohm Resistor
  * Breadboard (Optional but makes things easier)


## Getting Started

~~This app has C code that needs a special compiler. Download the latest
[PRU Code Generation Tools v2.1.5](http://software-dl.ti.com/codegen/non-esd/downloads/download.htm#PRU).
Install and make note of the location, we will need that. Export that
location to the PRU_CGT environment variable.~~

Note, WIP to auto-download TI's code generation tools as a Nerves artifact. This currently partially works, see `make_env:` option `mix.exs` for how this could/will work. 


### Compile the Nerves app
```
export MIX_TARGET=bbb  # Exports environment variable
mix deps.get           # Install dependencies
mix firmware           # Build firmware
mix firmware.burn      # Burn firmware to SD Card
```
### What just happened?

The `Makefile` in the root called the `Makefile` in `/pru/0`. The way `/pru/0/Makefile` is set up automatically copies the compiled firmware to the proper location.
`/pru/0` gets copied to `/rootfs_overlay/lib/firmware/am335x-pru0-fw`.
`/pru/1` gets copied to `/rootfs_overlay/lib/firmware/am335x-pru1-fw`.

### Wire the BeagleBone

![breadboard view](https://github.com/nuclearcanary/pru_example/raw/master/assets/breadboard_view.png)

Insert SD Card into BeagleBone and boot. The first boot after burning the firmware takes about 30 seconds to start blinking the LED. Thereafter it will take about 70 seconds.

## TODO
  * Test with Windows, I currently do not own a Windows machine so help would be appreciated!
  * Figure out why the PRU boots in ~30 seconds first boot after burn, but all subsequent boots require ~70 seconds.

## Learn more
  * TI PRU Code Generation Tools: http://software-dl.ti.com/codegen/non-esd/downloads/download.htm#PRU
  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: http://www.nerves-project.org/
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves
  * [TI C/C++ Compiler Manual](http://www.ti.com/lit/ug/spruhv7b/spruhv7b.pdf)
