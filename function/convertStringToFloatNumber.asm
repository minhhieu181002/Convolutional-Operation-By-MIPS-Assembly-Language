.data
    inputPrompt: .asciiz "Enter a floating point number: "
    inputBuffer: .space 100                  # Buffer to store user input (maximum 100 characters)
    newline: .asciiz "\n"                    # Newline for printing

.text
    # Print the input prompt
    li $v0, 4                               # Syscall to print a string
    la $a0, inputPrompt                     # Load address of the input prompt
    syscall                                 # Make the syscall

    # Read user input (floating point number as a string)
    li $v0, 8                               # Syscall to read a string
    la $a0, inputBuffer                     # Address to store user input
    li $a1, 100                             # Maximum number of characters to read
    syscall                                 # Make the syscall

    # Initialize the floating-point registers properly using integer registers and mtc1
    li $t1, 0x00000000                      # Load 0 into integer register
    mtc1 $t1, $f0                           # Move 0 into floating-point register $f0 (accumulator)
    mtc1 $t1, $f6                           # Move 0 into floating-point register $f6 (fractional accumulator)
    
    li $t1, 0x41200000                      # Load 10.0 (IEEE 754 for 10.0) into $t1
    mtc1 $t1, $f9                           # Move 10.0 into floating-point register $f9 (divisor for fractional part)

    la $t0, inputBuffer                     # Set pointer to the start of the input buffer

    # Start parsing the input string
parse_input:
    lb $t2, 0($t0)                          # Load a byte (ASCII character) from inputBuffer
    beq $t2, 0, finish_parsing              # If null terminator (end of string), stop
    beq $t2, 46, parse_fraction_part        # If '.', switch to parsing the fractional part
    beq $t2, 32, finish_parsing             # If space, we're done with this number
    beq $t2, 10, finish_parsing             # If newline, we're done with this number

    # Parse integer part (before decimal point)
    sub $t2, $t2, 48                        # Convert ASCII digit to integer ('0'-'9')
    mtc1 $t2, $f2                           # Move integer into floating-point register
    cvt.s.w $f2, $f2                        # Convert integer to single-precision float
    mul.s $f0, $f0, $f9                     # Multiply accumulator by 10 (shift left)
    add.s $f0, $f0, $f2                     # Add the current digit to the accumulator

    addi $t0, $t0, 1                        # Move to the next character
    j parse_input                           # Continue parsing the integer part

# Parse the fractional part after the decimal point
parse_fraction_part:
    addi $t0, $t0, 1                        # Move past the decimal point
parse_fraction_loop:
    lb $t2, 0($t0)                          # Load the next byte
    beq $t2, 32, finish_parsing             # If space, we are done with this number
    beq $t2, 10, finish_parsing             # If newline, we are done with this number
    sub $t2, $t2, 48                        # Convert ASCII character to integer
    mtc1 $t2, $f2                           # Move the integer into a float register
    cvt.s.w $f2, $f2                        # Convert to floating-point

    div.s $f2, $f2, $f9                     # Divide the digit by the divisor
    add.s $f6, $f6, $f2                     # Accumulate the fractional part

    mul.s $f9, $f9, $f9                     # Multiply divisor by 10 for next fractional digit
    addi $t0, $t0, 1                        # Move to the next character
    j parse_fraction_loop                   # Continue parsing the fractional part

# Combine integer and fractional parts and finish
finish_parsing:
    add.s $f0, $f0, $f6                     # Add fractional part to the integer part

    # Print the result
    li $v0, 2                               # Syscall to print a floating-point number
    mov.s $f12, $f0                         # Move the result to $f12 for printing
    syscall                                 # Print the floating-point number

    # Print a newline
    li $v0, 4                               # Syscall to print a string
    la $a0, newline                         # Load the newline string
    syscall                                 # Print the newline

    # Exit the program
    li $v0, 10                              # Syscall to exit the program
    syscall
