#################################
#                               #
#     'E' PRINTOUT ROUTINES     #
#                               #
#           14K VERSION         #
#                               #
#       WOZ       20-APR-80     #
#                               #
#################################
#                               #
#  THESE SUBROUTINES PERFORM    #
#  THE CRITICAL OPERATIONS      #
#  FOR CONVERTING THE 14K       #
#  BINARY VERSION OF 'E'        #
#  TO DECIMAL FOR PRINTING.     #
#  THEY ARE INTENDED TO BE      #
#  CALLED FROM A BASIC PROGRAM  #
#  WHICH DOES THE ACTUAL        #
#  PRINTING.                    #
#                               #
#################################
#                               #
#  THE BINARY REPRESENTATION    #
#  OF THE FRACTIONAL PART OF    #
#  E (OR ANY OTHER NUMBER       #
#  TO BE CONVERTED TO DECIMAL)  #
#  IS STORED IN LOCATIONS $800  #
#  (MOST SIGNIFICANT) TO $3FFF  #
#  (LEAST).  THE SUBROUTINES    #
#  INIT AND MULT RESIDE IN THE  #
#  $4000 PAGE OF MEMORY AND     #
#  USE TABLES PRODLO AND        #
#  PRODHI IN THE $4100 AND      #
#  $4200 PAGES RESPECTIVELY.    #
#  LOWMEM MUST BE SET TO $4300  #
#  (17152 DECIMAL) OR GREATER   #
#  FROM BASIC.                  #
#                               #
#################################
#                               #
#  SUBROUTINE INIT MUST BE      #
#  CALLED ONCE TO GENERATE      #
#  'MULTIPLY BY 100' TABLES     #
#  PRODLO AND PRODHI.  INIT     #
#  MUST BE CALLED BEFORE MULT.  #
#                               #
#  SUBROUTINE MULT PERFORMS     #
#  A 'MULTIPLE BY 100' ON THE   #
#  NUMBER 'E'. IT RETURNS       #
#  THE NEXT TWO DIGITS OF THE   #
#  DECIMAL EQUIVALENT AS A      #
#  NUMBER BETWEEN 0 AND 99 IN   #
#  LOCATION 1 (WHERE BASIC      #
#  CAN PEEK IT FOR PRINTING).   #
#                               #
#################################

XSAV    EQU  0          X-REG SAVE LOCATION.
RESULT  EQU  1          RESULT BYTE FROM MULTIPLY
PCOUNT  EQU  2          COUNTS NUMBER OF RAM PAGES OF E.
PRODLO  EQU  $4100      LOW BYTE TABLE (100 * IDX).
PRODHI  EQU  $4200      HI BYT TABLE (100 * IDX).
E       EQU  $800       E, BINARY FRACTION, TO $3FFF.
NUMPAG  EQU  56         56 PAGES IN 14K
LASTPAG EQU  $3F        LAST (LEAST SIGNIFICANT) PAGE OF E.
#
######################################################
#
        ORG  $4000
INIT    STX  XSAV       PRESERVE X-REG FOR INT BASIC.
        LDA  #0         STARTING PRODUCT LO BYTE.
        TAX             STARTING PRODUCT HI BYTE.
        TAY             STARTING INDEX TO PRODUCT TABLES.
PRODGEN STA  PRODLO,Y   STORE LOW BYTE OF 100 * Y
        PHA             PRESERVE A-REG
        TXA             HI BYTE OF CURRENT PRODUCT.
        STA  PRODHI,Y   STORE HI BYTE OF 100 * Y.
        PLA             RESTORE A-REG (PRODUCT LOW BYTE).
        CLC
        ADC  #100       ADD 100 FOR NEXT PRODUCT.
        BCC  NXTPROD
        INX
NXTPROD INY             NEXT OF 256 PRODUCTS.
        BNE  PRODGEN
        LDX  XSAV       RESTORE X-REG FOR INT BASIC.
        RTS             (RETURN
#
######################################################
#
MULT    LDA  #NUMPAG
        STA  PCOUNT     56 PAGES IN 14K.
        LDA  #LASTPAG
        STA  MULT1+2    INIT E REFS FOR LEAST
        STA  MULT2+2      SIGNIFICANT RAM PAGE.
        LDY  #0         INIT INDEX TO E (WILL DECR TO $FF FIRST TIME)
        LDX  #0         TRICK TO CLEAR RESIDUAL CARRY.
        CLC
MULBYT  LDA  PRODHI,X   (4) HI PROD BYTE IS RESIDUAL CARRY.
        DEY             (2) NEXT MORE SIGNIFICANT BYTE OF E.
MULT1   LDX  E,Y        (4) (GET IT)
        ADC  PRODLO,X   (4) TIMES 100, PLUS RESIDUAL CARRY.
MULT2   STA  E,Y        (5) RESTORE PRODUCT BYTE.
        TYA             (2) LAST BYTE THIS PAGE?
        BNE  MULBYT     (3/2)  NO, CONTINUE.
        DEC  MULT1+2    (6)
        DEC  MULT2+2    (6) NEXT MORE SIGNIFICANT PAGE.
        DEC  PCOUNT     (5) DONE 56 PAGES?
        BNE  MULBYT     (3)   NO, CONTINUE.
        ADC  PRODHI,X   RETRIEVE FINAL CARRY.
        STA  RESULT     SAVE AS TWO-DIGIT RETURNED VALUE.
        LDX  XSAV       RESTORE X-REG FOR INT BASIC.
        RTS             (RETURN)
