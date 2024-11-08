.data
    num: .float 14.56            # The initial float number to be rounded
    positive_round: .float 0.5       # Constant for rounding positive numbers
    negative_round: .float -0.5      # Constant for rounding negative numbers
    hundred: .float 10.0            # Constant 100.0 for scaling
    newline: .asciiz "\n"            # Newline for output formatting
    num_zero: .float	0.0

.text
    .globl main
main:
    # Load the floating-point number to be rounded into $f0
    l.s $f0, num

    # Step 1: Multiply by 100.0 to shift two decimal places
    l.s $f2, hundred                 # Load 100.0 into $f2
    mul.s $f0, $f0, $f2              # $f0 = $f0 * 100.0

    # Step 2: Check if the number is positive or negative
    # Use `c.lt.s` to compare $f0 with 0.0
    l.s $f4, num_zero                    # Load 0.0 into $f4
    c.lt.s $f4, $f0                  # Set condition flag if $f0 < 0 (negative)
    bc1f positive                    # Branch to positive if $f0 >= 0

negative:
    # If the number is negative, subtract 0.5
    l.s $f6, negative_round          # Load -0.5 into $f6
    add.s $f0, $f0, $f6              # $f0 = $f0 - 0.5
    j round_convert                  # Jump to rounding step

positive:
    # If the number is positive, add 0.5
    l.s $f6, positive_round          # Load 0.5 into $f6
    add.s $f0, $f0, $f6              # $f0 = $f0 + 0.5

round_convert:
    # Step 3: Convert to integer to remove the decimal part
    cvt.w.s $f1, $f0                 # Convert $f0 to integer, store in $f1

    # Step 4: Convert back to floating-point
    cvt.s.w $f1, $f1                 # Convert the integer back to float in $f1

    # Step 5: Divide by 100.0 to return to original scale
    div.s $f1, $f1, $f2              # $f1 = $f1 / 100.0

    # Print the result
    li $v0, 2                        # Syscall for printing a float
    mov.s $f12, $f1                  # Move rounded result to $f12 for printing
    syscall

    # Print newline for formatting
    li $v0, 4                        # Syscall for printing a string
    la $a0, newline                  # Load newline address
    syscall

    # Exit program
    li $v0, 10                       # Syscall to exit
    syscall
