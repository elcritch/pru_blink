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

RX_SCRATCHPAD_FUNC(settings, PAD_ONE, SettingsData);

void spiExample() {
  // Setup SPI Master - Mode 0
  IOPins pins = { .miso = , .mosi = 11, .sck = 14 };
  ClockTimings timings = ClockTimings::with_sck_cycle_and_pre_delays(10, 0, 0);
  uint8_t out;

  SpiMaster<uint8_t, Polarity::Std, PollEdge::Rising, MsbFirst, SpiClockToggler> spi0(pins, timings);

}

void blinkExample() {
  __SHARED_MEMORY__(SharedStruct, shared_mem);

	/* uint32_t gpio = 0x834F; */

	SettingsData settings = { 8000 };

  bool state = true;
	while (1) {
		/* __R30 ^= gpio; */
    /* __R30 ^= gpio_15 & ( __R30 ^ (state ? HIGH : LOW)); */

    digitalWrite(PRU0_GO_P8_11, state ? HIGH : LOW);
    state = !state;

    uint32_t i = 0;
    for (i = settings.speed; i > 0; --i) {
      __delay_cycles(1000);

      if (CT_INTC.SRSR0 & (1 << (16+9)) ) {
        settings = shared_mem->settings;

        CT_INTC.SECR0 = (1 << (16 + 9));
      }
    }
	}
}

void main(void)
{
	/* Clear SYSCFG[STANDBY_INIT] to enable OCP master port */
	CT_CFG.SYSCFG_bit.STANDBY_INIT = 0;
	CT_INTC.SICR_bit.STS_CLR_IDX = PRU1_PRU0_INTERRUPT;


  blinkExample();
  /* spiExample(); */
}
