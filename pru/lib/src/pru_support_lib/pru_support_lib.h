

#ifndef __HEADER_PRU_SUPPORT_LIB_H__
#define __HEADER_PRU_SUPPORT_LIB_H__

#include <stdint.h>
#include <stdbool.h>
#include <pru_types.h>

#define PAD_ONE   10
#define PAD_TWO   11
#define PAD_THREE 12

#define EMIT_PRAGMA(x) _Pragma(#x)

#define TX_SCRATCHPAD_FUNC(NAME, PAD, STRUCT)          \
  EMIT_PRAGMA( FUNC_CANNOT_INLINE (tx_scratchpad_##NAME) )                  \
  void tx_scratchpad_##NAME( STRUCT data ) { __xout(PAD, 14, 0, data); }

#define RX_SCRATCHPAD_FUNC(NAME, PAD, STRUCT)          \
  EMIT_PRAGMA( FUNC_CANNOT_INLINE (rx_scratchpad_##NAME) ) \
  STRUCT rx_scratchpad_##NAME() { STRUCT data; __xin( PAD, 14, 0, data); return data; }

#endif
