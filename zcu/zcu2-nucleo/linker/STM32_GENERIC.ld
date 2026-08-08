/* Placeholder memory map — replace with the exact FLASH/RAM origin+length
 * from your confirmed STM32 Discovery part number's datasheet before
 * flashing real hardware. Values below match a generic STM32F4-class part
 * (1MB flash @ 0x08000000, 128KB SRAM @ 0x20000000) so the skeleton links. */

MEMORY
{
  FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 1024K
  RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 128K
}

_estack = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
  } > FLASH

  .text :
  {
    . = ALIGN(4);
    *(.text)
    *(.text*)
    *(.rodata)
    *(.rodata*)
    . = ALIGN(4);
    _etext = .;
  } > FLASH

  .data :
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data)
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } > RAM AT > FLASH
  _sidata = LOADADDR(.data);

  .bss :
  {
    . = ALIGN(4);
    _sbss = .;
    *(.bss)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > RAM

  ._user_heap_stack :
  {
    . = ALIGN(8);
    . = . + 0x400; /* min heap */
    . = . + 0x400; /* min stack */
    . = ALIGN(8);
  } > RAM
}
