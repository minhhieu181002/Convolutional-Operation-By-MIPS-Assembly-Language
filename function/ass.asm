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
    # --- Dynamically allocate memory for 2 matrix ---
    lw $t1, N               # Load N (size of the image matrix)
    lw $t2, M
    # Calculate total memory needed for the 2 matrix [(N * N) + (M * M)] * 4 bytes for floating point)
    mul $t3, $t1, $t1       # N * N (number of elements in the image matrix)
    mul $t4, $t2, $t2       # M * M (number of elements in the kernel matrix)
  
    li $t5, 4               # Each element is 4 bytes (float)
    #total byte needed for 2 matrix
    add $t6,$t3,$t4
    mul $a0, $t6, $t5       # [(N * N) + (M * M)] * 4 (total bytes needed for 2 matrix)

    # Allocate memory for the image matrix
    li $v0, 9               # Syscall for memory allocation
    syscall                 # Allocate memory
    move $s1, $v0           # Save the allocated address for the image matrix in $s1
    move $t7, $s1        # use $t7 for adjust the address of the array 

    # --- Parsing the image matrix ---
    addi $t0, $t0, 3        # Move pointer after the first row
    li $t3, 0 		#variable for check negative
    li $t5, 0               # Index counter for image matrix elements
    #li $t6, 6               # Load the size of the image matrix (N * N)

parse_matrix:
    beq $t5, $t6, done_parsing_matrices  # Stop when all elements are parsed
    
    # Initialize the floating-point registers properly using integer registers and mtc1
    li $t1, 0x00000000                      # Load 0 into integer register
    mtc1 $t1, $f0                           # Move 0 into floating-point register $f0 (accumulator)
    mtc1 $t1, $f6                           # Move 0 into floating-point register $f6 (fractional accumulator)
    li $t1, 0x41200000                      # Load 10.0 (IEEE 754 for 10.0) into $t1
    mtc1 $t1, $f9                           # Move 10.0 into floating-point register $f9 (divisor for fractional part)
    
    jal parse_floating_point                    # Call function to parse a floating-point number
    s.s $f0, 0($t7)                            # Store parsed floating-point number into image matrix
    addi $t7, $t7, 4                           # Move to next element (4 bytes per float)
    addi $t5, $t5, 1                           # Increment the index
    j parse_matrix                       # Loop until all elements are parsed

done_parsing_matrices:
    # Print the Image Matrix
    #jal initialize_padded_image
    jal print_matrix
    #j print_matrix
   
    # Exit the program
    li $v0, 10              # Syscall for exit
    syscall
	
# --- Function to parse a floating-point number from the buffer ---
parse_floating_point:
    lb $t2, 0($t0)
    beq $t2, 45, saveSign
    beq $t2, 0, finish_parsing              # If null terminator (end of string), stop
    beq $t2, 46, parse_fraction_part        # If '.', switch to parsing the fractional part
    beq $t2, 32,  finish_parsing            # If space, we're done with this number
    beq $t2, 10, finish_parsing             # If newline, we're done with this number
    beq $t2, 13, finish_parsing
    
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
	lb $t2, 0($t0) #if the next byte is not "." => does not have fraction part
	beq $t2, 32, finish_parsing
	j parse_floating_point
saveSign:
	addi $t3,$t3, 1    #the is number is negative number
	addi $t0, $t0, 1 #ignore this sign
	j parse_floating_point
	
parse_fraction_part:
	addi $t0,$t0,1
parse_fraction_loop:
	lb $t2, 0($t0)
	beq $t2,0, finish_parsing
	beq $t2,32, finish_parsing    #if space, we are with this number
	beq $t2,10, finish_parsing    #if newline, we are done with this array
	beq $t2,13, parse_kernel_matrix    #jump to parse the kernel matrix
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
	addi $t0,$t0,1
	add.s $f0,$f0,$f6 #add fractional part to the integer part
	beq $t3, 1, conToNegNum
	jr $ra
conToNegNum:
	neg.s $f0, $f0
	li $t3, 0
	jr $ra
	
	
parse_kernel_matrix:
	addi $t0,$t0,2
	jr $ra
	
		

# --- Function to print the image matrix ---
print_matrix:
    # Print the title of the matrix
    li $v0, 4               # Syscall to print a string
    la $a0, titleMatrix # Load the title for the image matrix
    syscall                 # Print the title

    # Load N (size of the matrix)
    #li $t1, 6               # Load the size of the matrix N
    #mul $t1, $t1, $t1       # Calculate N * N (total elements in the image matrix)
    
    # Loop to print each floating-point element in the matrix
    
    la $a0, 0($s1)
    move $t2, $a0           # Set starting address of the image matrix in memory
    li $t3, 0               # Initialize element counter

print_matrix_loop:
    beq $t3, $t6, end_print_matrix  # Stop when all elements are printed

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
    j initialize_padded_image
    #jr $ra                  # Return to caller
    
