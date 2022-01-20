#include <avr/io.h>

#define PIN_CMP_IN 0 
#define PIN_SW_HIGH 1
#define PIN_SW_LOW 2
#define PIN_VFB 3

; expected output level, eg 5V
#define VOLTAGE_TARGET 0x0102

; buck-boost threshold voltage
#define VOLTAGE_TRESHOLD 0x0102

#define PHASE_1_CURREN_LIMIT 0x03

;r25 reserved state register
#define STATREG r25

;r24 reserved for AC0 interrupt
#define CMPREG r24

;r23 reserved for AC0 interrupt
#define CMP_TMP_STAT r23

.section .text

.global main
.global AC0_AC_vect


main:
    cli ; diable interrupts for the setup

    rcall _f_setup_vref
    rcall _f_setup_dac
    rcall _f_setup_cmp
    rcall _f_setup_adc

    ; buck mode?
    ldi STATREG, 0x01

    sei ; enable interrupts and go!

loop:

    ;read ADC
    lds r1, ADC0_RESL   
    lds r2, ADC0_RESH 

    ; check if target voltage has been reached
    ldi r16, lo8(VOLTAGE_TARGET)
    ldi r17, hi8(VOLTAGE_TARGET)
    cp r1, r16
    cpc r2, r17

    BRGE _v_greater_target

    ; voltage less than target

    ; check if threshold voltage
    ldi r16, lo8(VOLTAGE_TRESHOLD)
    ldi r17, hi8(VOLTAGE_TRESHOLD)
    cp r1, r16
    cpc r2, r17

    brge _v_greater_theshold

    ; voltage threshold not reached


    _v_greater_theshold:

    ; voltage lower than target but greater than threshold


    ; increase chopper current, set boost mode

    ;voltage greater than or equal expected
    _v_greater_target:
        ;TODO: lower chopper current
    

    rjmp loop



; Analog Comprarator interrupt
AC0_AC_vect:

    ; turn off both transistors
    cbi VPORTA_OUT, PIN_SW_LOW
    cbi VPORTA_OUT, PIN_SW_HIGH

    in CMP_TMP_STAT, CPU_SREG ; copy cpu status register, as not to destroy 

    out CPU_SREG, CMP_TMP_STAT

    ; clear interrupt flag
    ldi CMPREG, 0x01
    sts AC0_STATUS, CMPREG

    reti


_f_setup_adc:
    ;start freerunning
    ldi r16, ADC_FREERUN_bm
    sts ADC0_CTRLA, r16

    ;accumulate 2 samples?
    ldi r16, ADC_SAMPNUM0_bm
    sts ADC0_CTRLB, r16

    ;reduced sample capacitance, internal vref, x2 division
    ldi r16, ADC_SAMPCAP_bm
    sts ADC0_CTRLC, r16

    ;randomize sample delay
    ldi r16, ADC_ASDV_bm
    sts ADC0_CTRLD, r16

    ;enable
    ldi r16, ADC_ENABLE_bm
    sts ADC0_CTRLA, r16

    ;and go!
    ldi r16, 0x01
    sts ADC0_COMMAND, r16

    ret


_f_setup_cmp:
    ;push r16

    ldi r16, AC_MUXNEG0_bm | AC_MUXNEG1_bm ; select DAC as neg. input
    sts AC0_MUXCTRLA, r16

    ; enable, hist 10mV, rising edge interrupt
    ldi r16, AC_ENABLE_bm | AC_HYSMODE0_bm | AC_INTMODE0_bm | AC_INTMODE1_bm
    sts AC0_CTRLA, r16

    ;enable interrupt
    ldi r16, 1
    sts AC0_INTCTRL, r16

    ; wait for compatator to settle down (10ms)
    ldi r16, 0xA
    rcall _f_delay

    ;pop r16

    ret

    
_f_setup_dac:
    ldi r16, PHASE_1_CURREN_LIMIT
    sts DAC0_DATA, r16

    ret

_f_setup_vref:
    ;push r16

    ;1.1V ADC, 1.1V AC                   
    ldi r16, VREF_ADC0REFSEL0_bm | VREF_DAC0REFSEL0_bm
    sts VREF_CTRLA, r16

    ;pop r16

    ret