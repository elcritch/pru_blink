#ifndef __HEADER_PRU_COMMON_H__
#define __HEADER_PRU_COMMON_H__

typedef struct {
	uint32_t speed;
	uint8_t spi_msg;
} SettingsData;

typedef struct {
	uint32_t result;
} SpiData;

typedef struct {
  SettingsData settings;
  SpiData spi_data;
} SharedStruct;


#endif
