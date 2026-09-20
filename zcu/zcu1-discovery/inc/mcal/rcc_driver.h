/******************************************************************************
 * @file        rcc_driver.h
 * @brief       RCC Driver related contents.
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

#ifndef RCC_DRIVER_H
#define RCC_DRIVER_H

/* ============================================================
 * Includes
 * ============================================================ */


/* ============================================================
 * Function Prototypes
 * ============================================================ */

void RCC_GPIOA_ClockEnable(void);                               /*API to enable IO port A clock*/
void RCC_GPIOD_ClockEnable(void);                               /*API to enable IO port D clock*/


#endif /* RCC_DRIVER_H */
