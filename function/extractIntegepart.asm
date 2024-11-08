.data
float_array: .float 2343.2   # Example array of floating-point numbers
array_size: .word 1                       # Number of elements in the array
newline: .asciiz "\n"                      # Newline character for formatting

# Pre-allocated buffer for digits (assuming maximum 10 digits for simplicity)
digitBuffer: .space 10                     # Buffer to hold digits temporarily

.text
.globl main
main:
    # Load array information
    la $t0, float_array           # $t0 points to start of float_array
    lw $t1, array_size            # Load the size of the array into $t1
    li $t2, 0                     # Initialize index to 0

loop_array:
    # Check if we reached the end of the array
    bge $t2, $t1, done            # If index >= array size, we're done

    # Load the next floating-point number
    l.s $f0, 0($t0)               # Load float from array into $f0

    # Convert the floating-point number to integer part and extract digits
    jal extract_integer_part      # Call function to extract integer part into digitBuffer

    # Reverse the digitBuffer to get the correct order
    jal reverse_buffer            # Call function to reverse digitBuffer contents

    # Print the extracted digits
    jal print_buffer              # Call function to print digitBuffer contents

    # Prepare for next iteration
    addiu $t0, $t0, 4             # Move to the next float in the array
    addiu $t2, $t2, 1             # Increment index
    j loop_array                  # Repeat for next array element

done:
    # Exit program
    li $v0, 10                    # Syscall to exit
    syscall

# Function: extract_integer_part
# Description: Converts the floating-point number in $f0 to its integer part,
#              extracts each digit, and stores in digitBuffer in reverse order.
extract_integer_part:
    # Step 1: Convert the floating-point number to an integer
    cvt.w.s $f2, $f0              # Convert float in $f0 to integer (rounded)
    mfc1 $t3, $f2                 # Move integer part to $t3

    # Step 2: Clear digitBuffer (optional step to reuse buffer)
    li $t4, 10                    # Buffer size
    la $t5, digitBuffer           # Pointer to digitBuffer
clear_buffer:
    beqz $t4, extract_digits      # If buffer is cleared, proceed to extraction
    sb $zero, 0($t5)              # Clear each byte to zero
    addiu $t5, $t5, 1             # Move to the next byte in buffer
    subi $t4, $t4, 1              # Decrement buffer counter
    j clear_buffer                # Repeat until buffer is cleared

# Step 3: Extract each digit and store in digitBuffer in reverse order
extract_digits:
    li $t6, 10                    # Divisor 10
    la $t5, digitBuffer           # Load the base address of digitBuffer
    li $t7, 0                     # Counter for storing each digit position

digit_extraction_loop:
    # Check if all digits are extracted
    blez $t3, end_extraction      # If no more digits, exit loop

    # Extract the last digit
    div $t3, $t6                  # Divide $t3 by 10
    mfhi $t8                      # $t8 = remainder (last digit)
    mflo $t3                      # Update $t3 with quotient

    # Store the digit in digitBuffer
    addi $t8, $t8, 48             # Convert digit to ASCII
    sb $t8, 0($t5)                # Store ASCII character in digitBuffer
    addiu $t5, $t5, 1             # Move to the next byte in buffer
    addi $t7, $t7, 1              # Increment the counter

    j digit_extraction_loop       # Repeat the loop

end_extraction:
    move $s1, $t7                 # Store the number of digits extracted in $s1
    jr $ra                         # Return to main

# Function: reverse_buffer
# Description: Reverses the contents of digitBuffer to store digits in the correct order.
reverse_buffer:
    la $t5, digitBuffer           # Start of digitBuffer
    add $t6, $t5, $s1             # End of buffer (digitBuffer + number of digits)
    subi $t6, $t6, 1              # Set $t6 to point to the last valid digit

reverse_loop:
    bge $t5, $t6, end_reverse     # If pointers meet or cross, we're done

    # Swap the values at $t5 and $t6
    lb $t7, 0($t5)                # Load value at the start
    lb $t8, 0($t6)                # Load value at the end
    sb $t8, 0($t5)                # Store end value at start
    sb $t7, 0($t6)                # Store start value at end

    # Move pointers inward
    addiu $t5, $t5, 1             # Move start pointer forward
    subi $t6, $t6, 1              # Move end pointer backward
    j reverse_loop                # Repeat the loop

end_reverse:
    jr $ra          
# Function: print_buffer
# Description: Iterates through digitBuffer and prints each character.
print_buffer:
    la $t5, digitBuffer           # Set $t5 to start of digitBuffer
    move $t6, $s1                 # Use the number of digits in $s1

print_loop:
    blez $t6, end_print           # If counter is zero, end print

    # Print the character
    lb $t7, 0($t5)                # Load a byte from digitBuffer
    li $v0, 11                    # Syscall for printing a character
    move $a0, $t7                 # Load the character into $a0
    syscall

    addiu $t5, $t5, 1             # Move to the next character in buffer
    subi $t6, $t6, 1              # Decrease counter
    j print_loop                  # Repeat until buffer is empty

end_print:
    # Print newline for formatting after buffer
    li $v0, 4                     # Syscall for printing a string
    la $a0, newline               # Load newline address
    syscall

    jr $ra                         # Return to main