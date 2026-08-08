/*
 * ZCU-1 — STM32 Discovery
 * App-logic skeleton. This compiles standalone (no HAL dependency yet) so
 * the toolchain + linker path is proven before you layer in CubeMX-generated
 * HAL code, GPIO/ADC/PWM drivers (see ../drivers/), and the MQTT+mbedTLS
 * network stack (see ../net/).
 *
 * Bring-up order (see Execution Guide Section 3.1):
 *   1. This skeleton must build + link to an ELF (proves toolchain).
 *   2. Flash it, confirm it runs (add a real GPIO toggle once HAL is in).
 *   3. Layer in drivers/ for your actual wired sensors/actuators.
 *   4. Layer in net/ for MQTT+mbedTLS once ZCU<->HPC wiring is validated.
 */

volatile unsigned long tick_count = 0;

static void delay_cycles(volatile unsigned long n) {
    while (n--) {
        __asm__ volatile("nop");
    }
}

int main(void) {
    for (;;) {
        tick_count++;
        delay_cycles(100000);
        /* TODO: replace with real sensor poll / actuator command loop
         * once drivers/ (GPIO/ADC/PWM HAL) and net/ (MQTT client) exist. */
    }
    return 0;
}
