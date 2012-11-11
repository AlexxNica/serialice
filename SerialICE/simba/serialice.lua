-- SerialICE
--
-- Copyright (c) 2009 coresystems GmbH
-- Copyright (c) 2012 Kyösti Mälkki <kyosti.malkki@gmail.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--

io.write("SerialICE: Starting LUA script\n")


-- Set to "false" to show undecoded access for the specified class
hide_rom_access = true
hide_pci_io_cfg = true
hide_pci_mm_cfg = true
hide_nvram_io = true
hide_i8042_io = false
hide_i8237_io = true
hide_i8254_io = true
hide_i8259_io = true
hide_superio_cfg = true
hide_smbus_io = true
hide_mainboard_io = true

-- Set to "true" to log every memory and IO access
log_everything = false


-- Use lua table for NVram
-- RTC registers 0x0-0xd go to HW
cache_nvram = false

-- SMSC 0x07, Winbond 0x06 ?
DEFAULT_SUPERIO_LDN_REGISTER = 0x07

rom_size = 4 * 1024 * 1024
rom_base = 0x100000000 - rom_size


-- --------------------------------------------------------------------
-- This initialization is executed right after target communication
-- has been established

dofile("interface.lua")
dofile("output.lua")
dofile("hooks.lua")
dofile("core_io.lua")
dofile("memory.lua")
dofile("cpu.lua")
dofile("pci_cfg.lua")
dofile("pc80.lua")
dofile("superio.lua")
dofile("mmio.lua")

function do_minimal_setup()
	enable_hook(io_hooks, filter_io_fallback)
	enable_hook(mem_hooks, filter_mem_fallback)
	enable_hook(cpumsr_hooks, filter_cpumsr_fallback)
	enable_hook(cpuid_hooks, filter_cpuid_fallback)
	enable_hook(mem_hooks, filter_rom_low)
	enable_hook(mem_hooks, filter_rom_high)
end

function do_default_setup()
	enable_ram()
	enable_hook(mem_hooks, filter_lapic)
	enable_hook(mem_hooks, filter_ioapic)
	enable_hook(io_hooks, filter_pci_io_cfg)
	enable_hook_pc80()
	enable_hook_superio(0x2e, DEFAULT_SUPERIO_LDN_REGISTER)
	enable_hook_superio(0x4e, DEFAULT_SUPERIO_LDN_REGISTER)
	enable_hook(io_hooks, filter_com1)
	if superio_initialization then
		superio_initialization()
	end
end

mainboard_file = string.format("%s.lua", string.lower(string.gsub(SerialICE_mainboard, "[ -]", "_")))
local mainboard_lua, ferr = loadfile(mainboard_file)
local mainboard_script = io.open(mainboard_file)
if mainboard_script then
	io.close(mainboard_script)
	assert(mainboard_lua, ferr)
	mainboard_lua()
	printks(froot, "Mainboard script %s initialized.\n", mainboard_file)
	do_minimal_setup()
	do_mainboard_setup()
else
	printks(froot, "Mainboard script %s not found.\n", mainboard_file)
	do_minimal_setup()
	do_default_setup()
end

printks(froot, "LUA script initialized.\n")

return true
