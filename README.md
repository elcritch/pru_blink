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

    PWR  +
      --|+|--|--------|------
    /   |+|  |  Eth0  |       \                     P8
    |   |_|  |        |       |
    |O__     |________|    __O|        |============|======|=====|===========|
    | [|]   Led Ground-> [*|] |        | DGND       |   1  |  2  | DGND      |   ... row 1
    | [|]                 [|] |        | MMC1 DAT 6 |   3  |  4  | MMC1 DAT7 |   ... row 2
    | [|]                 [|] |        | MMC1 DAT2  |   5  |  6  | MMC1 DAT3 |   ... row 3
    | [|]                 [|] |        | GPIO 66    |   7  |  8  | GPIO 67   |   ... row 4
    | [|]                 [|] |        | GPIO 69    |   9  | 10  | GPIO 68   |   ... row 5
    | [|]                 [|] |        | GPIO 45    |  11  | 12  | GPIO 44   |   ... row 6
    | [|]                 [|] |        | PWM2B      |  13  | 14  | GPIO 26   |   ... row 7
    | [|]                 [|] |        | GPIO 47    |  15  | 16  | GPIO 46   |   ... row 8
    | [|]     ........    [|] |        | GPIO 27    |  17  | 18  | GPIO 65   |   ... row 9
    | [|]     .      .    [|] |        | PWM2A      |  19  | 20  | MMC1 CMD  |   ... row 10
    | [|]     . TI   .    [|] |        | MMC1 CLK   |  21  | 22  | MMC1 DAT5 |   ... row 11
    | [|]     .      .    [|] |        | MMC1 DAT4  |  23  | 24  | MMC1 DAT1 |   ... row 12
    | [|]     ........    [|] |        | MMC1 DAT0  |  25  | 26  | GPIO 61   |   ... row 13
    | [|]    Led Wire -> [*|] |        | LCD VSYNC  |  27  | 28  | LCD PCLK  |   ... row 14
    | [|]                 [|] |        | LCD HSYNC  |  29  | 30  | LCD ACBias|   ... row 15
    | [|]                 [|] |        | LCD DATA14 |  31  | 32  | LCD DATA15|   ... row 16
    | [|]                 [|] |        | LCD DATA13 |  33  | 34  | LCD DATA11|   ... row 17
    | [|]                 [|] |        | LCD DATA12 |  35  | 36  | LCD DATA10|   ... row 18
    | [|]                 [|] |        | LCD DATA8  |  37  | 38  | LCD DATA9 |   ... row 19
    | [|]                 [|] |        | LCD DATA6  |  39  | 40  | LCD DATA7 |   ... row 20
    | [|]                 [|] |        | LCD DATA4  |  41  | 42  | LCD DATA5 |   ... row 21
    | [|]                 [|] |        | LCD DATA2  |  43  | 44  | LCD DATA3 |   ... row 22
    | [|] -------         [|] |        | LCD DATA0  |  45  | 46  | LCD DATA1 |   ... row 23
    \     | SD  |             /        |============|======|=====|===========|
      ----|     |------------
          -------

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
