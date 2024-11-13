#-----------------------------------------------------------#
#		 PROJECT COMPUTER ARCHITECTURE		    #
#		    TITLE: Convolutional Operation	    #
#		    Author: Hua Vũ Minh Hieu		    #
#		    Stu. ID: 2052990			    #
#		    Date: 11/08/2024			    #
#-----------------------------------------------------------#
.data
    inputFile:    .asciiz "D:/Materials_Study_Uni/Fourth year/CA/Assignment 241/Mips/main/Convolutional-Operation-By-MIPS-Assembly-Language/testcase/input/1_2.txt"   # Input file name
    fout:    .asciiz "D:/Materials_Study_Uni/Fourth year/CA/Assignment 241/Mips/main/Convolutional-Operation-By-MIPS-Assembly-Language/testcase/output/output.txt"
    buffer:       .space 200                                      # Buffer to read file content (adjust size if necessary)
    N:            .word 0                                         # To store image matrix size (N)
    M:            .word 0                                         # To store kernel matrix size (M)
    p:            .word 0                                         # To store padding value (p)
    s:            .word 0                                         # To store stride value (s)
    outputSize:	   .word 0
    image: 	  .float 0.0:49
    kernel: 	   .float 0.0:16
    ouput: 	   .float 0.0:49
    paddedSize:    .word 0					  # To store the size of padded matrix
    newline:      .asciiz "\n"                                    # Newline string for printing
    space:        .asciiz " "                                     # Space between matrix elements
    titleMatrix: .asciiz "The array of image and kernel matrices:\n"                   # Title for the image matrix
    titleImageMatrix: .asciiz "The image matrix is: "
    titleKernelMatrix: .asciiz "The kernel matrix is:\n "
    titlePaddedMatrix: .asciiz "The image matrix after padded is: \n"
    zero:          .float 0.0         # Zero value for padding
    kernelMatrix: .asciiz "The Kernel Matrix"
    startPerformOperation: .asciiz "Start to perform convolutional operation...\n"
    bufferOutput: .space 1024                           # Buffer to store the final formatted result
    digitBufferForIntegerPart: .space 10                              # Temporary buffer for storing digits in reverse order
	num_zero: .float 0.0                           # Constant 100.0 for scaling
	num_10: .float 10.0                                 # Constant 10.0 for scaling
	num_100: .float 100.0    
	num_0.001: .float 0.001

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
    #beq $t2, 10, done_parsing
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
    addi $t0, $t0, 4        # Move pointer after the first row
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
    jal copy_to_image_matrix
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
parse_kernel_matrix:
	addi $t0,$t0,2
	add.s $f0,$f0,$f6 #add fractional part to the integer part
	beq $t3, 1, conToNegNum
	jr $ra
conToNegNum:
	neg.s $f0, $f0
	li $t3, 0
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
########################## COPY TO IMAGE MATRIX ############################
copy_to_image_matrix:
	la $t0, image	#base address of the image matrix
	la $a0, 0($s1)  #the base address that contain 2 matrix
	move $t3,$a0    #base address of 2 matrix
	lw $t1, N  
	mul $t1, $t1, $t1 #$t1 = number of element of image matrix
	#li $t0, 4
	li $t2, 0 #counter
copy_loop:
	bge $t2, $t1, done_copy
	
	lwc1 $f0, 0($t3)
	swc1 $f0, 0($t0)
	
	addi $t3, $t3, 4
	addi $t0, $t0, 4
	addi $t2, $t2, 1
	j copy_loop
done_copy:
	la $t0, image
	lw $t1, N
	mul $t1, $t1, $t1 #size of image
	li $t2, 0 #counter
	
	li $v0, 4
	la $a0, titleImageMatrix
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
print_image_matrix:
	bge $t2, $t1, end_print
	l.s $f12, 0($t0)        # Load a floating-point value from the image matrix
    	li $v0, 2               # Syscall to print a floating-point number
    	syscall                 # Print the floating-point number

    	# Print a space after each element
    	li $v0, 4               # Syscall to print a string
    	la $a0, space           # Load space string
    	syscall                 # Print space

    	# Move to the next element in the matrix
    	addi $t0, $t0, 4        # Move to the next element (4 bytes per float)
    	addi $t2, $t2, 1        # Increment element counter
    	j print_image_matrix     # Continue printing elements
end_print:
	li $v0, 4
	la $a0, newline
	syscall
    	jr $ra
  
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
    la   $t2, image       # Base address of the image matrix

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
    
    li $v0, 4
    la $a0, titlePaddedMatrix
    syscall
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

    la $t1, kernel
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
    li   $v0, 4              # Syscall for printing a string (newline)
    la   $a0, kernelMatrix        # Load the address of the newline string
    syscall
    
    li   $v0, 4              # Syscall for printing a string (newline)
    la   $a0, newline        # Load the address of the newline string
    syscall
    
    la $t7, kernel               
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
    
