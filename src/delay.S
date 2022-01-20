.global _f_delay

#define DELAY_REG_L r26
#define DELAY_REG_H r27

; F_CPU / (4 * 1000)
#define DELAY_TIME 1000

; waits number of ms specifed by r16
_f_delay:
    ldi DELAY_REG_L, lo8(DELAY_TIME)
    ldi DELAY_REG_H, hi8(DELAY_TIME)

    _f_delay_loop:
        sbiw DELAY_REG_L, 1
        brne _f_delay_loop

    dec r16
    brne _f_delay

    ret