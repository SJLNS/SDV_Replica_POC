/* STM32F407VGT6 (STM32F407G-DISC1 Discovery board) - confirmed via datasheet:
 * 1MB flash @ 0x08000000, 128KB SRAM1+SRAM2 (contiguous) @ 0x20000000.
 * A further 64KB CCM RAM exists at 0x10000000 but is a separate, non-DMA-
 * accessible region - not included here; add as its own MEMORY entry later
 * if a driver specifically needs core-coupled RAM for performance. */

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