########################## PERFORM CONVOLUTIONAL OPERATION ##########################

	# Step 1: Load size of padded matrix, kernel size, padding, and stride
    la   $t0, N     # Load address of padded matrix size
    lw   $t1, 0($t0)                 # Load size of padded matrix (N)
    
    la   $t2, M     # Load address of kernel matrix size
    lw   $t3, 0($t2)                 # Load size of kernel matrix (M)
    
    la   $t4, p           # Load address of padding value
    lw   $t5, 0($t4)                 # Load padding value (p)
    
    la   $t6, s            # Load address of stride value
    lw   $s5, 0($t6)                 # Load stride value (s)
    
    addi  $s2, $s2, 0   	#base address of padded matrix is $s2
    la  $s3, kernel 
    # Step 2: Calculate the output matrix dimension
    # Dimension = ((N - sizeOfKernelMatrix) + 2*paddingValue) / stride + 1
    sub  $t8, $t1, $t3               # t8 = sizeOfPaddedMatrix - sizeOfKernelMatrix
    sll  $t9, $t5, 1                 # t9 = 2 * paddingValue (left shift padding by 1)
    add  $t8, $t8, $t9               # t8 = (sizeOfPaddedMatrix - sizeOfKernelMatrix) + 2 * paddingValue
    div  $t8, $t8, $s5               # t8 = t8 / stride
    addi $t8, $t8, 1                 # Add 1 for the output size
    sw   $t8, outputSize             # Store output size (dimension)

    # Step 3: Allocate memory for the output matrix dynamically (dimension * dimension * 4)
    lw   $t9, outputSize             # Load the calculated dimension
    mul  $t9, $t9, $t9               # Calculate total elements: dimension * dimension
    li   $t0, 4                      # Each element is 4 bytes
    mul  $t9, $t9, $t0               # Total bytes to allocate: total elements * 4
    li   $v0, 9                      # System call for sbrk (memory allocation)
    move $a0, $t9                    # Request memory of size in bytes
    syscall
    move $s4, $v0                    # Save base address of dynamically allocated output matrix in $s4
    move $s7, $s4 #use for increase space
    # Step 5: Start the convolution operation loop
    li   $t0, 0                      # i = 0 (initialize output row index)
conv_row_loop:
    lw   $t1, outputSize             # Load output matrix dimension
    bge  $t0, $t1, print_matrix_convol     # If i >= outputSize, exit loop

    li   $t2, 0                      # j = 0 (initialize output column index)
conv_col_loop:
    bge  $t2, $t1, nextRow          # If j >= outputSize, go to next row

    # Calculate starting row and column for this convolution step
    mul  $t3, $t0, $s5               # startRow = i * stride
    mul  $t4, $t2, $s5               # startCol = j * stride

    # Push necessary registers onto the stack
    addi $sp, $sp, -20               # Make space on the stack
    sw $t0, 0($sp)                   # Save $t0 (row index)
    sw $t1, 4($sp) 		#save for the size of output
    sw $t2, 8($sp)                   # Save $t2 (column index)
    sw $t3, 12($sp)                   # Save $t3 (startRow)
    sw $t4, 16($sp)                  # Save $t4 (startCol)

    # Call dotProduct function
    move $a0, $s2                    # Pass base address of padded matrix
    move $a1, $s3                    # Pass base address of kernel matrix
    move $a2, $t3                    # Pass startRow
    move $a3, $t4                    # Pass startCol
    jal  dotProduct                  # Call dotProduct, result will be in $f0

    # Restore the saved registers
    lw $t0, 0($sp)                   # Restore $t0 (row index)
    lw $t1, 4($sp)		#restore $t1 (output size)
    lw $t2, 8($sp)                   # Restore $t2 (column index)
    lw $t3, 12($sp)                   # Restore $t3 (startRow)
    lw $t4, 16($sp)                  # Restore $t4 (startCol)
    addi $sp, $sp, 20                # Deallocate stack space

    # Store the result in output matrix
    swc1 $f0, 0($s7)                 # Store the floating-point result
    addi $s7, $s7, 4                 # Move to next output matrix position
    addi $t2, $t2, 1                 # Increment j
    j    conv_col_loop

nextRow:
    addi $t0, $t0, 1                 # Increment i
    j    conv_row_loop

print_matrix_convol:
    # Reset output matrix base address to start printing
    move $s7, $s4

    # Step 6: Print the output matrix
    li   $t0, 0                      # i = 0 (row index)
