/*** asmMult.s   ***/
/* SOLUTION; used to test C test harness
 * VB 10/14/2023
 */
    
/* Tell the assembler to allow both 16b and 32b extended Thumb instructions */
.syntax unified

#include <xc.h>

/* Tell the assembler that what follows is in data memory    */
.data
.align
 
/* define and initialize global variables that C can access */

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Ian Moser"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global a_Multiplicand,b_Multiplier,a_Sign,b_Sign,a_Abs,b_Abs,init_Product,final_Product
.type a_Multiplicand,%gnu_unique_object
.type b_Multiplier,%gnu_unique_object
.type rng_Error,%gnu_unique_object
.type a_Sign,%gnu_unique_object
.type b_Sign,%gnu_unique_object
.type prod_Is_Neg,%gnu_unique_object
.type a_Abs,%gnu_unique_object
.type b_Abs,%gnu_unique_object
.type init_Product,%gnu_unique_object
.type final_Product,%gnu_unique_object

/* NOTE! These are only initialized ONCE, right before the program runs.
 * If you want these to be 0 every time asmMult gets called, you must set
 * them to 0 at the start of your code!
 */
a_Multiplicand:  .word     0  
b_Multiplier:    .word     0  
rng_Error:       .word     0 
a_Sign:          .word     0  
b_Sign:          .word     0 
prod_Is_Neg:     .word     0 
a_Abs:           .word     0  
b_Abs:           .word     0 
init_Product:    .word     0
final_Product:   .word     0

 /* Tell the assembler that what follows is in instruction memory    */
.text
.align

.global asmUnpack, asmAbs, asmMult, asmFixSign, asmMain
.type asmUnpack,%function
.type asmAbs,%function
.type asmMult,%function
.type asmFixSign,%function
.type asmMain,%function

/* function: asmUnpack
 *    inputs:   r0: contains the packed value. 
 *                  MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *              r1: address where to store unpacked, 
 *                  sign-extended 32 bit a value
 *              r2: address where to store unpacked, 
 *                  sign-extended 32 bit b value
 *    outputs:  r0: No return value
 *              memory: 
 *                  1) store unpacked A value in location
 *                     specified by r1
 *                  2) store unpacked B value in location
 *                     specified by r2
 */
asmUnpack:   
    
    /*** STUDENTS: Place your asmUnpack code BELOW this line!!! **************/
    push {r4-r11,LR}
    /*Arm Calling Convention Part 1*/
    
    mov r4, r0
    asr r4, r4, 16
    /*Getting the 16 MSBits set into one register*/
    str r4, [r1]
    
    mov r5, r0
    ror r5, r5, 16
    asr r5, r5, 16
    /*ror moves the 16 bits from the LSB to the MSB so I can sigh exstend them
     with asr.*/
    str r5, [r2]
    
    pop {r4-r11,LR}

    mov pc, lr	 /*and the thing that ends the function*/
    /*** STUDENTS: Place your asmUnpack code ABOVE this line!!! **************/


    /***************  END ---- asmUnpack  ************/

 
/* function: asmAbs
 *    inputs:   r0: contains signed value
 *              r1: address where to store absolute value
 *              r2: address where to store sign bit 0 = "+", 1 = "-")
 *    outputs:  r0: Absolute value of r0 input. Same value as stored to location given in r1
 *              memory: store absolute value in location given by r1
 *                      store sign bit in location given by r2
 */    
asmAbs:  

    /*** STUDENTS: Place your asmAbs code BELOW this line!!! **************/
    push {r4-r11,LR}
    /*Arm Calling Convention Part 1*/
    
    
    MOV r7, 0
    MOV r8, 1
    /*setting up for sign filling, with + in r7 and - in r8*/
    
    CMP r0, 0
    STRGE r7, [r2]
    STRLT r8, [r2]
    /*compares signed value to zero, assigning a 0 to the sign address
    if CMP is positive and a 1 to the sign if the CMP is negative.*/
    
    CMP r0, 0
    /*I know I don't need to reset the flags here, but it helps me to have
     this bit of code to remind me what the following flags are checking-
     I'm checking to see if the signed value is positive to see if I need to
     just store it or if I need to 2's complement it to get the abs value*/
    STRGE r0, [r1]
    NEGLT r0, r0
    STRLT r0, [r1]
    /*if r0 is 0 or more, store it as absolute. If not, put its negative into r9
     and store that instead.*/
    
    
    pop {r4-r11,LR}

    mov pc, lr	 /*and the thing that ends the function*/
    /*** STUDENTS: Place your asmAbs code ABOVE this line!!! **************/


    /***************  END ---- asmAbs  ************/

 
/* function: asmMult
 *    inputs:   r0: contains abs value of multiplicand (a)
 *              r1: contains abs value of multiplier (b)
 *    outputs:  r0: initial product: r0 * r1
 */ 
