MEMORY
{
   ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00001800
}

ENTRY(_start)

SECTIONS {
  .text 0x00000000 : {
        crt0.o (.text)
        *(.text)
        *(.sdata)
        *(.srodata)
        *(.rodata)
        *(.rodata.str1.4)
        *(.data)
        *(.sbss)
  } >ram
}
