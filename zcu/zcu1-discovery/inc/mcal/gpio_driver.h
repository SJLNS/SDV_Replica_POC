/******************************************************************************
 * @file        gpio_driver.h
 * @brief       GPIO Driver related contents.
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
 * 1.0.0       20-Sep-2026    Chittaranjan Baral       Initial version
 * ----------------------------------------------------------------------------
 ******************************************************************************/

#ifndef GPIO_DRIVER_H
#define GPIO_DRIVER_H

/* ============================================================
 * Includes
 * ============================================================ */


/* ============================================================
 * Function Prototypes
 * ============================================================ */

void GPIOD_MODER_PD12_SetOutput(void);                                 /* Set the mode of 12th PIN as Output for PORT GPIOD */
void GPIOD_MODER_PD13_SetOutput(void);                                 /* Set the mode of 13th PIN as Output for PORT GPIOD */
void GPIOD_MODER_PD14_SetOutput(void);                                 /* Set the mode of 14th PIN as Output for PORT GPIOD */
void GPIOD_MODER_PD15_SetOutput(void);                                 /* Set the mode of 15th PIN as Output for PORT GPIOD */

void GPIOD_ODR_PD12_SetHigh(void);                                     /* Set GPIO Port D Pin 12 output data bit HIGH */
void GPIOD_ODR_PD13_SetHigh(void);                                     /* Set GPIO Port D Pin 13 output data bit HIGH */
void GPIOD_ODR_PD14_SetHigh(void);                                     /* Set GPIO Port D Pin 14 output data bit HIGH */
void GPIOD_ODR_PD15_SetHigh(void);                                     /* Set GPIO Port D Pin 15 output data bit HIGH */

void GPIOD_ODR_PD12_SetLow(void);                                      /* Set GPIO Port D Pin 12 output data bit LOW */
void GPIOD_ODR_PD13_SetLow(void);                                      /* Set GPIO Port D Pin 13 output data bit LOW */
void GPIOD_ODR_PD14_SetLow(void);                                      /* Set GPIO Port D Pin 14 output data bit LOW */
void GPIOD_ODR_PD15_SetLow(void);                                      /* Set GPIO Port D Pin 15 output data bit LOW */


#endif /* GPIO_DRIVER_H */
