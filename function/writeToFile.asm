.data
fout:    .asciiz "D:/Materials_Study_Uni/Fourth year/CA/Assignment 241/Mips/output.txt"
float_array: .float -1.3, -1.5, -1.0999999,2.0,0.0, 1.0,0.0, 1.0, 0.0  # Array of floating-point numbers
array_size: .word 9                                 # Number of elements in the array
newline: .asciiz "\n"                               # Newline character for formatting
space: .asciiz " "
bufferOutput: .space 1024                           # Buffer to store the final formatted result
digitBufferForIntegerPart: .space 10                              # Temporary buffer for storing digits in reverse order
num_zero: .float 0.0                           # Constant 100.0 for scaling
num_10: .float 10.0                                 # Constant 10.0 for scaling
num_100: .float 100.0    
num_0.001: .float 0.001


.text
.globl main
main:
    # Load array information
    la $t0, float_array           # $t0 points to start of float_array
    lw $t1, array_size            # Load the size of the array into $t1
    la $s0, bufferOutput          # Pointer to bufferOutput to store the final formatted result
    #la $s1, digitBufferForIntegerPart
    li $s7, 0                     # Initialize index to 0

loop_array:
    # Check if we reached the end of the array
    beq $s7, $t1, done            # If index >= array size, we're done

    # Load the next floating-point number
    l.s $f0, 0($t0)               # Load float from array into $f0
    l.s $f4, num_zero                  # Load 0.0 into $f4
    c.lt.s $f0, $f4                # Check if $f0 < 0
    bc1f positive                  # If not negative, branch to positive

negative:
    # Number is negative, so store '-' sign
    li $t4, '-'                    # ASCII for '-'
    sb $t4, 0($s0)                 # Store '-' in bufferOutput
    addiu $s0, $s0, 1              # Advance buffer pointer for the next character

    # Take absolute value
    neg.s $f0, $f0                 # Negate $f0 to make it positive

positive:
    #check the integer part here
    #if the first digit is zero: no need to extract
    cvt.w.s $f2, $f0              # Convert float in $f0 to integer
    mfc1 $t4, $f2                 # Move integer part to $t4

    # Check if the integer part is zero
    bne $t4, 0, start_extract_integer    # If integer part is not zero, skip to extraction
    
    #write 0 to buffer output
    li $t5, '0'                   # Load ASCII '0'
    sb $t5, 0($s0)                # Store '0' in bufferOutput
    addiu $s0, $s0, 1             # Advance bufferOutput pointer
    #passing number to parsing decimal part
    li $a0, '.'                   # ASCII for decimal point
    sb $a0, 0($s0)                # Store decimal point in bufferOutput
    addiu $s0, $s0, 1             # Move bufferOutput pointer
    
    move $a0, $s0                 # Base address of bufferOutput
    mov.s $f12, $f0  # Load floating point value into $f12
    
    # Step 2: Extract and round decimal part
    jal extract_decimal_part      # Call function to extract and round the first decimal part
    #else passing the number to parsing
    move $s0, $v0
    j update_index
    # Step 1: Extract integer part and reverse order
    
start_extract_integer:

    move $a0, $t4
    la   $a1, digitBufferForIntegerPart
    jal extract_integer_part      # Call function to extract integer part into bufferOutput
	
    # Reverse digitBuffer to get digits in correct order
    la $a0, digitBufferForIntegerPart           # Reset pointer to start of digitBuffer
    move $a1, $v0          # Number of digits in digitBuffer
    jal reverse_buffer     # Call reverse_buffer function
    
    move $a0, $s0          # Current pointer in bufferOutput
    la $a1, digitBufferForIntegerPart    # Base address of digitBuffer
    move $a2, $v0              # Number of digits to write
    jal writeDigitToBuffer # Call the function

    # The updated pointer of bufferOutput will be in $v0
    move $s0, $v0          # Update bufferOutput pointer in $s0 for further use
    addi $s0, $s0, 1	   #space for the dot
