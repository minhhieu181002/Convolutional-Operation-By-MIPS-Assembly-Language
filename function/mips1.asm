.data
	#open, close, read and write file
	fout:.asciiz "textout.txt"
	msg1:.asciiz "Before read: "
	msg2:.asciiz "After read: "
	buffer_write:.asciiz "The quick brown fox jumps over the lazy dogs. \n"
	buffer_read:.asciiz "----------------------------------------------- \n"
.text
	#open (for writing) a file that does not exist
	li $v0, 13 #system call for open file
	la $a0, fout # output the file name 
	li $a1, 1 #open for writing (flag write: 1, read: 0)
	li $a2, 0 # mode is ignored
	syscall # open a file (file descriptor returned in $v0)
	move $s6, $v0 #save the file descriptor
	
	########################################
	# Write to the file just open
	li $v0,15 # system call for write a file 
	move $a0, $s6 #file descriptor
	la $a1, buffer_write # address of the buffer to write
	li $a2, 44 #hardcoded buffer length
	syscall #write to file
	
	########################################
	#close the file
	#li $v0,16 #system call for close file
	#move $a0,$s6 #file descriptor to close
	#syscall #close file
	
	#######################################
	#open for reading a file 
	li $v0,13 #system call for open file
	la $a0, fout # input the filename
	li $a1, 0 #open for reading
	li $a2, 0 #mode is ignored 
	syscall # open a file (file descriptor return in $v0
	move $s6, $v0 #save the file descriptor
	
	#####################################
	#read from file 
	li $v0, 14 #system call for read
	move $a0,$s6 #file descriptor
	la $a1, buffer_read #address for buffer read
	li $a2, 44 #hardcoded buffer length
	syscall #read file
	
	#####################################
    # Print the content of buffer_write (before writing)
    li $v0, 4           # System call for print string
    la $a0, msg1        # Load message "Before read: "
    syscall             # Print message

    li $v0, 4           # System call for print string
    la $a0, buffer_write # Load buffer_write to print
    syscall             # Print buffer_write

    #####################################
    # Print the content of buffer_read (after reading)
    li $v0, 4           # System call for print string
    la $a0, msg2        # Load message "After read: "
    syscall             # Print message

    li $v0, 4           # System call for print string
    la $a0, buffer_read # Load buffer_read to print
    syscall             # Print buffer_read
    
    ########################################
    # Close the file after reading
    li $v0, 16          # System call for close file
    move $a0, $s6       # File descriptor to close
    syscall             # Close the file