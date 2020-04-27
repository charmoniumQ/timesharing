#ifndef _SYNTH_H_
#define _SYNTH_H_

#ifdef __KERNEL__
#include <linux/ioctl.h>
#include <linux/types.h>
#else
#include <sys/ioctl.h>
#include <stdint.h>
#ifndef __user
#define __user
#endif
#endif /* __KERNEL__ */

#include <esp.h>
#include <esp_accelerator.h>

enum synth_pattern {PATTERN_STREAMING = 0, PATTERN_STRIDED, PATTERN_IRREGULAR};

struct synth_cfg {
        unsigned int offset;                    /* Memory offset when chaining dependent accelerators */
        enum synth_pattern pattern;             /* load pattern: streaming, strided, irregular */
        unsigned int in_size;                   /* size of input dataset */
        unsigned int access_factor;             /* accessed portion of dataset */
        unsigned int burst_len;                 /* dma burst length */
        unsigned int compute_bound_factor;      /* cycles for word transferred */
        unsigned int irregular_seed;            /* random integer used for irregular DMA */
        unsigned int reuse_factor;              /* # of times the dataset is accessed */
        unsigned int ld_st_ratio;               /* size of data to be loaded w.r.t data to be stored */
        unsigned int stride_len;                /* stride length for strided pattern */
        unsigned int out_size;                  /* size of output dataset */
        unsigned int in_place;                  /* output stored in place of input */
};

struct synth_access {
	struct esp_access esp;
	struct synth_cfg cfg;
};

enum alloc_effort {ALLOC_NONE, ALLOC_AUTO};


#define SYNTH_IOC_ACCESS	_IOW ('S', 0, struct synth_access)

#endif /* _SYNTH_H_ */
