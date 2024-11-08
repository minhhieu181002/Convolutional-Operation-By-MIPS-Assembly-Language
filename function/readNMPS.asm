.data
    inputFile:    .asciiz "D:/Materials_Study_Uni/Fourth year/CA/Assignment 241/Mips/1.txt"   # Input file name
    buffer:       .space 200                                      # Buffer to read file content (adjust size if necessary)
    N:            .word 0                                         # To store image matrix size (N)
    M:            .word 0                                         # To store kernel matrix size (M)
    p:            .word 0                                         # To store padding value (p)
    s:            .word 0                                         # To store stride value (s)
    paddedSize:    .word 0					  # To store the size of padded matrix
    newline:      .asciiz "\n"                                    # Newline string for printing
    space:        .asciiz " "                                     # Space between matrix elements
    titleMatrix: .asciiz "The array of image and kernel matrices:\n"                   # Title for the image matrix
    zero:          .float 0.0         # Zero value for padding
    kernelMatrix: .asciiz "The Kernel Matrix"
    startPerformOperation: .asciiz "Start to perform convolutional operation..."

.text
    # Open the file for reading
    li $v0, 13              # Syscall for opening a file
    la $a0, inputFile       # Load the file name
    li $a1, 0               # Open for reading (flag 0)
    li $a2, 0               # Mode is ignored for reading
    syscall                 # Open the file
    move $s0, $v0           # Save file descriptor in $s0

    # Read the file content into the buffer
    li $v0, 14              # Syscall for reading from file
    move $a0, $s0           # File descriptor (in $s0)
    la $a1, buffer          # Buffer to store file content
    li $a2, 200             # Number of bytes to read (adjust as needed)
    syscall                 # Read the file into the buffer

    # Close the input file
    li $v0, 16              # Syscall for closing a file
    move $a0, $s0           # File descriptor to close
    syscall

    # Parse the first row (N, M, p, s) from the buffer
    la $t0, buffer          # Point to the start of the buffer

    # --- Parsing N ---
    li $t1, 0               # Initialize register to store parsed value of N
  
parse_N_loop:
    lb $t2, 0($t0)          # Load first byte (ASCII value of the first character)
    beq $t2, 46, parse_M
    #beq $t2, 32, parse_M    # Break on space (ASCII 32) to move to the next number
    sub $t2, $t2, 48        # Convert ASCII to integer (subtract ASCII '0')
    mul $t1, $t1, 10        # Shift left (multiply by 10 to prepare for the next digit)
    add $t1, $t1, $t2       # Add the parsed digit to the value
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j parse_N_loop          # Continue parsing N

parse_M:
    sw $t1, N               # Store parsed N

    # --- Skip space after N ---
    addi $t0, $t0, 3        # Skip the space after N

    # --- Parsing M ---
    li $t1, 0               # Reset the value for M
parse_M_loop:
    lb $t2, 0($t0)          # Load the next character for M
    beq $t2, 46, parse_p    # Break on space to parse next integer (padding)
    sub $t2, $t2, 48        # Convert ASCII to integer
    mul $t1, $t1, 10        # Multiply by 10 to shift left
    add $t1, $t1, $t2       # Add parsed digit to M
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j parse_M_loop          # Loop until the space
parse_p:
    sw $t1, M               # Store parsed M

    # --- Skip space after M ---
    addi $t0, $t0, 3        # Skip the space after M

    # --- Parsing p (padding) ---
    li $t1, 0               # Reset the value for p
parse_p_loop:
    lb $t2, 0($t0)          # Load the next character for p
    beq $t2, 46, parse_s    # Break on space to parse next integer (stride)
    sub $t2, $t2, 48        # Convert ASCII to integer
    mul $t1, $t1, 10        # Multiply by 10 to shift left
    add $t1, $t1, $t2       # Add parsed digit to p
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j parse_p_loop          # Loop until the space
parse_s:
    sw $t1, p               # Store parsed p

    # --- Skip space after p ---
    addi $t0, $t0, 3        # Skip the space after p

    # --- Parsing s (stride) ---
    li $t1, 0               # Reset the value for s
parse_s_loop:
    lb $t2, 0($t0)          # Load the next character for s
    beq $t2, 46, done_parsing  # Break on newline (ASCII 13) - carriage return
    sub $t2, $t2, 48        # Convert ASCII to integer
    mul $t1, $t1, 10        # Multiply by 10 to shift left
    add $t1, $t1, $t2       # Add parsed digit to s
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j parse_s_loop          # Loop until newline
    
done_parsing:
    sw $t1, s               # Store parsed s