/*
 * Copyright (C) 2016 Texas Instruments Incorporated - http://www.ti.com/
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
#include <stdio.h>
#include <string.h>
#include <pru_cfg.h>
#include <pru_intc.h>
#include <rsc_types.h>
#include <pru_rpmsg.h>
#include "resource_table_1.h"

#include <msgpck.h>
#include <pru_support_lib.h>

#include "../common.h"

volatile register uint32_t __R31;

/* Host-1 Interrupt sets bit 31 in register R31 */

/* The PRU-ICSS system events used for RPMsg are defined in the Linux device tree
 * PRU0 uses system event 16 (To ARM) and 17 (From ARM)
 * PRU1 uses system event 18 (To ARM) and 19 (From ARM)
 */
#define TO_ARM_HOST			18
#define FROM_ARM_HOST			19
#define PRU1_PRU0_INTERRUPT (16)

/*
 * Using the name 'rpmsg-client-sample' will probe the RPMsg sample driver
 * found at linux-x.y.z/samples/rpmsg/rpmsg_client_sample.c
 *
 * Using the name 'rpmsg-pru' will probe the rpmsg_pru driver found
 * at linux-x.y.z/drivers/rpmsg/rpmsg_pru.c
 */
//#define CHAN_NAME			"rpmsg-client-sample"
#define CHAN_NAME			"rpmsg-pru"
#define CHAN_DESC			"Channel 31"
#define CHAN_PORT			31


/*
 * Used to make sure the Linux drivers are ready for RPMsg communication
 * Found at linux-x.y.z/include/uapi/linux/virtio_config.h
 */
#define VIRTIO_CONFIG_S_DRIVER_OK	4

uint8_t payload[RPMSG_BUF_SIZE];
uint8_t buf[128];
char cmd[16];

TX_SCRATCHPAD_FUNC(settings, PAD_ONE, SettingsData);

/*
 * main.c
 */
void main(void)
{
  __SHARED_MEMORY__(SharedStruct, shared_mem);
	struct pru_rpmsg_transport transport;
	uint16_t src, dst, len;
	volatile uint8_t *status;

	SettingsData settings;
  settings.speed = 1;

	/* Allow OCP master port access by the PRU so the PRU can read external memories */
	CT_CFG.SYSCFG_bit.STANDBY_INIT = 0;

	/* Clear the status of the PRU-ICSS system event that the ARM will use to 'kick' us */
	CT_INTC.SICR_bit.STS_CLR_IDX = FROM_ARM_HOST;

	/* Make sure the Linux drivers are ready for RPMsg communication */
	status = &resourceTable.rpmsg_vdev.status;
	while (!(*status & VIRTIO_CONFIG_S_DRIVER_OK));

	/* Initialize the RPMsg transport structure */
	pru_rpmsg_init(&transport, &resourceTable.rpmsg_vring0, &resourceTable.rpmsg_vring1, TO_ARM_HOST, FROM_ARM_HOST);

  Stream rx;
  Stream sb;

	/* Create the RPMsg channel between the PRU and ARM user space using the transport structure. */
	while (pru_rpmsg_channel(RPMSG_NS_CREATE, &transport, CHAN_NAME, CHAN_DESC, CHAN_PORT) != PRU_RPMSG_SUCCESS);

	while (1) {
		/* Check bit 30 of register R31 to see if the ARM has kicked us */
		if (__R31 & HOST_INT_1) {
			/* Clear the event status */
			CT_INTC.SICR_bit.STS_CLR_IDX = FROM_ARM_HOST;

			/* Receive all available messages, multiple messages can be sent per kick */
			while (pru_rpmsg_receive(&transport, &src, &dst, payload, &len) == PRU_RPMSG_SUCCESS) {
				/* Echo the message back to the same address from which we just received */
        stream_setup(&rx, payload, len);

        uint32_t arrsz, speed;
        if (msgpck_read_array_size(&rx, &arrsz) && arrsz == 2 &&
            msgpck_read_string(&rx, cmd, sizeof(cmd)) &&
            msgpck_read_integer(&rx, (byte*)&speed, 4)
        ) {
          /* Update settings */
          settings.speed = speed;
          if (strncmp("set31", cmd, sizeof(cmd)) == 0) {

            settings.speed = speed;
            tx_scratchpad_settings(settings);

            SettingsData * main_settings = (SettingsData*)(shared_mem);
            *main_settings = settings;

            __R31 = (1<<5) | 9;
          } else if (strncmp("secr0", cmd, sizeof(cmd)) == 0) {
            CT_INTC.SECR0 = (1 << (16 + 9));
          } else if (strncmp("secr1", cmd, sizeof(cmd)) == 0) {
            CT_INTC.SECR1 = (1 << speed);
          }

          /* Send data back to port driver */
          stream_setup(&sb, buf, 128);
          msgpck_write_array_header(&sb, 2);
          msgpck_write_string(&sb, "ok", 2);
          msgpck_write_string(&sb, cmd, 5);
          pru_rpmsg_send(&transport, dst, src, sb.data, sb.pos);

          stream_setup(&sb, buf, 128);
          msgpck_write_array_header(&sb, 6);
          msgpck_write_string(&sb, "data", 4);
          msgpck_write_integer_u32(&sb, __R31);
          msgpck_write_integer_u32(&sb, CT_INTC.SRSR0);
          msgpck_write_integer_u32(&sb, CT_INTC.SRSR0 & ( 1 << (16+9) ));
          msgpck_write_integer_u32(&sb, CT_INTC.SRSR0 & ( 1 << (16+10) ));
          msgpck_write_integer_u32(&sb, CT_INTC.SRSR0 & ( 1 << (16+8) ));
          pru_rpmsg_send(&transport, dst, src, sb.data, sb.pos);

        } else {
          msgpck_write_array_header(&sb, 3);
          msgpck_write_string(&sb, "err", 3);
          msgpck_write_string(&sb, (char *)payload, len);
          msgpck_write_integer_u32(&sb, arrsz);
          pru_rpmsg_send(&transport, dst, src, sb.data, sb.pos);
        }

			}
		}
	}
}
