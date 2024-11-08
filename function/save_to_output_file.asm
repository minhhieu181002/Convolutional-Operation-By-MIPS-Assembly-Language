.data
    inputFile:    .asciiz "D:/Materials_Study_Uni/Fourth year/CA/Assignment 241/Mips/inputFromAss.txt"   # Input file name
    outputFile:   .asciiz "D:/Materials_Study_Uni/Fourth year/CA/Assignment 241/Mips/output.txt"        # Output file name
    buffer:       .space 200                                      # Buffer to read file content
    newline:      .asciiz "\n"                                    # Newline string for printing

.text
    # Open the input file for reading
    li $v0, 13              # Syscall for opening a file
    la $a0, inputFile       # Load the input file name
    li $a1, 0               # Open for reading (flag 0)
    li $a2, 0               # Mode is ignored for reading
    syscall                 # Open the file
    move $s0, $v0           # Save the file descriptor of input file in $s0

    # Read the file content into the buffer
    li $v0, 14              # Syscall for reading from file
    move $a0, $s0           # File descriptor of input file
    la $a1, buffer          # Buffer to store the file content
    li $a2, 200             # Number of bytes to read (adjust as needed)
    syscall                 # Read the file content into the buffer

    # Close the input file after reading
    li $v0, 16              # Syscall for closing a file
    move $a0, $s0           # File descriptor to close
    syscall                 # Close the input file

    # Traverse and print each character in the buffer
    la $t0, buffer          # Start of the buffer (load the buffer address)
    li $t1, 0               # Initialize index counter
    
print_buffer_loop:
    lb $t2, 0($t0)          # Load the byte from the buffer (current character)
    beq $t2, 0, end_print   # If null terminator, stop (end of buffer)
    beq $t2, 10, print_newline  # If it's newline, print a newline
    li $v0, 11              # Syscall for printing a character
    move $a0, $t2           # Character to print (in $t2)
    syscall                 # Print the character
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j print_buffer_loop     # Loop and print the next character

print_newline:
    li $v0, 4               # Syscall for printing a string
    la $a0, newline         # Load the newline string
    syscall                 # Print the newline
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j print_buffer_loop     # Continue printing the buffer

end_print:
    # Open the output file for writing
    li $v0, 13              # Syscall for opening a file
    la $a0, outputFile      # Load the output file name
    li $a1, 1               # Open for writing (flag 1)
    li $a2, 0               # Mode is ignored
    syscall                 # Open the output file
    move $s1, $v0           # Save the file descriptor of output file in $s1

    # Write the buffer content to the output file
    li $v0, 15              # Syscall for writing to file
    move $a0, $s1           # File descriptor of output file
    la $a1, buffer          # Address of the buffer to write
    li $a2, 200             # Number of bytes to write (adjust as needed)
    syscall                 # Write the buffer content to the output file

    # Close the output file after writing
    li $v0, 16              # Syscall for closing a file
    move $a0, $s1           # File descriptor to close
    syscall                 # Close the output file

    # Exit the program
    li $v0, 10              # Syscall for exit
    syscall