print_row_loop:
    lw   $t1, outputSize             # Load output matrix dimension
    bge  $t0, $t1, write_to_file_function  # If i >= outputSize, exit loop

    li   $t2, 0                      # j = 0 (column index)
print_col_loop:
    bge  $t2, $t1, print_newline_convol     # If j >= outputSize, go to next row

    # Load and print the element from output matrix
    lwc1 $f12, 0($s7)                # Load floating-point element from output matrix
    li   $v0, 2                      # System call to print float
    syscall

    # Print a space after each element
    li   $v0, 4                      # System call for printing a string
    la   $a0, space                  # Load address of the space string
    syscall

    # Move to the next element
    addi $s7, $s7, 4                 # Move to the next element (float is 4 bytes)
    addi $t2, $t2, 1                 # Increment column index
    j    print_col_loop

print_newline_convol:
    # Print a newline after each row
    li   $v0, 4                      # System call for printing a string
    la   $a0, newline                # Address of newline string
    syscall
    addi $t0, $t0, 1                 # Increment row index
    j    print_row_loop


#################### WRITE TO FILE #######################



write_to_file_function:
    # Load array information
    move $t0, $s4           # $t0 points to start of float_array
    lw $t1, outputSize            # Load the size of the array into $t1
    mul $t1, $t1, $t1	#outputSize * outputSize
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

end_print_buffer:
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

copyLoop:
    # Check if all digits are copied
    blez $t2, end_write           # If $t2 <= 0, end the function

    # Load a byte from digitBuffer and store it in bufferOutput
    lb $t3, 0($t0)                # Load digit from digitBuffer
    sb $t3, 0($t1)                # Store digit in bufferOutput

    # Advance pointers
    addiu $t0, $t0, 1             # Move to the next digit in digitBuffer
    addiu $t1, $t1, 1             # Move to the next position in bufferOutput
    subi $t2, $t2, 1              # Decrease the count of digits to copy
    j copyLoop                   # Repeat the loop

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
#$end_convolution:
    # Program ends
  #  li   $v0, 10                     # Exit system call
   # syscall
# DotProduct Function
# Arguments:
#   $a0 - base address of padded matrix
#   $a1 - base address of kernel matrix
#   $a2 - startRow
#   $a3 - startColumn
# Returns:
#   $f0 - dot product result
dotProduct:
    # Initialize sum to 0.0
    li   $t5, 0                      # Integer 0
    mtc1 $t5, $f0                    # Move integer 0 to floating-point register $f0
    
    # Kernel index variables
    li   $t6, 0                      # i = 0 for kernel matrix row index
dot_product_row:
    lw   $t1, M      # Load size of kernel matrix (M)
    bge  $t6, $t1, dot_product_done   # If i >= kernel size, finish dot product

    li   $t7, 0                      # j = 0 for kernel matrix column index
dot_product_column:
    bge  $t7, $t1, next_dot_row      # If j >= kernel size, go to next row

    # Calculate padded matrix element address
    lw   $t3, paddedSize      # Load size of padded matrix
    add  $t0, $t6, $a2               # Add startRow to the row index i (padded matrix row)
    add  $t2, $t7, $a3               # Add startCol to the column index j (padded matrix column)
    mul  $t4, $t0, $t3               # Row offset = (i + startRow) * sizeOfPaddedMatrix
    add  $t4, $t4, $t2               # Add column offset (j + startCol)
    sll  $t4, $t4, 2                 # Multiply by 4 (each element is 4 bytes)
    add  $t4, $t4, $a0               # Add base address of padded matrix
    lwc1 $f1, 0($t4)                 # Load floating-point element from padded matrix

    # Calculate kernel matrix element address
    mul  $t5, $t6, $t1               # Row offset = i * sizeOfKernelMatrix (for kernel matrix)
    add  $t5, $t5, $t7               # Add column offset (j) for kernel matrix
    sll  $t5, $t5, 2                 # Multiply by 4 (each element is 4 bytes)
    add  $t5, $t5, $a1               # Add base address of kernel matrix
    lwc1 $f2, 0($t5)                 # Load floating-point element from kernel matrix

    # Perform multiplication and accumulate the sum
    mul.s $f3, $f1, $f2              # Multiply padded matrix and kernel matrix elements
    add.s $f0, $f0, $f3              # Add to the sum

    addi $t7, $t7, 1                 # Increment kernel matrix column index (j)
    j    dot_product_column

next_dot_row:
    addi $t6, $t6, 1                 # Increment kernel matrix row index (i)
    j    dot_product_row

dot_product_done:
    jr   $ra                         # Return from function, result in $f0
    li   $v0, 10                 # Exit the program
    syscall

