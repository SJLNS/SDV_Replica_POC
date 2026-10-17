/******************************************************************************
 * @file        bsp_button.h
 * @brief       Button related BSP contents.
 *
 * @author      Chittaranjan Baral
 * @date        10-Oct-2026
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
 * 1.0.0       10-Oct-2026    Chittaranjan Baral       Initial version
 * ----------------------------------------------------------------------------
 ******************************************************************************/

#ifndef BSP_BUTTON_H
#define BSP_BUTTON_H

/* ============================================================
 * Includes
 * ============================================================ */
#include "mcal/stm32f407_regs.h"

/* ============================================================
 * Function Prototypes
 * ============================================================ */

uint8_t Button_B1_IsPressed(void);                               /*API to check Button B1(i.e PA0) is pressed or not*/
GPIO_PinState_t Button_B1_Read(void);                            /*API to read PIN state of Button B1(i.e PA0)*/
void Button_B1_Init(void);                                       /*Init API for Button B1*/

#endif /* BSP_BUTTON_H */
