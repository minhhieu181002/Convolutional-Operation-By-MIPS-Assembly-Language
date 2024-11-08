.data
    inputFile:    .asciiz "D:/Materials_Study_Uni/Fourth year/CA/Assignment 241/Mips/inputMatrix.txt"   # Input file name
    buffer:       .space 200                                      # Buffer to read file content (adjust size if necessary)
    N:            .word 0                                         # To store image matrix size (N)
    M:            .word 0                                         # To store kernel matrix size (M)
    p:            .word 0                                         # To store padding value (p)
    s:            .word 0                                         # To store stride value (s)
    newline:      .asciiz "\n"                                    # Newline string for printing
    space:        .asciiz " "                                     # Space between matrix elements
    titleImageMatrix: .asciiz "Image Matrix:\n"                   # Title for the image matrix
    titleKernelMatrix: .asciiz "Kernel Matrix:\n"                 # Title for the kernel matrix

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
    beq $t2, 32, parse_M    # Break on space (ASCII 32) to move to the next number
    sub $t2, $t2, 48        # Convert ASCII to integer (subtract ASCII '0')
    mul $t1, $t1, 10        # Shift left (multiply by 10 to prepare for the next digit)
    add $t1, $t1, $t2       # Add the parsed digit to the value
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j parse_N_loop          # Continue parsing N
parse_M:
    sw $t1, N               # Store parsed N

    # --- Skip space after N ---
    addi $t0, $t0, 1        # Skip the space after N

    # --- Parsing M ---
    li $t1, 0               # Reset the value for M
parse_M_loop:
    lb $t2, 0($t0)          # Load the next character for M
    beq $t2, 32, parse_p    # Break on space to parse next integer (padding)
    sub $t2, $t2, 48        # Convert ASCII to integer
    mul $t1, $t1, 10        # Multiply by 10 to shift left
    add $t1, $t1, $t2       # Add parsed digit to M
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j parse_M_loop          # Loop until the space
parse_p:
    sw $t1, M               # Store parsed M

    # --- Skip space after M ---
    addi $t0, $t0, 1        # Skip the space after M

    # --- Parsing p (padding) ---
    li $t1, 0               # Reset the value for p
parse_p_loop:
    lb $t2, 0($t0)          # Load the next character for p
    beq $t2, 32, parse_s    # Break on space to parse next integer (stride)
    sub $t2, $t2, 48        # Convert ASCII to integer
    mul $t1, $t1, 10        # Multiply by 10 to shift left
    add $t1, $t1, $t2       # Add parsed digit to p
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j parse_p_loop          # Loop until the space
parse_s:
    sw $t1, p               # Store parsed p

    # --- Skip space after p ---
    addi $t0, $t0, 1        # Skip the space after p

    # --- Parsing s (stride) ---
    li $t1, 0               # Reset the value for s
parse_s_loop:
    lb $t2, 0($t0)          # Load the next character for s
    beq $t2, 13, done_parsing  # Break on newline (ASCII 13) - carriage return
    sub $t2, $t2, 48        # Convert ASCII to integer
    mul $t1, $t1, 10        # Multiply by 10 to shift left
    add $t1, $t1, $t2       # Add parsed digit to s
    addi $t0, $t0, 1        # Move to the next character in the buffer
    j parse_s_loop          # Loop until newline
done_parsing:
    sw $t1, s               # Store parsed s

    # --- Dynamically allocate memory for image matrix ---
    lw $t1, N               # Load N (size of the image matrix)

    # Calculate total memory needed for the image matrix (N * N * 4 bytes for floating point)
    mul $t3, $t1, $t1       # N * N (number of elements in the image matrix)
    li $t4, 4               # Each element is 4 bytes (float)
    mul $a0, $t3, $t4       # N * N * 4 (total bytes needed for image matrix)

    # Allocate memory for the image matrix
    li $v0, 9               # Syscall for memory allocation
    syscall                 # Allocate memory
    move $s1, $v0           # Save the allocated address for the image matrix in $s1

    
    # --- Allocate memory for the kernel matrix ---
    lw $t1, M               # Load M (size of the kernel matrix)

    # Calculate total memory needed for the kernel matrix (M * M * 4 bytes for floating point)
    mul $t3, $t1, $t1       # M * M (number of elements in the kernel matrix)
    li $t4, 4               # Each element is 4 bytes (float)
    mul $a0, $t3, $t4       # M * M * 4 (total bytes needed for kernel matrix)

    # Allocate memory for the kernel matrix
    li $v0, 9               # Syscall for memory allocation
    syscall                 # Allocate memory
    move $s2, $v0           # Save the allocated address for the kernel matrix in $s2
    
     # --- Parsing the image matrix ---
    addi $t0, $t0, 2        # Move pointer after the first row
    li $t5, 0               # Index counter for image matrix elements
    li $t6, 9               # Load the size of the image matrix (N * N)

