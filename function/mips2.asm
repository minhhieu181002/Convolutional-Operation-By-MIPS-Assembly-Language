.data
    fout:         .asciiz "D:/Materials_Study_Uni/Fourth year/CA/Assignment 241/Mips/textout.txt"       # File name
    buffer_write: .asciiz "my name is blackman\n"  # Text to write to file

.text
    # Open a file for writing (create if it doesn't exist)
    li $v0, 13             # System call for open file
    la $a0, fout           # Load address of file name
    li $a1, 1              # Open file for writing (write mode)
    li $a2, 0              # Mode is ignored
    syscall                # Open the file
    move $s6, $v0          # Save file descriptor to $s6
    
    ########################################
    # Write to the file just opened
    li $v0, 15             # System call for write
    move $a0, $s6          # File descriptor
    la $a1, buffer_write   # Address of the buffer to write
    li $a2, 21             # Hardcoded buffer length (21 bytes)
    syscall                # Write to file
    
    ########################################
    # Close the file
    li $v0, 16             # System call for close file
    move $a0, $s6          # File descriptor to close
    syscall                # Close the file
    
    ########################################
    # Exit the program
    li $v0, 10             # System call for exit
    syscall                # Exit the program
