/******************************************************************************
 * @file        gpio_driver.c
 * @brief       GPIO Driver implementation.
 *
 * @author      Chittaranjan Baral
 * @date        19-Sep-2026
 * @version     1.0.0
 *
 * @copyright   Copyright (c) 2026 CRB. All rights reserved.
 *
 * @details
 * This file contains the implementation of the GPIO Driver.
 *
 * @history
 * ----------------------------------------------------------------------------
 * Version     Date            Author                  Description
 * ----------------------------------------------------------------------------
 * 1.0.0       20-Sep-2026    Chittaranjan Baral       Initial version
 * ----------------------------------------------------------------------------
 ******************************************************************************/

#include "mcal/stm32f407_regs.h"
#include "mcal/gpio_driver.h"


/*============================================================================*/
/*                               LOCAL MACROS                                 */
/*============================================================================*/


/*============================================================================*/
/*                              LOCAL TYPES                                  */
/*============================================================================*/


/*============================================================================*/
/*                         LOCAL FUNCTION PROTOTYPES                          */
/*============================================================================*/


/*============================================================================*/
/*                           LOCAL VARIABLES                                  */
/*============================================================================*/


/*============================================================================*/
/*                        GLOBAL FUNCTION DEFINITIONS                         */
/*============================================================================*/

void GPIOD_MODER_PD12_SetOutput(void)
{
    /* Clear MODER bits [25:24] for PD12 */
    GPIOD_MODER_REG &= ~(0x3UL << (12U * 2U));

    /* Set PD12 to Output mode: MODER[25:24] = 01 */
    GPIOD_MODER_REG |= ((uint32_t)GPIO_MODER_OUTPUT << (12U * 2U));
}

void GPIOD_MODER_PD13_SetOutput(void)
{
    /* Clear MODER bits [27:26] for PD13 */
    GPIOD_MODER_REG &= ~(0x3UL << (13U * 2U));

    /* Set PD13 to Output mode: MODER[27:26] = 01 */
    GPIOD_MODER_REG |= ((uint32_t)GPIO_MODER_OUTPUT << (13U * 2U));
}

void GPIOD_MODER_PD14_SetOutput(void)
{
    /* Clear MODER bits [29:28] for PD14 */
    GPIOD_MODER_REG &= ~(0x3UL << (14U * 2U));

    /* Set PD14 to Output mode: MODER[29:28] = 01 */
    GPIOD_MODER_REG |= ((uint32_t)GPIO_MODER_OUTPUT << (14U * 2U));
}

void GPIOD_MODER_PD15_SetOutput(void)
{
    /* Clear MODER bits [31:30] for PD15 */
    GPIOD_MODER_REG &= ~(0x3UL << (15U * 2U));

    /* Set PD15 to Output mode: MODER[31:30] = 01 */
    GPIOD_MODER_REG |= ((uint32_t)GPIO_MODER_OUTPUT << (15U * 2U));
}


void GPIOD_ODR_PD12_SetHigh(void)
{
	/* Set GPIO Port D Pin 12 output data bit HIGH */
    GPIOD_ODR_REG |= (1UL << 12);
}

void GPIOD_ODR_PD13_SetHigh(void)
{
	/* Set GPIO Port D Pin 13 output data bit HIGH */
    GPIOD_ODR_REG |= (1UL << 13);
}

void GPIOD_ODR_PD14_SetHigh(void)
{
	/* Set GPIO Port D Pin 14 output data bit HIGH */
    GPIOD_ODR_REG |= (1UL << 14);
}

void GPIOD_ODR_PD15_SetHigh(void)
{
	/* Set GPIO Port D Pin 15 output data bit HIGH */
    GPIOD_ODR_REG |= (1UL << 15);
}



void GPIOD_ODR_PD12_SetLow(void)
{
	/* Set GPIO Port D Pin 12 output data bit LOW */
    GPIOD_ODR_REG &= ~(1UL << 12);
}

void GPIOD_ODR_PD13_SetLow(void)
{
	/* Set GPIO Port D Pin 13 output data bit LOW */
    GPIOD_ODR_REG &= ~(1UL << 13);
}

void GPIOD_ODR_PD14_SetLow(void)
{
	/* Set GPIO Port D Pin 14 output data bit LOW */
    GPIOD_ODR_REG &= ~(1UL << 14);
}

void GPIOD_ODR_PD15_SetLow(void)
{
	/* Set GPIO Port D Pin 15 output data bit LOW */
    GPIOD_ODR_REG &= ~(1UL << 15);
}

/*============================================================================*/
/*                         LOCAL FUNCTION DEFINITIONS                         */
/*============================================================================*/


