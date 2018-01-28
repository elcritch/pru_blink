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

volatile register uint32_t __R30;
volatile register uint32_t __R31;

#define HOST_INT			((uint32_t) 1 << 31)	
#define PRU_SHAREDMEM 0x00012000

/* PRU-to-ARM interrupt */
#define PRU_SCRATCHPAD_1 10

#define PRU1_PRU0_INTERRUPT (16)

typedef struct {
	uint32_t speed;
} SettingsData;

RX_SCRATCHPAD_FUNC(settings, PAD_ONE, SettingsData);

void main(void)
{
  volatile int* shared_mem = (volatile int *) PRU_SHAREDMEM;
	volatile uint32_t gpio;

	SettingsData settings;
  settings.speed = 1;
  uint32_t i = 0;

	/* Clear SYSCFG[STANDBY_INIT] to enable OCP master port */
	CT_CFG.SYSCFG_bit.STANDBY_INIT = 0;
	CT_INTC.SICR_bit.STS_CLR_IDX = PRU1_PRU0_INTERRUPT;

	/* Toggle GPO pins
    https://github.com/derekmolloy/boneDeviceTree/blob/master/docs/BeagleboneBlackP8HeaderTable.pdf
    https://github.com/derekmolloy/boneDeviceTree/blob/master/docs/BeagleboneBlackP9HeaderTable.pdf
    Use these tables to find the correct pin address
    P8_11 = 0x834
    */
	gpio = 0x834F;

	/* TODO: Create stop condition, else it will toggle indefinitely */
	while (1) {
		__R30 ^= gpio;

    for (i = settings.speed; i > 0; --i) {
      __delay_cycles(10000000);
    }

    if (CT_INTC.SRSR0 & (1 << (16+9)) ) {
      /* XFR registers R5-R10 from PRU0 to PRU1 */
      /* 14 is the device_id that signifies a PRU to PRU transfer */
      /* __xin(PRU_SCRATCHPAD_1, 5, 0, settings); */

      /* Clear the status of the interrupt */
      /* SettingsData input = rx_scratchpad_settings(); */
      /* settings = input; */

      settings = *((SettingsData*)(shared_mem));

      CT_INTC.SECR0 = (1 << (16 + 9));
    }
	}
}