asmMult:   

    /*** STUDENTS: Place your asmMult code BELOW this line!!! **************/
    push {r4-r11,LR}
    /*Arm Calling Convention Part 1*/
    
    mov r2, 0 
    /*the spot I'm gonna build up the product while mutliplying*/
    
 multiply:
    tst r1, 1
    beq skipStep
    add r2, r2, r0
    
 skipStep:
    lsl r1, r1, 1
    lsr r0, r0, 1
    cmp r0, 0
    bne multiply
    
    mov r0, r2
    b multPop
    
 zeroProd:
    mov r0, 0
    
 multPop:    
    pop {r4-r11,LR}

    mov pc, lr	 /*and the thing that ends the function*/
    /*** STUDENTS: Place your asmMult code ABOVE this line!!! **************/

   
    /***************  END ---- asmMult  ************/


    
/* function: asmFixSign
 *    inputs:   r0: initial product from previous step: 
 *              (abs value of A) * (abs value of B)
 *              r1: sign bit of originally unpacked value
 *                  of A
 *              r2: sign bit of originally unpacked value
 *                  of B
 *    outputs:  r0: final product:
 *                  sign-corrected version of initial product
 */ 
asmFixSign:   
    
    /*** STUDENTS: Place your asmFixSign code BELOW this line!!! **************/
    push {r4-r11,LR}
    /*Arm Calling Convention Part 1*/
    cmp r1, r2
    /*if the sign bits are the same, positive result, if they aren't, negative*/
    beq done
    
    neg r0, r0
    /*makes r0 2's complemented if the sign bits aren't the same*/
    
    
    pop {r4-r11,LR}

    mov pc, lr	 /*and the thing that ends the function*/   
    /*** STUDENTS: Place your asmFixSign code ABOVE this line!!! **************/


    /***************  END ---- asmFixSign  ************/



    
/* function: asmMain
 *    inputs:   r0: contains packed value to be multiplied
 *                  using shift-and-add algorithm
 *           where: MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *    outputs:  r0: final product: sign-corrected product
 *                  of the two unpacked A and B input values
 *    NOTE TO STUDENTS: 
 *           To implement asmMain, follow the steps outlined
 *           in the comments in the body of the function
 *           definition below.
 */  
asmMain:   
    
    /*** STUDENTS: Place your asmMain code BELOW this line!!! **************/
     push {r4-r11,LR}
     /*Arm Calling Convention Part 1*/
     /* Step 1:
     * call asmUnpack. Have it store the output values in a_Multiplicand
     * and b_Multiplier.
     */
     LDR r1, =a_Multiplicand
     LDR r2, =b_Multiplier
    
     BL asmUnpack
    

     /* Step 2a:
      * call asmAbs for the multiplicand (a). Have it store the absolute value
      * in a_Abs, and the sign in a_Sign.
      */
     LDR r0, [r1]
     LDR r1, =a_Abs
     LDR r2, =a_Sign
    
     BL asmAbs


     /* Step 2b:
      * call asmAbs for the multiplier (b). Have it store the absolute value
      * in b_Abs, and the sign in b_Sign.
      */
     LDR r1, =b_Multiplier
     LDR r0, [r1]
     LDR r1, =b_Abs
     LDR r2, =b_Sign
    
     BL asmAbs
     /* Step 3:
     * call asmMult. Pass a_Abs as the multiplicand, 
     * and b_Abs as the multiplier.
     * asmMult returns the initial (positive) product in r0.
     * In this function (asmMain), store the output value  
     * returned asmMult in r0 to mem location init_Product.
     */
     LDR r4, =a_Abs
     LDR r5, =b_Abs
    
     LDR r0, [r4]
     LDR r1, [r5]
    
     BL asmMult
    
     LDR r4, =init_Product
     STR r0, [r4]
    


     /* Step 4:
     * call asmFixSign. Pass in the initial product, and the
     * sign bits for the original a and b inputs. 
     * asmFixSign returns the final product with the correct
     * sign. Store the value returned in r0 to mem location 
     * final_Product.
     */
    
     LDR r4, =init_Product
     LDR r0, [r4]
    
     LDR r5, =a_Sign
     LDR r6, =b_Sign
    
     LDR r1, [r5]
     LDR r2, [r6]
    
     BL asmFixSign


     /* Step 5:
      * END! Return to caller. Make sure of the following:
      * 1) Stack has been correctly managed.
      * 2) the final answer is stored in r0, so that the C call 
      *    can access it.
      */


done:    
    /* restore registers, Arm Calling Convention Part 2*/
    mov r0,r0 /* these are do-nothing lines to deal with IDE mem display bug */
    mov r0,r0 

screen_shot:    pop {r4-r11,LR}

    mov pc, lr	 /*and the thing that ends the function*/    
    /*** STUDENTS: Place your asmMain code ABOVE this line!!! **************/


    /***************  END ---- asmMain  ************/

 
    
    
.end   /* the assembler will ignore anything after this line. */
