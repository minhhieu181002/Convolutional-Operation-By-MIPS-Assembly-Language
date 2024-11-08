.data
float_number: .float 2.46           # Example floating-point number
digitBuffer: .space 2                # Buffer to hold the rounded first decimal digit
newline: .asciiz "\n"                # Newline for formatting
num_100: .float 100.0
.text
.globl main
main:
    # Load the floating-point number into $f0
    l.s $f0, float_number

    # Step 1: Convert to integer to extract the integer part
    cvt.w.s $f2, $f0                # Convert float in $f0 to integer
    mfc1 $t0, $f2                   # Move integer part to $t0

    # Step 2: Subtract integer part from original to get decimal part
    cvt.s.w $f2, $f2                # Convert integer part back to float
    sub.s $f4, $f0, $f2             # $f4 = decimal part of original number

    # Step 3: Multiply decimal part by 100 to shift first two decimal digits
    l.s $f6, num_100                # Load 100.0 into $f6
    mul.s $f4, $f4, $f6             # $f4 = decimal part * 100

    # Step 4: Convert to integer to get first two decimal digits
    cvt.w.s $f8, $f4                # Convert $f4 to integer
    mfc1 $t1, $f8                   # Move first two decimal digits to $t1

    # Step 5: Extract first and second decimal digits
    div $t1, $t1, 10                # Divide by 10 to get first and second digits
    mfhi $t2                        # $t2 = second digit (remainder)
    mflo $t1                        # $t1 = first digit

    # Step 6: Check second digit and round first digit if necessary
    li $t3, 5                       # Load 5 to compare
    bge $t2, $t3, round_up          # If second digit >= 5, go to round up
    j store_digit                   # Else, store the first digit as is

round_up:
    addi $t1, $t1, 1                # Round up the first digit by adding 1

store_digit:
    # Step 7: Convert first digit to ASCII and store in digitBuffer
    addi $t1, $t1, 48               # Convert to ASCII
    sb $t1, digitBuffer             # Store in digitBuffer

    # Print the rounded first decimal digit
    li $v0, 11                      # Syscall for printing a character
    lb $a0, digitBuffer             # Load the character from digitBuffer
    syscall

    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

    # Exit program
    li $v0, 10                      # Syscall to exit
    syscall
