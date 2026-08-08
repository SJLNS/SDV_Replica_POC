    .syntax unified
    .cpu cortex-m4
    .thumb

    .global Reset_Handler
    .global _estack

    .section .isr_vector,"a",%progbits
    .type g_pfnVectors, %object
g_pfnVectors:
    .word _estack
    .word Reset_Handler
    .word Default_Handler   /* NMI */
    .word Default_Handler   /* HardFault */
    .word Default_Handler   /* MemManage */
    .word Default_Handler   /* BusFault */
    .word Default_Handler   /* UsageFault */
    .word 0
    .word 0
    .word 0
    .word 0
    .word Default_Handler   /* SVC */
    .word Default_Handler   /* DebugMon */
    .word 0
    .word Default_Handler   /* PendSV */
    .word Default_Handler   /* SysTick */
    /* peripheral IRQs go here once the exact part number is confirmed */

    .section .text.Reset_Handler
    .weak Reset_Handler
    .type Reset_Handler, %function
Reset_Handler:
    ldr r0, =_sidata
    ldr r1, =_sdata
    ldr r2, =_edata
copy_data:
    cmp r1, r2
    bge copy_data_done
    ldr r3, [r0], #4
    str r3, [r1], #4
    b copy_data
copy_data_done:

    ldr r1, =_sbss
    ldr r2, =_ebss
    movs r3, #0
zero_bss:
    cmp r1, r2
    bge zero_bss_done
    str r3, [r1], #4
    adds r1, r1, #4
    b zero_bss
zero_bss_done:

    bl main
    b .

    .section .text.Default_Handler,"ax",%progbits
Default_Handler:
    b .

    .size Default_Handler, .-Default_Handler
