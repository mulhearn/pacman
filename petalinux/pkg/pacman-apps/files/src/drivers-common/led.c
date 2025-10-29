#include <stdlib.h>
#include <stdio.h>

#include "hw_access.h"
#include "led.h"
#include "global.h"

// -----------------------------------------------------------
// LED control
// -----------------------------------------------------------

#define LED_TRENZ_RED 7
#define LED_1         12
#define LED_2         13

void init_led() {
  // LEDs use the AXI-Lite register and GPIO interfaces from the platform layer:
  axil_platform_init();
  gpio_platform_init();
  // configure the LEDs controlled by MIO:
  gpio_platform_configure_pin(LED_TRENZ_RED, GPIO_DIR_OUTPUT, 0);
  gpio_platform_configure_pin(LED_1, GPIO_DIR_OUTPUT, 0);
  gpio_platform_configure_pin(LED_2, GPIO_DIR_OUTPUT, 0);
}

void blink_red_led() {
  printf("Blinking RED LED on Trenz Module, via MIO...\r\n");
  for (int i = 0; i < 20; i++) {
    (void)gpio_write_pin(LED_TRENZ_RED, 1);
    usleep(50000);
    (void)gpio_write_pin(LED_TRENZ_RED, 0);
    usleep(50000);
  }
}

void blink_pacman_leds() {
  printf("Blinking PACMAN LED-0, via MIO...\r\n");
  for (int i = 0; i < 20; i++) {
    (void)gpio_write_pin(LED_1, 1);
    usleep(50000);
    (void)gpio_write_pin(LED_1, 0);
    usleep(50000);
  }

  printf("Blinking PACMAN LED-1, via MIO...\r\n");
  for (int i = 0; i < 20; i++) {
    (void)gpio_write_pin(LED_2, 1);
    usleep(50000);
    (void)gpio_write_pin(LED_2, 0);
    usleep(50000);
  }

  printf("Blinking PACMAN LED-2, via AXIL register...\r\n");
  for (int i = 0; i < 20; i++) {
    axil_write_register(SCOPE_GLOBAL + C_ADDR_GLOBAL_LEDS, 0x1);
    usleep(50000);
    axil_write_register(SCOPE_GLOBAL + C_ADDR_GLOBAL_LEDS, 0x0);
    usleep(50000);
  }

  printf("Blinking PACMAN LED-3, via AXIL register...\r\n");
  for (int i = 0; i < 20; i++) {
    axil_write_register(SCOPE_GLOBAL + C_ADDR_GLOBAL_LEDS, 0x2);
    usleep(50000);
    axil_write_register(SCOPE_GLOBAL + C_ADDR_GLOBAL_LEDS, 0x0);
    usleep(50000);
  }
}