#after_integer_part:
    li $a0, '.'                   # ASCII for decimal point
    sb $a0, 0($s0)                # Store decimal point in bufferOutput
    addiu $s0, $s0, 1             # Move bufferOutput pointer
    
    move $a0, $s0                 # Base address of bufferOutput
    mov.s $f12, $f0  # Load floating point value into $f12

    jal extract_decimal_part      # Call function to extract and round the first decimal part
    #update the pointer of buffer output
    move $s0, $v0

update_index:
    # Add a comma if it's not the last element in the array
    addiu $s7, $s7, 1             # Increment index
    bge $s7, $t1, skip_comma      # If this is the last element, skip adding comma

    li $t3, ','                   # ASCII for comma
    sb $t3, 0($s0)                # Store comma in bufferOutput
    addiu $s0, $s0, 1             # Move buffer pointer forward by 1

skip_comma:
    # Move to the next float in the array
    addiu $t0, $t0, 4             # Move to the next float in the array
    j loop_array                  # Repeat for next array element

done:
    # Print bufferOutput by calling print_buffer function
    li $t3, '!'                   # ASCII for comma
    sb $t3, 0($s0)                # Store comma in bufferOutput
    addiu $s0, $s0, 1             # Move buffer pointer forward by 1
    jal print_buffer

    jal write_to_file        # Call the function to write to file	
    # Exit program
    li $v0, 10                    # Syscall to exit
    syscall

# Function: extract_integer_part
# Description: Extracts the integer part from a number in $a0, stores the digits in reverse order
#              in the buffer at $a1, and returns the count of digits.
# Parameters:
#   $a0 - Integer to extract digits from
#   $a1 - Base address of the buffer to store digits
#
# Returns:
#   $v0 - Number of digits extracted

extract_integer_part:
    # Save registers to the stack
    addiu $sp, $sp, -16           # Allocate space on the stack
    sw $ra, 12($sp)               # Save return address
    sw $t4, 8($sp)                # Save temporary register $t4
    sw $t5, 4($sp)                # Save temporary register $t5
    sw $t6, 0($sp)                # Save temporary register $t6

    # Initialize variables
    li $t5, 10                    # Divisor for extracting digits (10)
    li $t6, 0                     # Digit count, initialized to 0
    move $t4, $a0                 # Copy the integer to $t4 for processing
    move $t7, $a1                 # Base address of digit buffer in $t7

extract_digits:
    blez $t4, done_integer_part   # If $t4 is 0, we are done with the integer part

    # Extract the last digit
    div $t4, $t5                  # Divide $t4 by 10
    mfhi $t8                      # $t8 = remainder (last digit)
    mflo $t4                      # Update $t4 with quotient

    # Store the ASCII of the digit in the buffer
    addi $t8, $t8, 48             # Convert digit to ASCII
    sb $t8, 0($t7)                # Store ASCII character in the buffer at $t7
    addiu $t7, $t7, 1             # Move buffer pointer forward
    addiu $t6, $t6, 1             # Increment digit count
    j extract_digits              # Repeat for the next digit

done_integer_part:
    # Return the number of digits extracted in $v0
    move $v0, $t6                 # $v0 = digit count

    # Restore registers from the stack
    lw $t6, 0($sp)                # Restore $t6
    lw $t5, 4($sp)                # Restore $t5
    lw $t4, 8($sp)                # Restore $t4
    lw $ra, 12($sp)               # Restore return address
    addiu $sp, $sp, 16            # Deallocate stack space

    jr $ra                         # Return to caller

# Function: extract_decimal_part
# Description: Extracts and rounds the first decimal digit from a floating-point number
#              passed in $f12 and stores it in bufferOutput.
# Parameters:
#   $f12 - floating-point number (passed as a parameter)
#   $a0 - base address of bufferOutput

