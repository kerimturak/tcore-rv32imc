/*======================================================================*/
/* Proxy kernel linker script                                           */
/*======================================================================*/
/* This is the linker script used when building the proxy kernel. */

/*----------------------------------------------------------------------*/
/* Setup                                                                */
/*----------------------------------------------------------------------*/

/* The OUTPUT_ARCH command specifies the machine architecture where the
   argument is one of the names used in the BFD library. More
   specifically one of the entires in bfd/cpu-mips.c */

OUTPUT_ARCH( "riscv" )
GROUP("libgcc.a")
ENTRY(_start)

/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/
MEMORY
{
  ram  : ORIGIN = 0x40000000, LENGTH = 0x10000
}

PHDRS
{
  ram PT_LOAD;
  ram_vol PT_NULL;
}

SECTIONS
{
__stack_size = DEFINED(__stack_size) ? __stack_size : 4K;

  .text.init           :
  {
  . = 0x4;
    KEEP (*(SORT_NONE(.text.init)))
  } >ram AT>ram :ram
. = ALIGN(1000);
.tohost           :
  {
  . = 0x4;
    KEEP (*(SORT_NONE(.tohost)))
  } >ram AT>ram :ram
. = ALIGN(1000);
    .text           :
  {
    *(.text.unlikely .text.unlikely.*)
    *(.text.startup .text.startup.*)
    *(.text .text.*)
    *(.gnu.linkonce.t.*)
  }  >ram AT>ram :ram

/* data segment */
    .lalign         :
  {
    . = ALIGN(4);
    PROVIDE( _data_lma = . );
  } >ram AT>ram :ram

  .dalign         :
  {
    . = ALIGN(4);
    PROVIDE( _data = . );
  } >ram AT>ram :ram

  .data          :
  {
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    . = ALIGN(8);
    PROVIDE( __global_pointer$ = . + 0x800 );
    *(.sdata .sdata.*)
    *(.gnu.linkonce.s.*)
    . = ALIGN(8);
    *(.srodata.cst16)
    *(.srodata.cst8)
    *(.srodata.cst4)
    *(.srodata.cst2)
    *(.srodata .srodata.*)
  } >ram AT>ram :ram

. = ALIGN(4);
  PROVIDE( _edata = . );
  PROVIDE( edata = . );

  PROVIDE( _fbss = . );
  PROVIDE( __bss_start = . );
  .bss            :
  {
    *(.sbss*)
    *(.gnu.linkonce.sb.*)
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(4);
  } >ram AT>ram :ram_vol

  .tdata :
  {
    . = 0x30;
    _tdata_begin = .;
    *(.tdata.begin)
    *(.tdata)
    _tdata_end = .;
  }

  .tbss :
  {
    
    *(.tbss)
    _tbss_end = .;
  }
  
  . = ALIGN(8);
  PROVIDE( _end = . );
  PROVIDE( end = . );

  .stack ORIGIN(ram) + LENGTH(ram) - __stack_size :
  {
    PROVIDE( _heap_end = . );
    . = __stack_size;
    PROVIDE( _sp = . );
  } >ram AT>ram :ram_vol
}