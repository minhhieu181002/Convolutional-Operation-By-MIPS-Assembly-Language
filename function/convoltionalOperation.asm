    .data
sizeOfPaddedMatrix:  .word 3         # Size of padded matrix (5x5)
sizeOfKernelMatrix:  .word 2         # Size of kernel matrix (2x2)
paddingValue:        .word 0         # No padding in this case
strideValue:         .word 2         # Stride of 1
outputSize:          .word 0         # Output matrix size will be calculated (4x4)
newline:    .asciiz "\n"             # For printing new lines
space:      .asciiz " "              # For printing a space between elements
# Define the padded matrix (5x5)
paddedMatrix:  
    .float -5.6, -1.1, -5.6
    .float -3.3, 1.0, -5.6   # Row 1
    .float -1.1, -5.6, -3.3   # Row 2

# Define the kernel matrix (2x2)
kernelMatrix:  
    .float -1.0 -1.1   # Row 1
    .float -1.1 -1.5   # Row 2

    .text
    .globl main

main:
    # Step 1: Load size of padded matrix, kernel size, padding, and stride
    la   $t0, sizeOfPaddedMatrix     # Load address of padded matrix size
    lw   $t1, 0($t0)                 # Load size of padded matrix (N)
    
    la   $t2, sizeOfKernelMatrix     # Load address of kernel matrix size
    lw   $t3, 0($t2)                 # Load size of kernel matrix (M)
    
    la   $t4, paddingValue           # Load address of padding value
    lw   $t5, 0($t4)                 # Load padding value (p)
    
    la   $t6, strideValue            # Load address of stride value
    lw   $s5, 0($t6)                 # Load stride value (s)
    
    la  $s2, paddedMatrix
    la  $s3, kernelMatrix 
    # Step 2: Calculate the output matrix dimension
    # Dimension = ((sizeOfPaddedMatrix - sizeOfKernelMatrix) + 2*paddingValue) / stride + 1
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
    bge  $t0, $t1, print_matrix      # If i >= outputSize, exit loop

    li   $t2, 0                      # j = 0 (initialize output column index)
conv_col_loop:
    bge  $t2, $t1, next_row          # If j >= outputSize, go to next row

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

next_row:
    addi $t0, $t0, 1                 # Increment i
    j    conv_row_loop

print_matrix:
    # Reset output matrix base address to start printing
    move $s7, $s4

    # Step 6: Print the output matrix
    li   $t0, 0                      # i = 0 (row index)
print_row_loop:
    lw   $t1, outputSize             # Load output matrix dimension
    bge  $t0, $t1, end_convolution   # If i >= outputSize, exit loop

    li   $t2, 0                      # j = 0 (column index)
print_col_loop:
    bge  $t2, $t1, print_newline     # If j >= outputSize, go to next row

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

print_newline:
    # Print a newline after each row
    li   $v0, 4                      # System call for printing a string
    la   $a0, newline                # Address of newline string
    syscall
    addi $t0, $t0, 1                 # Increment row index
    j    print_row_loop

write_to_file:
    
end_convolution:
    # Program ends
    li   $v0, 10                     # Exit system call
    syscall
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
    lw   $t1, sizeOfKernelMatrix      # Load size of kernel matrix (M)
    bge  $t6, $t1, dot_product_done   # If i >= kernel size, finish dot product

    li   $t7, 0                      # j = 0 for kernel matrix column index
dot_product_column:
    bge  $t7, $t1, next_dot_row      # If j >= kernel size, go to next row

    # Calculate padded matrix element address
    lw   $t3, sizeOfPaddedMatrix      # Load size of padded matrix
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