############################ INITIALIZE THE PADDING IMAGE ############################
initialize_padded_image:
    lw  $t2, p                   # Load the padding size
    lw  $t3, N                   # Load the image matrix size (N)
    # Calculate the size of the padded matrix (N + 2 * padding)
    li  $t4, 2
    mul $t1, $t2, $t4            # t1 = 2 * padding
    add $t1, $t1, $t3            # t1 = N + 2 * padding (size of the padded matrix)
    sw $t1, paddedSize
    # Calculate total bytes needed for the padded matrix
    li  $t4, 4                   # Each element is 4 bytes (float)
    mul $t2, $t1,$t1 		# Total element for padded matrix
    mul $t3, $t2, $t4            # t2 = total bytes needed for the matrix

    move $a0, $t3                # Number of bytes to allocate
    li   $v0, 9                  # Syscall for memory allocation
    syscall                      # Allocate memory
    move $s2, $v0                # Save the allocated base address of the padded matrix in $s2
    move $t4, $s2 #$t2 is the base address of the padded image -> use for moving
    ############################# INITIALIZE WITH 0.0 ###############################
    la  $t0, zero                # Load the address of 0.0 (which is pre-defined in the .data section)
    lwc1 $f0, 0($t0)             # Load 0.0 into the floating-point register $f0

    li  $t5, 0                   # Initialize counter for the number of elements (total number of elements in the matrix)
initialize_loop:
    #mul $t2, $t1, $t1            # t2 = paddedSize * paddedSize (total number of elements)
    bge $t5, $t2, initialize_done # Exit loop if all elements initialized

    # Store 0.0 into the current matrix position
    swc1 $f0, 0($t4)             # Store 0.0 into the padded matrix at the current address

    addi $t4, $t4, 4             # Move to the next float element (4 bytes per float)
    addi $t5, $t5, 1             # Increment the counter
    j    initialize_loop          # Repeat the loop

initialize_done:
    # Call the function to print the padded matrix
    #move $a0, $t1                # Pass the size of the padded matrix (N + 2 * padding)
    #move $a1, $v0                # Base address of the padded matrix
    #jal insert_image_to_padded
    #jr  $ra                      # Return to the caller
############################ INSERT IMAGE INTO THE PADDING IMAGE ############################
insert_image_to_padded:
    lw  $t0, p                   # Load the padding size
    lw  $t1, paddedSize                 #size of padded matrix  
    lw  $t8, N   # Load the image matrix size (N)
    #$s2                # Base address of the padded matrix (already allocated)
    la   $t2, 0($s1)        # Base address of the image matrix

    li   $t3, 0                  # Initialize row index for the image matrix
insert_image_rows:
    beq  $t3, $t8, insert_done   # If all rows of the image matrix are copied, exit the loop
    li   $t4, 0                  # Initialize column index for the image matrix

insert_image_columns:
    bge  $t4, $t8, next_image_row # If all columns of the image matrix row are copied, move to the next row

    # Load the element from the image matrix
    l.s $f0, 0($t2)             # Load the element at position (row, col) of the image matrix
    #li $v0, 2               # Syscall to print a floating-point number
    #syscall                 # Print the floating-point number
    # Calculate the target position in the padded matrix
    # padded_row = t3 + paddingNum
    # padded_col = t4 + paddingNum
    add  $t5, $t3, $t0           # Calculate padded_row = image_row + paddingNum
    add  $t6, $t4, $t0           # Calculate padded_col = image_col + paddingNum

    # Calculate the address in the padded matrix: padded_base + ((padded_row * padded_size) + padded_col) * 4
    mul  $t7, $t5, $t1           # t7 = padded_row * padded_size
    add  $t7, $t7, $t6           # t7 = padded_row * padded_size + padded_col
    sll  $t7, $t7, 2             # t7 = (padded_row * padded_size + padded_col) * 4 (byte offset)

    # Now, calculate the actual address using the base of the padded matrix
    add  $t7, $s2, $t7           # t7 is the actual address of the padded matrix

    # Store the image matrix element into the calculated address in the padded matrix
    swc1 $f0, 0($t7)             # Store the element at the calculated position in the padded matrix

    # Move to the next column in the image matrix
    addi $t2, $t2, 4             # Move to the next element in the image matrix (4 bytes per float)
    addi $t4, $t4, 1             # Increment the column index
    j    insert_image_columns     # Repeat for the next column

next_image_row:
    addi $t3, $t3, 1             # Move to the next row in the image matrix
    j    insert_image_rows        # Repeat for the next row

insert_done:
	j  print_padded_matrix      # Call the print function
    #jr   $ra                      # Return to the caller

############################# PRINT THE PADDING IMAGE ###############################
print_padded_matrix:
    # $a0 contains the size of the padded matrix (N + 2 * padding)
    # $a1 contains the base address of the padded matrix
    lw $t1, paddedSize                # Number of rows/columns in the padded matrix
    move $t2, $s2                # Base address of the padded matrix

    li   $t3, 0                  # Row index
print_rows:
    bge  $t3, $t1, print_done    # If all rows printed, exit
    li   $t4, 0                  # Column index