parse_image_matrix:
    beq $t5, $t6, done_parsing_image_matrices  # Stop when all elements are parsed
    
    # Initialize the floating-point registers properly using integer registers and mtc1
    li $t1, 0x00000000                      # Load 0 into integer register
    mtc1 $t1, $f0                           # Move 0 into floating-point register $f0 (accumulator)
    mtc1 $t1, $f6                           # Move 0 into floating-point register $f6 (fractional accumulator)
    li $t1, 0x41200000                      # Load 10.0 (IEEE 754 for 10.0) into $t1
    mtc1 $t1, $f9                           # Move 10.0 into floating-point register $f9 (divisor for fractional part)
    
    jal parse_floating_point                    # Call function to parse a floating-point number
    s.s $f0, 0($s1)                            # Store parsed floating-point number into image matrix
    addi $s1, $s1, 4                           # Move to next element (4 bytes per float)
    addi $t5, $t5, 1                           # Increment the index
    j parse_image_matrix                       # Loop until all elements are parsed

done_parsing_image_matrices:
    # Print the Image Matrix
    jal print_image_matrix                     # Call the function to print the image matrix

done_parsing_kernel_matrix:

    # --- Parsing the kernel matrix ---
    jal parse_kernel_matrix                     # Call the function to parse the kernel matrix

    # Print the Kernel Matrix
    jal print_kernel_matrix                     # Call the function to print the kernel matrix

    # Exit the program
    li $v0, 10              # Syscall for exit
    syscall
	
# --- Function to parse a floating-point number from the buffer ---
parse_floating_point:
    lb $t2, 0($t0)
    beq $t2, 0, finish_parsing              # If null terminator (end of string), stop
    beq $t2, 46, parse_fraction_part        # If '.', switch to parsing the fractional part
    beq $t2, 32,  nextDigit            # If space, we're done with this number
    beq $t2, 10, finish_parsing             # If newline, we're done with this number

    
    #parse integer part 
    sub $t2,$t2,48 #convert to integer
    mtc1 $t2,$f2   #move integer into floating point number
    cvt.s.w $f2,$f2 #convert integer to single-precision float
    
    mul.s $f0,$f0,$f9 #multiply accumlator by 10 (shift left)
    add.s $f0,$f0,$f2 #add the current digit to the accumulator
    
    add $t0,$t0,1 #move to the next charater
    j parse_floating_point

nextDigit:
	addi $t0,$t0,1
	j parse_floating_point
parse_fraction_part:
	addi $t0,$t0,1
parse_fraction_loop:
	lb $t2, 0($t0)
	beq $t2,32, finish_parsing    #if space, we are with this number
	beq $t2,10, finish_parsing    #if newline, we are done with this array
	beq $t2,13, parse_kernel_matrix
	sub $t2,$t2, 48
	mtc1 $t2,$f2
	cvt.s.w $f2,$f2
	div.s $f2, $f2, $f9     # divide the digit by the dividor 4.0 -> 0.4
	add.s $f6,$f6, $f2     #accumlate the fractinal part
	li $t1, 0x41200000                      # Load 10.0 (IEEE 754 for 10.0) into $t1
    	mtc1 $t1, $f10                           # Move 10.0 into floating-point register $f9 (divisor for fractional part)
	mul.s $f9,$f9,$f10     #multiply divisor by 10 for the next fractional digit
	addi $t0,$t0,1
	j parse_fraction_loop
	
finish_parsing:
	add.s $f0,$f0,$f6 #add fractional part to the integer part
	jr $ra