extract_decimal_part:
    # Save registers to the stack
    addiu $sp, $sp, -20           # Allocate space on the stack
    sw $ra, 16($sp)               # Save return address
    sw $s0, 12($sp)               # Save bufferOutput base address
    sw $t9, 8($sp)                # Save temporary register $t9
    sw $s6, 4($sp)                # Save temporary register $s6
    sw $s7, 0($sp)                # Save temporary register $s7

    # Set up $s0 as the base address of bufferOutput from $a0
    move $s0, $a0                 # Move bufferOutput base address to $s0

    # Step 1: Extract the integer part
    cvt.w.s $f2, $f12             # Convert floating-point number in $f12 to integer
    mfc1 $t4, $f2                 # Move integer part to $t4

    # Step 2: Convert integer part back to float and subtract to get decimal part
    cvt.s.w $f2, $f2              # Convert integer part back to float
    l.s $f10, num_0.001
    sub.s $f4, $f12, $f2          # $f4 = decimal part of the original number
    add.s $f4, $f4, $f10
    # Step 3: Multiply decimal part by 100 to shift the first two decimal digits
    l.s $f6, num_100              # Load 100.0 into $f6
    
    mul.s $f4, $f4, $f6           # $f4 = decimal part * 100

    # Step 4: Convert to integer to get the first two decimal digits
    cvt.w.s $f8, $f4              # Convert $f4 to integer
    mfc1 $t9, $f8                 # Move first two decimal digits to $t9

    # Step 5: Extract first and second decimal digits
    div $t9, $t9, 10              # Divide by 10 to get first and second digits
    mfhi $s6                      # $s6 = second digit
    mflo $t9                      # $t9 = first digit

    # Step 6: Check second digit for rounding
    li $s7, 5                     # Load 5 for rounding comparison
    bge $s6, $s7, round_up        # If second digit >= 5, round up
    j store_first_decimal         # Otherwise, store the first decimal as is

round_up:
    addi $t9, $t9, 1              # Round up the first digit

store_first_decimal:
    addi $t9, $t9, 48             # Convert to ASCII
    sb $t9, 0($s0)                # Store in bufferOutput at $s0
    addiu $s0, $s0, 1             # Move bufferOutput pointer
    move $v0, $s0

    # Restore registers from the stack
    lw $s7, 0($sp)                # Restore $s7
    lw $s6, 4($sp)                # Restore $s6
    lw $t9, 8($sp)                # Restore $t9
    lw $s0, 12($sp)               # Restore bufferOutput base address
    lw $ra, 16($sp)               # Restore return address
    addiu $sp, $sp, 20            # Deallocate stack space

	
    jr $ra                         # Return to caller


# Function: print_buffer
# Description: Prints the contents of bufferOutput.
print_buffer:
    la $t5, bufferOutput          # Load bufferOutput address
print_loop:
    lb $t6, 0($t5)                # Load byte from bufferOutput
    beq $t6, 0, end_print         # If null terminator, exit
    li $v0, 11                    # Print character syscall
    move $a0, $t6                 # Load character to print
    syscall
    addiu $t5, $t5, 1             # Move to next byte
    j print_loop                  # Repeat until null terminator

end_print:
    # Print newline for formatting
    li $v0, 4
    la $a0, newline
    syscall
    jr $ra                         # Return to main

# Function: reverse_buffer
# Description: Reverses the contents of a buffer to store digits in the correct order.
# Parameters:
#   $a0 - base address of the buffer
#   $a1 - number of digits in the buffer

reverse_buffer:
    # Save registers to the stack
    addiu $sp, $sp, -16           # Allocate space on stack
    sw $ra, 12($sp)               # Save return address
    sw $t5, 8($sp)                # Save temporary register $t5
    sw $t6, 4($sp)                # Save temporary register $t6
    sw $t7, 0($sp)                # Save temporary register $t7

    # Set up pointers
    move $t5, $a0                 # Start pointer (base address of the buffer)
    add $t6, $t5, $a1             # End pointer (base address + number of digits)
    subi $t6, $t6, 1              # Adjust to point to the last valid digit

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
    # Restore registers from the stack
    lw $t7, 0($sp)                # Restore $t7
    lw $t6, 4($sp)                # Restore $t6
    lw $t5, 8($sp)                # Restore $t5
    lw $ra, 12($sp)               # Restore return address
    addiu $sp, $sp, 16            # Deallocate stack space

    jr $ra                         # Return to caller
# Function: writeDigitToBuffer
# Description: Copies digits from digitBuffer to bufferOutput.
# Parameters:
#   $a0 - Current pointer of bufferOutput
#   $a1 - Base address of digitBuffer
#   $a2 - Number of digits to write