print_columns:
    bge  $t4, $t1, next_row      # If all columns in the row printed, move to the next row

    l.s $f12, 0($t2)            # Load the current element into the floating-point register $f12
    li   $v0, 2                  # Syscall for printing floating-point numbers
    syscall

    # Print a space after the element
    li   $v0, 4                  # Syscall for printing strings
    la   $a0, space              # Load the address of the space string
    syscall

    addi $t2, $t2, 4             # Move to the next element (4 bytes per float)
    addi $t4, $t4, 1             # Increment column index
    j    print_columns

next_row:
    # Print a newline after each row
    li   $v0, 4                  # Syscall for printing strings
    la   $a0, newline            # Load the address of the newline string
    syscall

    addi $t3, $t3, 1             # Increment row index
    j    print_rows

print_done:
    #jr   $ra                      # Return to the caller

############################ RETRIEVE THE KERNEL MATRIX ############################
# Step 1: Load the size of the image and kernel matrices
    lw   $t0, N             # Load N (size of image matrix, N = 3)
    lw   $t1, M             # Load M (size of kernel matrix, M = 2)

    # Step 2: Calculate the number of elements in the image matrix
    mul  $t2, $t0, $t0      # t2 = N * N (number of elements in the image matrix)

    # Step 3: Calculate the offset to skip the image matrix
    li   $t3, 4             # Each element is 4 bytes (word)
    mul  $t2, $t2, $t3      # t2 = N * N * 4 (byte offset to skip image matrix)

    # Step 4: Calculate the address of the first element of the kernel matrix
    la $t4, 0($s1) #$t4 contains the based address of array
    add  $t4, $t4, $t2      # t4 = base address of kernel matrix (s1 + offset)

    # Step 5: Dynamically allocate memory for the kernel matrix
    # Calculate the total number of bytes required for the kernel matrix
    mul  $t5, $t1, $t1      # t5 = M * M (number of elements in the kernel matrix)
    mul  $t6, $t5, $t3      # t5 = M * M * 4 (total bytes required)

    move $a0, $t5           # Pass the number of bytes to allocate in $a0
    li   $v0, 9             # Syscall for memory allocation (sbrk)
    syscall                 # Allocate memory for the kernel matrix
    move $s3, $v0           # Save the base address of the allocated space for the kernel matrix
    move $t1, $s3
    # Step 6: Copy the kernel matrix from the original array to the newly allocated array
    li   $t7, 0             # Initialize element counter for kernel matrix
copy_kernel:
        bge  $t7, $t5, copy_done  # Stop copying after all elements are copied

        lwc1 $f0, 0($t4)         # Load the floating-point element from the original array (kernel matrix)
        swc1 $f0, 0($t1)         # Store the element into the newly allocated array

        addi $t4, $t4, 4         # Move to the next element in the original array (4 bytes)
        addi $t1, $t1, 4         # Move to the next position in the new array (4 bytes)
        addi $t7, $t7, 1         # Increment the element counter by 4 (bytes)
        j    copy_kernel          # Repeat until all elements are copied

copy_done:
	
    # Finished copying, now you can use the kernel matrix stored at $s3
    # Step 7: Print the kernel matrix in 2x2 format
    li   $v0, 4              # Syscall for printing a string (newline)
    la   $a0, kernelMatrix        # Load the address of the newline string
    syscall
    
    li   $v0, 4              # Syscall for printing a string (newline)
    la   $a0, newline        # Load the address of the newline string
    syscall
    
    move $t7, $s3                
    li   $t8, 0                  # Initialize the element counter for printing
    li   $t9, 0                  # Row counter for formatting (print newline after 2 elements per row)
    lw   $t1, M 		#kernel matrix size
print_kernel:
	
        bge  $t8, $t5, print_kernel_done  # Stop printing after all elements are printed

        lwc1 $f12, 0($t7)         # Load the floating-point value from the copied kernel matrix
        li   $v0, 2              # Syscall for printing a floating-point number
        syscall                  # Print the floating-point value

        # Print a space after every element except for the last in a row
        addi $t9, $t9, 1         # Increment row element counter
        bne  $t9, $t1, print_space # If the element is not the last in the row, print a space
        j    print_newline        # Otherwise, print a newline
print_space:
        li   $v0, 4              # Syscall for printing a string (space)
        la   $a0, space          # Load the address of the space string
        syscall                  # Print the space
        j    next_element
print_newline:
        li   $v0, 4              # Syscall for printing a string (newline)
        la   $a0, newline        # Load the address of the newline string
        syscall                  # Print newline after printing 2 elements (row complete)
        li   $t9, 0              # Reset row element counter

    next_element:
        addi $t8, $t8, 1         # Move to the next element in the kernel matrix
        addi $t7, $t7, 4         # Move to the next position in memory (4 bytes per float)
        j    print_kernel        # Repeat for the next element

print_kernel_done:
    li   $v0, 4              # Syscall for printing a string (space)
    la   $a0, newline           # Load the address of the space string
    syscall
    
    li   $v0, 4              # Syscall for printing a string (space)
    la   $a0, startPerformOperation           # Load the address of the space string
    syscall
    
    li   $v0, 10                 # Exit the program
    syscall

