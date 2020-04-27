-- Copyright (c) 2011-2019 Columbia University, System Level Design Group
-- SPDX-License-Identifier: Apache-2.0

------------------------------------------------------------------------------
--  This file is a configuration file for the ESP NoC-based architecture
-----------------------------------------------------------------------------
-- Package:     esp_global
-- File:        esp_global.vhd
-- Author:      Paolo Mantovani - SLD @ Columbia University
-- Author:      Christian Pilato - SLD @ Columbia University
-- Description: System address mapping and NoC tiles configuration
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package esp_global is

  ------ Global architecture parameters
  constant ARCH_BITS : integer := 32;
  constant GLOB_MEM_MAX_NUM : integer := 4;
  constant GLOB_CPU_MAX_NUM : integer := 4;
  constant GLOB_MAXIOSLV : integer := 32;
  constant GLOB_TILES_MAX_NUM : integer := 64;
  constant GLOB_WORD_OFFSET_BITS : integer := 2;
  constant GLOB_BYTE_OFFSET_BITS : integer := 2;
  constant GLOB_OFFSET_BITS : integer := GLOB_WORD_OFFSET_BITS + GLOB_BYTE_OFFSET_BITS;
  constant GLOB_ADDR_INCR : integer := 4;
  constant GLOB_PHYS_ADDR_BITS : integer := 32;
  type cpu_arch_type is (leon3, ariane);
  constant GLOB_CPU_ARCH : cpu_arch_type := leon3;
  constant GLOB_CPU_AXI : integer range 0 to 1 := 0;

  constant CFG_CACHE_RTL   : integer := 1;
end esp_global;