parse_kernel_matrix:
    addi $t0, $t0, 1        # Move pointer after the image matrix
    li $t5, 0               # Index counter for kernel matrix elements
    li $t6, 4               # Load the size of the kernel matrix (M * M)

parse_kernel_loop:
    beq $t5, $t6, done_parsing_kernel_matrix  # Stop when all elements are parsed
    
    # Initialize the floating-point registers properly using integer registers and mtc1
    li $t1, 0x00000000                      # Load 0 into integer register
    mtc1 $t1, $f0                           # Move 0 into floating-point register $f0 (accumulator)
    mtc1 $t1, $f6                           # Move 0 into floating-point register $f6 (fractional accumulator)
    li $t1, 0x41200000                      # Load 10.0 (IEEE 754 for 10.0) into $t1
    mtc1 $t1, $f9                           # Move 10.0 into floating-point register $f9 (divisor for fractional part)
    
    jal parse_floating_point                    # Call function to parse a floating-point number
    s.s $f0, 0($s2)                            # Store parsed floating-point number into kernel matrix
    addi $s2, $s2, 4                           # Move to next element (4 bytes per float)
    addi $t5, $t5, 1                           # Increment the index
    j parse_kernel_loop                        # Loop until all elements are parsed



# --- Function to print the kernel matrix ---
print_kernel_matrix:
    # Print the title of the matrix
    li $v0, 4               # Syscall to print a string
    la $a0, titleKernelMatrix # Load the title for the kernel matrix
    syscall                 # Print the title

    # Load M (size of the matrix)
    lw $t1, M               # Load the size of the matrix M
    mul $t1, $t1, $t1       # Calculate M * M (total elements in the kernel matrix)
    
    # Loop to print each floating-point element in the matrix
    move $t2, $s2           # Set starting address of the kernel matrix in memory
    li $t3, 0               # Initialize element counter

print_kernel_loop:
    beq $t3, $t1, end_print_kernel_matrix  # Stop when all elements are printed

    l.s $f12, 0($t2)        # Load a floating-point value from the kernel matrix
    li $v0, 2               # Syscall to print a floating-point number
    syscall                 # Print the floating-point number

    # Print a space after each element
    li $v0, 4               # Syscall to print a string
    la $a0, space           # Load space string
    syscall                 # Print space

    # Move to the next element in the matrix
    addi $t2, $t2, 4        # Move to the next element (4 bytes per float)
    addi $t3, $t3, 1        # Increment element counter
    j print_kernel_loop     # Continue printing elements

end_print_kernel_matrix:
    # Print a newline at the end
    li $v0, 4               # Syscall to print a string
    la $a0, newline         # Load newline string
    syscall                 # Print newline

    jr $ra                  # Return to caller
    
    
    
    
# --- Function to print the image matrix ---
print_image_matrix:
    # Print the title of the matrix
    li $v0, 4               # Syscall to print a string
    la $a0, titleImageMatrix # Load the title for the image matrix
    syscall                 # Print the title

    # Load N (size of the matrix)
    lw $t1, N               # Load the size of the matrix N
    mul $t1, $t1, $t1       # Calculate N * N (total elements in the image matrix)
    
    # Loop to print each floating-point element in the matrix
    la $a0, -36($s1)
    move $t2, $a0           # Set starting address of the image matrix in memory
    li $t3, 0               # Initialize element counter

print_matrix_loop:
    beq $t3, $t1, end_print_matrix  # Stop when all elements are printed

    l.s $f12, 0($t2)        # Load a floating-point value from the image matrix
    li $v0, 2               # Syscall to print a floating-point number
    syscall                 # Print the floating-point number

    # Print a space after each element
    li $v0, 4               # Syscall to print a string
    la $a0, space           # Load space string
    syscall                 # Print space

    # Move to the next element in the matrix
    addi $t2, $t2, 4        # Move to the next element (4 bytes per float)
    addi $t3, $t3, 1        # Increment element counter
    j print_matrix_loop     # Continue printing elements

end_print_matrix:
    # Print a newline at the end
    li $v0, 4               # Syscall to print a string
    la $a0, newline         # Load newline string
    syscall                 # Print newline

    jr $ra                  # Return to caller
