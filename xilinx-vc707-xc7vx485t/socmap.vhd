-- Copyright (c) 2011-2019 Columbia University, System Level Design Group
-- SPDX-License-Identifier: Apache-2.0

------------------------------------------------------------------------------
--  This file is a configuration file for the ESP NoC-based architecture
-----------------------------------------------------------------------------
-- Package:     socmap
-- File:        socmap.vhd
-- Author:      Paolo Mantovani - SLD @ Columbia University
-- Author:      Christian Pilato - SLD @ Columbia University
-- Description: System address mapping and NoC tiles configuration
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.esp_global.all;
use work.stdlib.all;
use work.grlib_config.all;
use work.amba.all;
use work.sld_devices.all;
use work.devices.all;
use work.leon3.all;
use work.nocpackage.all;
use work.allcaches.all;
use work.cachepackage.all;
package socmap is

  ------ NoC parameters
  constant CFG_XLEN : integer := 2;
  constant CFG_YLEN : integer := 2;
  constant CFG_TILES_NUM : integer := CFG_XLEN * CFG_YLEN;
  ------ DMA memory allocation (contiguous buffer or scatter/gather
  constant CFG_SCATTER_GATHER : integer range 0 to 1 := 1;
  constant CFG_L2_SETS     : integer := 512;
  constant CFG_L2_WAYS     : integer := 4;
  constant CFG_LLC_SETS    : integer := 1024;
  constant CFG_LLC_WAYS    : integer := 16;
  constant CFG_ACC_L2_SETS : integer := 512;
  constant CFG_ACC_L2_WAYS : integer := 4;
  ------ Monitors enable (requires proFPGA MMI64)
  constant CFG_MON_DDR_EN : integer := 0;
  constant CFG_MON_MEM_EN : integer := 0;
  constant CFG_MON_NOC_INJECT_EN : integer := 0;
  constant CFG_MON_NOC_QUEUES_EN : integer := 0;
  constant CFG_MON_ACC_EN : integer := 0;
  constant CFG_MON_L2_EN : integer := 0;
  constant CFG_MON_LLC_EN : integer := 0;
  constant CFG_MON_DVFS_EN : integer := 0;

  ------ Coherence enabled
  constant CFG_L2_ENABLE   : integer := 1;
  constant CFG_L2_DISABLE  : integer := 0;
  constant CFG_LLC_ENABLE  : integer := 1;

  ------ Number of components
  constant CFG_NCPU_TILE : integer := 1;
  constant CFG_NMEM_TILE : integer := 1;
  constant CFG_NL2 : integer := 1;
  constant CFG_NLLC : integer := 1;
  constant CFG_NLLC_COHERENT : integer := 1;

  ------ Local-port Synchronizers are always present)
  constant CFG_HAS_SYNC : integer := 1;
  constant CFG_HAS_DVFS : integer := 0;

  ------ Caches interrupt line
  constant CFG_SLD_LLC_CACHE_IRQ : integer := 4;

  constant CFG_SLD_L2_CACHE_IRQ : integer := 3;

  ------ Maximum number of slaves on both HP bus and I/O-bus
  constant maxahbm : integer := NAHBMST;
  constant maxahbs : integer := NAHBSLV;
  -- Arrays of Plug&Play info
  subtype apb_l2_pconfig_vector is apb_config_vector_type(0 to CFG_NL2-1);
  subtype apb_llc_pconfig_vector is apb_config_vector_type(0 to CFG_NLLC-1);
  -- Array of design-point or implementation IDs
  type tile_hlscfg_array is array (0 to CFG_TILES_NUM - 1) of hlscfg_t;
  -- Array of attributes for clock regions
  type domain_type_array is array (0 to 0) of integer;
  -- Array of device IDs
  type tile_device_array is array (0 to CFG_TILES_NUM - 1) of devid_t;
  -- Array of I/O-bus indices
  type tile_idx_array is array (0 to CFG_TILES_NUM - 1) of integer range 0 to NAPBSLV - 1;
  -- Array of attributes for I/O-bus slave devices
  type apb_attribute_array is array (0 to NAPBSLV - 1) of integer;
  -- Array of IRQ line numbers
  type tile_irq_array is array (0 to CFG_TILES_NUM - 1) of integer range 0 to NAHBIRQ - 1;
  -- Array of 12-bit addresses
  type tile_addr_array is array (0 to CFG_TILES_NUM - 1) of integer range 0 to 4095;
  -- Array of flags
  type tile_flag_array is array (0 to CFG_TILES_NUM - 1) of integer range 0 to 1;
  -- Array for I/O-bus peripherals enable
  type tile_apb_enable_array is array (0 to CFG_TILES_NUM - 1) of std_logic_vector(0 to NAPBSLV - 1);
  -- Array for bus peripherals enable
  type tile_ahb_enable_array is array (0 to CFG_TILES_NUM - 1) of std_logic_vector(0 to NAHBSLV - 1);

  ------ Plug&Play info on HP bus
  -- Leon3 CPU cores
  constant leon3_hconfig : ahb_config_type := (
    0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_LEON3, 0, LEON3_VERSION, 0),
    others => zero32);

  -- JTAG master interface, acting as debug access point
  -- Ethernet master interface, acting as debug access point
  constant eth0_hconfig : ahb_config_type := (
    0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_ETHMAC, 0, 0, 0),
    others => zero32);

  -- Enable SGMII controller iff needed
  constant CFG_SGMII : integer range 0 to 1 := 1;

  -- SVGA controller, acting as master on a dedicated bus connecte to the frame buffer
  -- BOOT ROM HP slave
  constant ahbrom_hindex  : integer := 0;
  constant ahbrom_haddr   : integer := 16#000#;
  constant ahbrom_hmask   : integer := 16#fff#;
  constant ahbrom_hconfig : ahb_config_type := (
    0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_AHBROM, 0, 0, 0),
    4 => ahb_membar(ahbrom_haddr, '1', '1', ahbrom_hmask),
    others => zero32);
  -- AHB2APB bus bridge slave
  constant CFG_APBADDR : integer := 16#800#;
  constant ahb2apb_hindex : integer := 1;
  constant ahb2apb_haddr : integer := CFG_APBADDR;
  constant ahb2apb_hmask : integer := 16#F00#;
  constant ahb2apb_hconfig : ahb_config_type := (
    0 => ahb_device_reg ( 1, 6, 0, 0, 0),
    4 => ahb_membar(CFG_APBADDR, '0', '0', ahb2apb_hmask),
    others => zero32);

  -- RISC-V CLINT
  constant clint_hindex  : integer := 2;
  constant clint_haddr   : integer := 16#020#;
  constant clint_hmask   : integer := 16#fff#;
  constant clint_hconfig : ahb_config_type := (
    0 => ahb_device_reg ( VENDOR_SIFIVE, SIFIVE_CLINT0, 0, 0, 0),
    4 => ahb_membar(clint_haddr, '0', '0', clint_hmask),
    others => zero32);

  -- Debug access points proxy index
  constant dbg_remote_ahb_hindex : integer := 3;

  ----  Memory controllers
  -- CPU tiles don't need to know how the address space is split across memory tiles
  -- and each CPU should be able to address any region transparently.
  constant cpu_tile_mig7_hconfig : ahb_config_type := (
    0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_MIG_7SERIES, 0, 0, 0),
    4 => ahb_membar(16#400#, '1', '1', 16#C00#),
    others => zero32);
  -- Network interfaces and ESP proxies, instead, need to know how to route packets
  constant ddr_hindex : mem_attribute_array := (
    0 => 4,
    others => 0);
  constant ddr_haddr : mem_attribute_array := (
    0 => 16#400#,
    others => 0);
  constant ddr_hmask : mem_attribute_array := (
    0 => 16#C00#,
    others => 0);
  -- Create a list of memory controllers info based on the number of memory tiles
  -- We use the MIG interface from GRLIB, which has a device entry for the 7SERIES
  -- Xilinx FPGAs only, however, we provide a patched version of the IP for the
  -- UltraScale(+) FPGAs. The patched intercace shared the same device ID with the
  -- 7SERIES MIG.
  constant mig7_hconfig : ahb_slv_config_vector := (
    0 => (
      0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_MIG_7SERIES, 0, 0, 0),
      4 => ahb_membar(ddr_haddr(0), '1', '1', ddr_hmask(0)),
      others => zero32),
    others => hconfig_none);
  -- On-chip frame buffer (GRLIB)
  constant fb_hindex : integer := 12;
  constant fb_hmask : integer := 16#FFF#;
  constant fb_haddr : integer := CFG_SVGA_MEMORY_HADDR;
  constant fb_hconfig : ahb_config_type := hconfig_none;

  -- HP slaves index / memory map
  constant fixed_ahbso_hconfig : ahb_slv_config_vector := (
    0 => ahbrom_hconfig,
    1 => ahb2apb_hconfig,
    4 => mig7_hconfig(0),
    12 => fb_hconfig,
    others => hconfig_none);

  -- HP slaves index / memory map for CPU tile
  -- CPUs need to see memory as a single address range
  constant cpu_tile_fixed_ahbso_hconfig : ahb_slv_config_vector := (
    0 => ahbrom_hconfig,
    1 => ahb2apb_hconfig,
    4 => cpu_tile_mig7_hconfig,
    12 => fb_hconfig,
    others => hconfig_none);

  ------ Plug&Play info on I/O bus
  -- UART (GRLIB)
  constant uart_pconfig : apb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_APBUART, 0, 1, CFG_UART1_IRQ),
  1 => apb_iobar(16#001#, 16#fff#));

  -- Interrupt controller (Architecture-dependent)
  constant irqmp_pconfig : apb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_IRQMP, 0, 3, 0),
  1 => apb_iobar(16#002#, 16#fff#));

  -- Timer (GRLIB)
  constant gptimer_pconfig : apb_config_type := (
  0 => ahb_device_reg (VENDOR_GAISLER, GAISLER_GPTIMER, 0, 1, CFG_GPT_IRQ),
  1 => apb_iobar(16#003#, 16#fff#));

  -- ESPLink
  constant esplink_pconfig : apb_config_type := (
  0 => ahb_device_reg (VENDOR_SLD, SLD_ESPLINK, 0, 0, 0),
  1 => apb_iobar(16#004#, 16#fff#));

  -- SVGA controler (GRLIB)
  -- Ethernet MAC (GRLIB)
  constant eth0_pconfig : apb_config_type := (
  0 => ahb_device_reg (VENDOR_GAISLER, GAISLER_ETHMAC, 0, 0, 12),
  1 => apb_iobar(16#800#, 16#f00#));

  constant sgmii0_pconfig : apb_config_type := (
  0 => ahb_device_reg (VENDOR_GAISLER, GAISLER_SGMII, 0, 1, 11),
  1 => apb_iobar(16#010#, 16#ff0#));

  -- CPU DVFS controller
  -- Accelerators' power controllers are mapped to the upper half of their I/O
  -- address space. In the future, each DVFS controller should be assigned to an independent
  -- region of the address space, thus allowing discovery from the device tree.
  constant cpu_dvfs_paddr : tile_attribute_array := (
    others => 0);
  constant cpu_dvfs_pmask : integer := 16#fff#;
  constant cpu_dvfs_pconfig : apb_config_vector_type(0 to 3) := (
    others => pconfig_none);

  -- L2
  -- Accelerator's caches cannot be flushed/reset from I/O-bus
  constant l2_cache_pconfig : apb_l2_pconfig_vector := (
    0 => (
      0 => ahb_device_reg (VENDOR_SLD, SLD_L2_CACHE, 0, 0, CFG_SLD_L2_CACHE_IRQ),
      1 => apb_iobar(16#0D9#, 16#fff#)),
    others => pconfig_none);

  -- LLC
  constant llc_cache_pconfig : apb_llc_pconfig_vector := (
    0 => (
      0 => ahb_device_reg (VENDOR_SLD, SLD_LLC_CACHE, 0, 0, CFG_SLD_LLC_CACHE_IRQ),
      1 => apb_iobar(16#0E0#, 16#fff#)),
    others => pconfig_none);

  -- Accelerators
  constant accelerators_num : integer := 0;

  -- I/O bus slaves index / memory map
  constant fixed_apbo_pconfig : apb_slv_config_vector := (
    1 => uart_pconfig,
    2 => irqmp_pconfig,
    3 => gptimer_pconfig,
    4 => esplink_pconfig,
    9 => l2_cache_pconfig(0),
    16 => llc_cache_pconfig(0),
    14 => eth0_pconfig,
    15 => sgmii0_pconfig,
    others => pconfig_none);

  ------ Cross reference arrays
  -- Get CPU ID from tile ID
  constant tile_cpu_id : tile_attribute_array := (
    0 => -1,
    1 => 0,
    2 => -1,
    3 => -1,
    others => -1);

  -- Get tile ID from CPU ID
  constant cpu_tile_id : cpu_attribute_array := (
    0 => 1,
    others => 0);

  -- Get DVFS controller pindex from tile ID
  constant cpu_dvfs_pindex : tile_attribute_array := (
    others => -1);

  -- Get L2 cache ID from tile ID
  constant tile_cache_id : tile_attribute_array := (
    1 => 0,
    others => -1);

  -- Get tile ID from L2 cache ID
  constant cache_tile_id : cache_attribute_array := (
    0 => 1,
    others => 0);

  -- Get L2 pindex from tile ID
  constant l2_cache_pindex : tile_attribute_array := (
    1 => 9,
    others => 0);

  -- Flag tiles that have a private cache
  constant tile_has_l2 : tile_attribute_array := (
    0 => 0,
    1 => 1,
    2 => 0,
    3 => 0,
    others => 0);

  -- Get LLC ID from tile ID
  constant tile_llc_id : tile_attribute_array := (
    0 => 0,
    others => -1);

  -- Get tile ID from LLC-split ID
  constant llc_tile_id : mem_attribute_array := (
    0 => 0,
    others => 0);

  -- Get LLC pindex from tile ID
  constant llc_cache_pindex : tile_attribute_array := (
    0 => 16,
    others => 0);

  -- Get tile ID from memory ID
  constant mem_tile_id : mem_attribute_array := (
    0 => 0,
    others => 0);

  -- Get memory tile ID from tile ID
  constant tile_mem_id : tile_attribute_array := (
    0 => 0,
    others => -1);

  -- Get accelerator ID from tile ID
  constant tile_acc_id : tile_attribute_array := (
    others => 0);

  -- Get miscellaneous tile ID
  constant io_tile_id : integer := 3;

  -- DMA ID corresponds to accelerator ID for accelerators and nacc for Ethernet
  -- Ethernet must be coherent to avoid flushing private caches every time the
  -- DMA buffer is accessed, but the IP from GRLIB is not coherent. We leverage
  -- LLC-coherent DMA w/ recalls to have Etherent work transparently.
  -- Get DMA ID from tile ID
  constant tile_dma_id : tile_attribute_array := (
    io_tile_id => 0,
    others => -1);

  -- Get tile ID from DMA ID (used for LLC-coherent DMA)
  constant dma_tile_id : dma_attribute_array := (
    0 => io_tile_id,
    others => 0);

  -- Get type of tile from tile ID
  constant tile_type : tile_attribute_array := (
    0 => 4,
    1 => 1,
    2 => 0,
    3 => 3,
    others => 0);

  -- Get accelerator's implementation (hlscfg or generic design point) from tile ID
  constant tile_design_point : tile_hlscfg_array := (
    others => 0);

  -- Get accelerator device ID (device tree) from tile ID
  constant tile_device : tile_device_array := (
    others => 0);

  -- Get I/O-bus index line for accelerators from tile ID
  constant tile_apb_idx : tile_idx_array := (
    others => 0);

  -- Get I/O-bus address for accelerators from tile ID
  constant tile_apb_paddr : tile_addr_array := (
    others => 0);

  -- Get I/O-bus address mask for accelerators from tile ID
  constant tile_apb_pmask : tile_addr_array := (
    others => 0);

  -- Get IRQ line for accelerators from tile ID
  constant tile_apb_irq : tile_irq_array := (
    others => 0);

  -- Get DMA memory allocation from tile ID (this parameter must be the same for every accelerator)
  constant tile_scatter_gather : tile_flag_array := (
    others => 0);

  -- Get number of clock regions (1 if has_dvfs is false)
  constant domains_num : integer := 1;

  -- Flag tiles that belong to a DVFS domain
  constant tile_has_dvfs : tile_attribute_array := (
    others => 0);

  -- Flag tiles that are master of a DVFS domain (have a local PLL)
  constant tile_has_pll : tile_attribute_array := (
    others => 0);

  -- Get clock domain from tile ID
  constant tile_domain : tile_attribute_array := (
    others => 0);

  -- Get tile ID of the DVFS domain masters for each clock region (these tiles control the corresponding domain)
  -- Get tile ID of the DVFS domain master from the tile clock region
  constant tile_domain_master : tile_attribute_array := (
    0 => 0,
    1 => 0,
    2 => 0,
    3 => 0,
    others => 0);

  -- Get tile ID of the DVFS domain master from the clock region ID
  constant domain_master_tile : domain_type_array := (
    others => 0);

  -- Flag domain master tiles w/ additional clock buffer (these are a limited resource on the FPGA)
  constant extra_clk_buf : tile_attribute_array := (
    0 => 0,
    1 => 0,
    2 => 0,
    3 => 0,
    others => 0);

  ---- Get tile ID from I/O-bus index (index 4 is the local DVFS controller to each CPU tile)
  constant apb_tile_id : apb_attribute_array := (
    0 => io_tile_id,
    1 => io_tile_id,
    2 => io_tile_id,
    3 => io_tile_id,
    14 => io_tile_id,
    15 => io_tile_id,
    16 => 0,
    9 => 1,
    others => 0);

  -- Tiles YX coordinates
  constant tile_x : yx_vec(0 to 3) := (
    0 => "000",
    1 => "001",
    2 => "000",
    3 => "001"  );
  constant tile_y : yx_vec(0 to 3) := (
    0 => "000",
    1 => "000",
    2 => "001",
    3 => "001"  );

  -- CPU YX coordinates
  constant cpu_y : yx_vec(0 to 3) := (
   0 => tile_y(cpu_tile_id(0)),
   1 => tile_y(cpu_tile_id(1)),
   2 => tile_y(cpu_tile_id(2)),
   3 => tile_y(cpu_tile_id(3))  );
  constant cpu_x : yx_vec(0 to 3) := (
   0 => tile_x(cpu_tile_id(0)),
   1 => tile_x(cpu_tile_id(1)),
   2 => tile_x(cpu_tile_id(2)),
   3 => tile_x(cpu_tile_id(3))  );

  -- L2 YX coordinates
  constant cache_y : yx_vec(0 to 15) := (
   0 => tile_y(cache_tile_id(0)),
   1 => tile_y(cache_tile_id(1)),
   2 => tile_y(cache_tile_id(2)),
   3 => tile_y(cache_tile_id(3)),
   4 => tile_y(cache_tile_id(4)),
   5 => tile_y(cache_tile_id(5)),
   6 => tile_y(cache_tile_id(6)),
   7 => tile_y(cache_tile_id(7)),
   8 => tile_y(cache_tile_id(8)),
   9 => tile_y(cache_tile_id(9)),
   10 => tile_y(cache_tile_id(10)),
   11 => tile_y(cache_tile_id(11)),
   12 => tile_y(cache_tile_id(12)),
   13 => tile_y(cache_tile_id(13)),
   14 => tile_y(cache_tile_id(14)),
   15 => tile_y(cache_tile_id(15))  );
  constant cache_x : yx_vec(0 to 15) := (
   0 => tile_x(cache_tile_id(0)),
   1 => tile_x(cache_tile_id(1)),
   2 => tile_x(cache_tile_id(2)),
   3 => tile_x(cache_tile_id(3)),
   4 => tile_x(cache_tile_id(4)),
   5 => tile_x(cache_tile_id(5)),
   6 => tile_x(cache_tile_id(6)),
   7 => tile_x(cache_tile_id(7)),
   8 => tile_x(cache_tile_id(8)),
   9 => tile_x(cache_tile_id(9)),
   10 => tile_x(cache_tile_id(10)),
   11 => tile_x(cache_tile_id(11)),
   12 => tile_x(cache_tile_id(12)),
   13 => tile_x(cache_tile_id(13)),
   14 => tile_x(cache_tile_id(14)),
   15 => tile_x(cache_tile_id(15))  );

  -- DMA initiators YX coordinates
  constant dma_y : yx_vec(0 to 15) := (
   0 => tile_y(dma_tile_id(0)),
   1 => tile_y(dma_tile_id(1)),
   2 => tile_y(dma_tile_id(2)),
   3 => tile_y(dma_tile_id(3)),
   4 => tile_y(dma_tile_id(4)),
   5 => tile_y(dma_tile_id(5)),
   6 => tile_y(dma_tile_id(6)),
   7 => tile_y(dma_tile_id(7)),
   8 => tile_y(dma_tile_id(8)),
   9 => tile_y(dma_tile_id(9)),
   10 => tile_y(dma_tile_id(10)),
   11 => tile_y(dma_tile_id(11)),
   12 => tile_y(dma_tile_id(12)),
   13 => tile_y(dma_tile_id(13)),
   14 => tile_y(dma_tile_id(14)),
   15 => tile_y(dma_tile_id(15))  );
  constant dma_x : yx_vec(0 to 15) := (
   0 => tile_x(dma_tile_id(0)),
   1 => tile_x(dma_tile_id(1)),
   2 => tile_x(dma_tile_id(2)),
   3 => tile_x(dma_tile_id(3)),
   4 => tile_x(dma_tile_id(4)),
   5 => tile_x(dma_tile_id(5)),
   6 => tile_x(dma_tile_id(6)),
   7 => tile_x(dma_tile_id(7)),
   8 => tile_x(dma_tile_id(8)),
   9 => tile_x(dma_tile_id(9)),
   10 => tile_x(dma_tile_id(10)),
   11 => tile_x(dma_tile_id(11)),
   12 => tile_x(dma_tile_id(12)),
   13 => tile_x(dma_tile_id(13)),
   14 => tile_x(dma_tile_id(14)),
   15 => tile_x(dma_tile_id(15))  );

  -- LLC YX coordinates and memory tiles routing info
  constant tile_mem_list : tile_mem_info_vector(0 to MEM_MAX_NUM - 1) := (
    0 => (
      x => tile_x(mem_tile_id(0)),
      y => tile_y(mem_tile_id(0)),
      haddr => ddr_haddr(0),
      hmask => ddr_hmask(0)
    ),
    others => tile_mem_info_none);

  -- Add the frame buffer entry for accelerators' DMA.
  -- NB: accelerators can only access the frame buffer if.
  -- non-coherent DMA is selected from software.
  constant tile_acc_mem_list : tile_mem_info_vector(0 to MEM_MAX_NUM) := (
    0 => (
      x => tile_x(mem_tile_id(0)),
      y => tile_y(mem_tile_id(0)),
      haddr => ddr_haddr(0),
      hmask => ddr_hmask(0)
    ),
    others => tile_mem_info_none);

  -- I/O-bus devices routing info
  constant apb_slv_y : yx_vec(0 to NAPBSLV - 1) := (
    0 => tile_y(apb_tile_id(0)),
    1 => tile_y(apb_tile_id(1)),
    2 => tile_y(apb_tile_id(2)),
    3 => tile_y(apb_tile_id(3)),
    4 => tile_y(apb_tile_id(4)),
    5 => tile_y(apb_tile_id(5)),
    6 => tile_y(apb_tile_id(6)),
    7 => tile_y(apb_tile_id(7)),
    8 => tile_y(apb_tile_id(8)),
    9 => tile_y(apb_tile_id(9)),
    10 => tile_y(apb_tile_id(10)),
    11 => tile_y(apb_tile_id(11)),
    12 => tile_y(apb_tile_id(12)),
    13 => tile_y(apb_tile_id(13)),
    14 => tile_y(apb_tile_id(14)),
    15 => tile_y(apb_tile_id(15)),
    16 => tile_y(apb_tile_id(16)),
    17 => tile_y(apb_tile_id(17)),
    18 => tile_y(apb_tile_id(18)),
    19 => tile_y(apb_tile_id(19)),
    20 => tile_y(apb_tile_id(20)),
    21 => tile_y(apb_tile_id(21)),
    22 => tile_y(apb_tile_id(22)),
    23 => tile_y(apb_tile_id(23)),
    24 => tile_y(apb_tile_id(24)),
    25 => tile_y(apb_tile_id(25)),
    26 => tile_y(apb_tile_id(26)),
    27 => tile_y(apb_tile_id(27)),
    28 => tile_y(apb_tile_id(28)),
    29 => tile_y(apb_tile_id(29)),
    30 => tile_y(apb_tile_id(30)),
    31 => tile_y(apb_tile_id(31))  );
  constant apb_slv_x : yx_vec(0 to NAPBSLV - 1) := (
    0 => tile_x(apb_tile_id(0)),
    1 => tile_x(apb_tile_id(1)),
    2 => tile_x(apb_tile_id(2)),
    3 => tile_x(apb_tile_id(3)),
    4 => tile_x(apb_tile_id(4)),
    5 => tile_x(apb_tile_id(5)),
    6 => tile_x(apb_tile_id(6)),
    7 => tile_x(apb_tile_id(7)),
    8 => tile_x(apb_tile_id(8)),
    9 => tile_x(apb_tile_id(9)),
    10 => tile_x(apb_tile_id(10)),
    11 => tile_x(apb_tile_id(11)),
    12 => tile_x(apb_tile_id(12)),
    13 => tile_x(apb_tile_id(13)),
    14 => tile_x(apb_tile_id(14)),
    15 => tile_x(apb_tile_id(15)),
    16 => tile_x(apb_tile_id(16)),
    17 => tile_x(apb_tile_id(17)),
    18 => tile_x(apb_tile_id(18)),
    19 => tile_x(apb_tile_id(19)),
    20 => tile_x(apb_tile_id(20)),
    21 => tile_x(apb_tile_id(21)),
    22 => tile_x(apb_tile_id(22)),
    23 => tile_x(apb_tile_id(23)),
    24 => tile_x(apb_tile_id(24)),
    25 => tile_x(apb_tile_id(25)),
    26 => tile_x(apb_tile_id(26)),
    27 => tile_x(apb_tile_id(27)),
    28 => tile_x(apb_tile_id(28)),
    29 => tile_x(apb_tile_id(29)),
    30 => tile_x(apb_tile_id(30)),
    31 => tile_x(apb_tile_id(31))  );

  -- Flag I/O-bus slaves that are remote
  -- Note that some components can be remote to a tile even if they are
  -- located in that tile. This is because local masters still have to go
  -- through ESP proxies to address such devices (e.g. L2 cache and DVFS
  -- controller in CPU tiles). This choice allows any master in the SoC to
  -- access these slaves. For instance, when configuring DVFS, a single CPU
  -- must be able to access all DVFS controllers from other CPUS; another
  -- example is the synchronized flush of all private caches, which is
  -- initiated by a single CPU
  constant remote_apb_slv_mask : tile_apb_enable_array := (
    1 => (
      1 => to_std_logic(CFG_UART1_ENABLE),
      2 => to_std_logic(CFG_IRQ3_ENABLE),
      3 => to_std_logic(CFG_GPT_ENABLE),
      13 => to_std_logic(CFG_SVGA_ENABLE),
      14 => to_std_logic(CFG_GRETH),
      15 => to_std_logic(CFG_GRETH),
      9 => '1',
      16 => '1',
      others => '0'),
    3 => (
      9 => '1',
      16 => '1',
      others => '0'),
    others => (others => '0'));

  -- Flag I/O-bus slaves that are local to each tile
  constant local_apb_mask : tile_apb_enable_array := (
    0 => (
      16 => '1',
      others => '0'),
    1 => (
      9 => '1',
      others => '0'),
    3 => (
      1  => '1',
      2  => '1',
      3  => '1',
      4  => '1',
      13 => to_std_logic(CFG_SVGA_ENABLE),
      14 => to_std_logic(CFG_GRETH),
      15 => to_std_logic(CFG_SGMII * CFG_GRETH),
      others => '0'),
    others => (others => '0'));

  -- Flag bus slaves that are local to each tile (either device or proxy)
  constant local_ahb_mask : tile_ahb_enable_array := (
    0 => (
      4 => '1',
      others => '0'),
    1 => (
      1  => '1',
      4 => to_std_logic(CFG_L2_ENABLE),
      others => '0'),
    3 => (
      0  => '1',
      1  => '1',
      12  => to_std_logic(CFG_SVGA_ENABLE),
      others => '0'),
    others => (others => '0'));

  -- Flag bus slaves that are remote to each tile (request selects slv proxy)
  constant remote_ahb_mask : tile_ahb_enable_array := (
    1 => (
      0  => '1',
      4 => to_std_logic(CFG_L2_DISABLE),
      12  => to_std_logic(CFG_SVGA_ENABLE),
      others => '0'),
    3 => (
      4 => '1',
      others => '0'),
    others => (others => '0'));

end socmap;
