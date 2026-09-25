/******************************************************************************
 * @file        stm32f407_regs.h
 * @brief       stm32f407 register details.
 *
 * @author      Chittaranjan Baral
 * @date        19-Sep-2026
 * @version     1.0.0
 *
 * @copyright   Copyright (c) 2026 CRB. All rights reserved.
 *
 * @details
 *
 *
 *
 * @history
 * ----------------------------------------------------------------------------
 * Version     Date            Author                  Description
 * ----------------------------------------------------------------------------
 * 1.0.0       19-Sep-2026    Chittaranjan Baral       Initial version
 * ----------------------------------------------------------------------------
 ******************************************************************************/


#ifndef STM32F407_REGS_H
#define STM32F407_REGS_H

/* ============================================================
 * Includes
 * ============================================================ */

#include "stdint.h"

/* ============================================================
 * Peripheral BASE Address
 * ============================================================ */

#define RCC_BASE_ADDRESS            (0x40023800UL)
#define GPIOD_BASE_ADDRESS          (0x40020C00UL)

/* ============================================================
 * Register OFFSETs
 * ============================================================ */

#define RCC_AHB1ENR_OFFSET          (0x30UL)                    /*RCC_AHB1 Peripheral Clock Register Offset Value*/
#define GPIOD_MODER_OFFSET          (0x00UL)                    /*GPIO Port_D Mode Register offset Value*/
#define GPIOD_ODR_OFFSET            (0x14UL)                    /*GPIO port output data register offset value*/

/* ============================================================
 * Register RESET Value
 * ============================================================ */

#define RCC_AHB1ENR_RESET_VAL       (0x00100000UL)              /*RCC_AHB1 Peripheral Clock Register Reset Value*/
#define GPIOD_ODR_RESET_VAL         (0x00000000UL)              /*GPIOD_ODR Output Data Register Reset Value*/

/* ============================================================
 * Register Bit Positions
 * ============================================================ */

#define RCC_AHB1ENR_GPIOAEN_BIT     (0UL)                       /*IO port A clock enable*/
#define RCC_AHB1ENR_GPIODEN_BIT     (3UL)                       /*IO port D clock enable*/

/* ============================================================
 * Register Definitions
 * ============================================================ */

#define RCC_AHB1ENR_REG           (*(volatile uint32_t *) \
                                  (RCC_BASE_ADDRESS + RCC_AHB1ENR_OFFSET))
#define GPIOD_MODER_REG           (*(volatile uint32_t *) \
                                  (GPIOD_BASE_ADDRESS + GPIOD_MODER_OFFSET))
#define GPIOD_ODR_REG             (*(volatile uint32_t *) \
                                  (GPIOD_BASE_ADDRESS + GPIOD_ODR_OFFSET))

/* ============================================================
 * Type Definitions
 * ============================================================ */


/* ============================================================
 * Enumerations
 * ============================================================ */

typedef enum {
    GPIO_MODER_INPUT     = 0x0,  // 00
	GPIO_MODER_OUTPUT    = 0x1,  // 01
	GPIO_MODER_ALTERNATE = 0x2,  // 10
	GPIO_MODER_ANALOG    = 0x3,  // 11
} GPIO_ModeR_t;                                               /*Enum for GPIO I/O Direction mode*/

/* ============================================================
 * Structure and Unions
 * ============================================================ */


/* ============================================================
 * Function Prototypes
 * ============================================================ */


#endif /* STM32F407_REGS_H */
