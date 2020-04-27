#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"

typedef int32_t token_t;

/* <<--params-def-->> */
#define MAC_N 16
#define MAC_VEC 100
#define MAC_LEN 64

/* <<--params-->> */
const int32_t mac_n = MAC_N;
const int32_t mac_vec = MAC_VEC;
const int32_t mac_len = MAC_LEN;

#define NACC 1

esp_thread_info_t cfg_000[] = {
	{
		.run = true,
		.devname = "mac.0",
		.type = mac,
		/* <<--descriptor-->> */
		.desc.mac_desc.mac_n = MAC_N,
		.desc.mac_desc.mac_vec = MAC_VEC,
		.desc.mac_desc.mac_len = MAC_LEN,
		.desc.mac_desc.src_offset = 0,
		.desc.mac_desc.dst_offset = 0,
		.desc.mac_desc.esp.coherence = ACC_COH_NONE,
		.desc.mac_desc.esp.p2p_store = 0,
		.desc.mac_desc.esp.p2p_nsrcs = 0,
		.desc.mac_desc.esp.p2p_srcs = {"", "", "", ""},
	}
};

#endif /* __ESP_CFG_000_H__ */
