        LSTON
#################################
#                               #
#    CALCULATION OF E -- 14K    #
#                               #
#      WOZ       20-APR-80      #
#                               #
#        EXAMPLE PROGRAM        #
#                               #
#################################
#                               #
#  LOCATIONS $800-3FFF ARE USED #
#  FOR THE (BINARY) FRACTION OF #
#  E. LOCATION $800 IS THE MOST #
#  SIGNIFICANT BYTE, $3FFF IS   #
#  THE LEAST SIGNIFICANT.  THIS #
#  CORRESPONDS TO APPROXIMATELY #
#  34524 DIGITS.                #
#                               #
#################################
#                               #
#  THE FIRST DIVISOR IS 9720    #
#  AND THE LAST IS 2. 9720      #
#  FACTORIAL IS GREATER THAN    #
#  10 ^34524.                   #
#                               #
#################################
#                               #
#  THE MAJOR OPERATION IS AN    #
#  INCREMENT (+1) OF E FOLLOWED #
#  BY A MULTI-PRECISION DIVIDE  #
#  BY THE CURRENT DIVISOR.      #
#  EACH SUCCESSIVELY LESS SIG-  #
#  NIFICANT BYTE OF E, TOGETHER #
#  WITH THE RESIDUAL REMAINDER  #
#  A1 AND A2, IS DIVIDED BY THE #
#  CURRENT 2-BYTE DIVISOR.  THE #
#  8-BIT QUOTIENT IS LEFT IN E  #
#  AND THE RESIDUAL REMAINDER   #
#  IN A1 AND A2 (ACC HOLDS A2)  #
#                               #
#################################
A1      EQU  0         (CURRENT BYTE OF E IS A0, ACC IS A2)
PCOUNT  EQU  1         COUNTS RAM PAGES OF E ARRAY.
E       EQU  $800      E, BINARY FRACTION, TO $3FFF.
NUMPAG  EQU  $38       14k IS 56 RAM PAGES.
N       EQU  9720      (N FACTORIAL IS > 34524 DIGITS)
NL      EQU  N&$FF     LO BYTE OF N.
NH      EQU  N/256     HI BYTE OF N.

        ORG  $240
NXTDVSR LDA  #NUMPAG    INIT RAM PAGE COUNTER
        STA  PCOUNT       FOR 56 PAGES.
        LDA  #1
        STA  A1         INIT RESIDUAL REMAINDER TO 1. (FOR +1)
        LDA  #E/256
        STA  EREF1+2    MODIFY CODE SO THAT REFS
        STA  EREF2+2      TO E POINT TO FIRST BYTE.
        LDA  #0         (ACC IS ALSO A2 OF RESIDUAL REMAINDER)
        STA  EREF1+1
        STA  EREF2+1
NXTBYTE LDY  #8         (2) COUNTER--8 BITS PER BYTE
EREF1   ASL  E          (6) MSB OF DIVIDEND BYTE TO CARRY.
NXTBIT  ROL  A1         (5) SHIFT 3-BYTE DIVIDEND.
        ROL  A          (2)  (ACC IS A2)
NHREF1  CMP  #NH        (2) IF HI BYTE LESS THAN DIVISOR
        BCC  EREF2      (3/2)   THEN QUOTIENT BIT IS 0.
        BNE  REPLACE    (3/2) (TAKEN IF GREATER)
        LDX  A1         (3) COMPARE LOW BYTES IF HI BYTES EQUAL.
NLREF1  CPX  #NL        (2)
        BCC  EREF2      (3/2) IF LESS, QUOTIENT BIT IS 0.
REPLACE TAX             (2)
        LDA  A1         (3) REPLACE RESIDUAL REMAINDER A1 AND A2
NLREF2  SBC  #NL        (2)   WITH RESIDUAL REMAINDER
        STA  A1         (3)   MINUS CURRENT DIVISOR.
        TXA             (2) (HI BYTE OF RESIDUAL REMAINDER)
NHREF2  SBC  #NH        (2) (GUARANTEED TO SET CARRY)
EREF2   ROL  E          (6) QUOTIENT BIT INTO A0 LSB, MSB TO CARRY.
        DEY             (2) NEXT OF 8 BITS.
        BNE  NXTBIT     (3/2) LOOP--NOTE: CARRY = QUOTIENT BIT.
        INC  EREF1+1    (5)
        INC  EREF2+1    (5) MODIFY CODE REFS TO E ARRAY.
        BNE  NXTBYTE    (3)  (NO BYTE OVERFLOW)
        INC  EREF1+2
        INC  EREF2+2    (MODIFY HI BYTE)
        DEC  PCOUNT
        BNE  NXTBYTE    LOOP UNTIL DONE 56 RAM PAGES.
        LDA  NLREF1+1
        BNE  NXTDVR2
        DEC  NHREF1+1   DECR IMMEDIATE REFS TO
        DEC  NHREF2+1     CURRENT DIVISOR.
NXTDVR2 DEC  NLREF1+1
        DEC  NLREF2+1
        LDA  NLREF1+1
        LSR  A
        ORA  NHREF1+1   LOOP IF DIVISOR > 1.
        BNE  NXTDVSR
        RTS             (DONE)