writeDigitToBuffer:
    # Save registers to the stack
    addiu $sp, $sp, -12           # Allocate space on the stack
    sw $ra, 8($sp)                # Save return address
    sw $t0, 4($sp)                # Save temporary register $t0
    sw $t1, 0($sp)                # Save temporary register $t1

    # Initialize loop variables
    move $t0, $a1                 # $t0 points to base address of digitBuffer
    move $t1, $a0                 # $t1 points to current pointer of bufferOutput
    move $t2, $a2                 # Number of digits to copy

copy_loop:
    # Check if all digits are copied
    blez $t2, end_write           # If $t2 <= 0, end the function

    # Load a byte from digitBuffer and store it in bufferOutput
    lb $t3, 0($t0)                # Load digit from digitBuffer
    sb $t3, 0($t1)                # Store digit in bufferOutput

    # Advance pointers
    addiu $t0, $t0, 1             # Move to the next digit in digitBuffer
    addiu $t1, $t1, 1             # Move to the next position in bufferOutput
    subi $t2, $t2, 1              # Decrease the count of digits to copy
    j copy_loop                   # Repeat the loop

end_write:
    # Update bufferOutput pointer (returning the updated pointer in $v0)
    subi $t1, $t1, 1
    move $v0, $t1                 # $v0 now points to the new position in bufferOutput

    # Restore registers from the stack
    lw $t1, 0($sp)                # Restore $t1
    lw $t0, 4($sp)                # Restore $t0
    lw $ra, 8($sp)                # Restore return address
    addiu $sp, $sp, 12            # Deallocate stack space

    jr $ra                         # Return to caller

# Function: write_to_file
# Description: Opens a file and writes each character from bufferOutput to the file.
#              Stops when '!' is encountered. Replaces ',' with a newline.
# Parameters:
#   $a0 - Base address of bufferOutput

write_to_file:
    # Save registers to the stack
    addiu $sp, $sp, -12           # Allocate space on stack
    sw $ra, 8($sp)                # Save return address
    sw $t0, 4($sp)                # Save temporary register $t0
    sw $t1, 0($sp)                # Save temporary register $t1

    # Step 1: Open the file in write mode
    li $v0, 13                    # Syscall for opening a file
    la $a0, fout              # File name
    li $a1, 1                     # Flag: 1 for write-only
    li $a2, 0                     # Mode: 0 (not applicable for writing)
    syscall
    move $t0, $v0                 # Store file descriptor in $t0

    # Check if file opened successfully
    #bltz $t0, file_error          # If file descriptor is negative, jump to error

    # Step 2: Loop through bufferOutput
    la $t1, bufferOutput                 # $t1 points to the current character in bufferOutput

write_loop:
    lb $t2, 0($t1)                # Load the current character from bufferOutput

    # Check for end condition '!'
    li $t3, '!'                   # Load '!' to compare
    beq $t2, $t3, end_write_to_output       # If character is '!', end writing

    # Check if character is a comma ','
    li $t3, ','                   # Load ',' to compare
    beq $t2, $t3, write_space   # If character is ',', write a newline

    # Otherwise, write the character to file
    li $v0, 15                    # Syscall for writing to file
    move $a0, $t0                 # File descriptor
    move $a1, $t1                 # Address of the character to write
    li $a2, 1                     # Number of bytes to write
    syscall

    j next_char                   # Go to next character

write_space:
    # Write newline character instead of comma
    li $v0, 15                    # Syscall for writing to file
    move $a0, $t0                 # File descriptor
    la $a1, space               # Address of the newline character
    li $a2, 1                     # Number of bytes to write
    syscall

next_char:
    addiu $t1, $t1, 1             # Move to the next character in bufferOutput
    j write_loop                  # Repeat loop

end_write_to_output:
    # Step 3: Close the file
    li $v0, 16                    # Syscall for closing file
    move $a0, $t0                 # File descriptor
    syscall

    # Restore registers from the stack
    lw $t1, 0($sp)                # Restore $t1
    lw $t0, 4($sp)                # Restore $t0
    lw $ra, 8($sp)                # Restore return address
    addiu $sp, $sp, 12            # Deallocate stack space

    jr $ra                         # Return to caller

file_error:
    # Handle file open error (for simplicity, just return in this example)
    li $v0, 10                    # Exit syscall
    syscall