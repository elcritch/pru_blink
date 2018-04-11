/*
 * Copyright (C) 2015 Texas Instruments Incorporated - http://www.ti.com/
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *	* Redistributions of source code must retain the above copyright
 *	  notice, this list of conditions and the following disclaimer.
 *
 *	* Redistributions in binary form must reproduce the above copyright
 *	  notice, this list of conditions and the following disclaimer in the
 *	  documentation and/or other materials provided with the
 *	  distribution.
 *
 *	* Neither the name of Texas Instruments Incorporated nor the names of
 *	  its contributors may be used to endorse or promote products derived
 *	  from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdint.h>
#include <pru_cfg.h>
#include "resource_table_empty.h"
#include <pru_intc.h>
#include <pru_support_lib.h>
#include <pru_support_pins.h>


#include "../common.h"

#define HOST_INT			((uint32_t) 1 << 31)
#define PRU_SHAREDMEM 0x00012000

/* PRU-to-ARM interrupt */
#define PRU_SCRATCHPAD_1 10

#define PRU1_PRU0_INTERRUPT (16)
#define BB_BLACK

// #define BLINK_EXAMPLE
#define SPI_EXAMPLE

RX_SCRATCHPAD_FUNC(settings, PAD_ONE, SettingsData);

#ifdef BLINK_EXAMPLE

#include <string.h>

void blinkExample() {
  __SHARED_MEMORY__(SharedStruct, shared_mem);

	/* uint32_t gpio = 0x834F; */

	SettingsData settings = { 8000 };

  digitalWrite(PRU1_GI_P8_28, HIGH);

  bool state = true;
	while (1) {
		/* __R30 ^= gpio; */
    /* __R30 ^= gpio_15 & ( __R30 ^ (state ? HIGH : LOW)); */

    digitalWrite(0xFF, state ? HIGH : LOW);
    digitalToggle(0xFF);
    state = !state;

    uint32_t i = 0;
    for (i = settings.speed; i > 0; --i) {
      __delay_cycles(1000);

      if (CT_INTC.SRSR0 & (1 << (16+9)) ) {
        // C++ a& Volatile don't seem to mix well -\_(`.`)_/-
        memcpy(&settings, (SettingsData*) &shared_mem->settings, sizeof (SettingsData));
        // settings = rx_scratchpad_settings();

        CT_INTC.SECR0 = (1 << (16 + 9));
      }
    }
	}
}
#endif

#ifdef SPI_EXAMPLE

#define NOOP __delay_cycles(1000);
// #define NOOP __delay_cycles(10000);

#include <softspi.hpp>
#include <string.h>
using namespace SoftSPI;

/*
     ~ Power ~
      --|+|--|--------|------
    /   |+|  |  Eth0  |       \
    |   |_|  |        |       |
    |O__     |________|    __O|
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]     ........    [|] |
    | [|]     .      .    [|] |
    | [|]     . TI   .    [|] |
    | [|]     .      .    [|] |
    | [|]     ........    [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]                 [|] |
    | [|]             [CS1 |] |
    | [|]             [SCK |] |
    | [|]             [MOSI|] |
    | [|] -------     [MISO|] |
    \     | SD  |             /
      ----|     |------------
          -------

 */
// ClockTimings timings = ClockTimings::with_sck_cycle_and_pre_delays(10, 0, 0);

template <uint32_t cycles>
struct ClockDelay {
  void operator()() {
    __delay_cycles(cycles);
  }
};


// typedef ClockTimings<5,0,16,0,16, ClockDelay> Timings;
// const IOPins pins = { .miso = PRU1_GI_P8_45, .mosi = PRU1_GI_P8_43, .sck = PRU1_GI_P8_44 };
// const Pin spi_dev_1 = PRU1_GI_P8_39;

void spiExample() {
  __SHARED_MEMORY__(SharedStruct, shared_mem);
  SharedStruct * main_settings = (SharedStruct*)(shared_mem);
  // Setup SPI Master - Mode 0

  // SpiMaster<uint8_t, Std, Rising, MsbFirst, SpiClock, Timings> spi(pins);

  digitalWrite(PRU1_GI_P8_27, LOW);

	SettingsData settings = { 8000, 0xAA };
	// SpiData spi_data;
  // int32_t state = 0;
  bool state = true;

  digitalWrite(PRU1_GI_P8_27, HIGH);

  while (1) {

    // digitalWrite(pins.mosi, LOW);
    // digitalWrite(pins.sck, LOW);

    // settings.result_old = settings.result;
    // settings.result = 0;
    // spi_data.result = spi.transfer(spi_dev_1, settings.spi_msg);

    // tx
    // memcpy((SettingsData*) &shared_mem->settings, &settings, sizeof (SettingsData));
    // main_settings->spi_data = spi_data;
    // digitalToggle(PRU1_GI_P8_27);
    digitalWrite(PRU1_GI_P8_27, state ? HIGH : LOW);

    // state = state > settings.speed ? -settings.speed : state + 1;
    state = !state;

    uint32_t i = 0;
    for (i = settings.speed; i > 0; --i) {
      // __delay_cycles(1000);
      ClockDelay<1000>()();

      if (CT_INTC.SRSR0 & (1 << (16+9)) ) {
        // C++ a& Volatile don't seem to mix well -\_(`.`)_/-
        // rx
        // memcpy(&settings, (SettingsData*) &shared_mem->settings, sizeof (SettingsData));

        settings = main_settings->settings;

        // settings = rx_scratchpad_settings();

        CT_INTC.SECR0 = (1 << (16 + 9));
      }
    }
  }
}
#endif


void main(void)
{
	/* Clear SYSCFG[STANDBY_INIT] to enable OCP master port */
	CT_CFG.SYSCFG_bit.STANDBY_INIT = 0;
	CT_INTC.SICR_bit.STS_CLR_IDX = PRU1_PRU0_INTERRUPT;


  #ifdef BLINK_EXAMPLE
    blinkExample();
  #endif

  #ifdef SPI_EXAMPLE
    spiExample();
  #endif
}

