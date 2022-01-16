.data

A1:     .byte 0
PCOUNT: .byte 1
E       = $8000
NUMPAG  = 4
N       = 970
;NUMPAG  = 1
;N       = 301
; N       = 64
;  N       = 2
; NL      = .LOBYTE(N)
; NH      = .HIBYTE(N)
NL      = N & $FF
NH      = N / 256

.code

.export _asm_e
_asm_e:
            .word E

.export _init_e_calc
_init_e_calc:
        lda #NH
        sta NHREF1+1
        sta NHREF2+1
        lda #NL
        sta NLREF1+1
        sta NLREF2+1
        rts

.export _nxt_dvsr
_nxt_dvsr:
            lda #NUMPAG
            sta PCOUNT
            lda #1
            sta A1
            lda #E/256
            sta EREF1+2
            sta EREF2+2
            lda #0
            sta EREF1+1
            sta EREF2+1
NXTBYTE:    ldy #8
EREF1:      asl E
NXTBIT:     rol A1
            rol A
NHREF1:     cmp #NH
            bcc EREF2
            bne REPLACE
            ldx A1
NLREF1:     cpx #NL
            bcc EREF2
REPLACE:    tax
            lda A1
NLREF2:     sbc #NL
            sta A1
            txa
NHREF2:     sbc #NH
EREF2:      rol E
            dey
            bne NXTBIT
            inc EREF1+1
            inc EREF2+1
            bne NXTBYTE
            inc EREF1+2
            inc EREF2+2
            dec PCOUNT
            bne NXTBYTE
            lda NLREF1+1
            bne NXTDVR2
            dec NHREF1+1
            dec NHREF2+1
NXTDVR2:    dec NLREF1+1
            dec NLREF2+1
            lda NLREF1+1
            lsr A
            ora NHREF1+1
            bne _nxt_dvsr
            rts
