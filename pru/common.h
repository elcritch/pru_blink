#ifndef __HEADER_PRU_COMMON_H__
#define __HEADER_PRU_COMMON_H__

typedef struct {
	uint32_t speed;
	uint32_t result;
	uint8_t byte;
} SettingsData;

typedef struct {
  SettingsData settings;
} SharedStruct;


#endif
