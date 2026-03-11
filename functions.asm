####################### CSC258H1F Functions Worksheet #########################
######################## Bitmap Display Configuration #########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000
###############################################################################
.data
# The address of the bitmap display. Don't forget to configure and connect it!
ADDR_DSPL:
    .word 0x10008000

# An array of colours (from prior question)
MY_COLOURS:
	.word	0xff0000    # red
	.word	0x00ff00    # green
	.word	0x0000ff    # blue

.text
main:
	li $a0, 8
	li $a1, 10
	jal get_location_address
	
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	li $a2, 5
	jal draw_square
    # TODO
exit:
	li	$v0, 10
	syscall


# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 31, inclusive
#       - y is between 0 and 31, inclusive
get_location_address:
	sll	$a0, $a0, 2
	sll	$a1, $a1, 7

	la $v0, ADDR_DSPL
	lw $v0, 0($v0)
	add $v0, $a0, $v0
	add $v0, $a1, $v0
	
	jr $ra
# TODO


# draw_square(start, colour_address, size)
#   Draw a square that is size x units wide and high on the display using the
#   colour at colour_address and starting from the start address
#
#   Preconditions:
#       - The start address can "accommodate" a size x size square
# TODO
draw_square:
	addi $sp, $sp, 4
	sw $ra, 0($sp)
	
	li $t3, 0
        addi $t5, $t5, 128
        addi $t6, $t6, 0
        add $t6, $t6, $a2
        sll $t6, $t6, 2
        sub $t5, $t5, $t6
draw_square_loop:
    slt $t4, $t3, $a2           # i < width ?
    beq $t4, $0, draw_square_epi  # if not, then done

        jal draw_line
        add $a0, $a0, $t5

    addi $t3, $t3, 1            # i = i + 1
    j draw_square_loop

draw_square_epi:
	lw $ra, 0($sp)
	addi $sp, $sp, -4
    jr $ra
	

# draw_line(start, colour_address, width) -> void
#   Draw a line with width units horizontally across the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_line:
    # Retrieve the colour
    lw $t0, 0($a1)              # colour = *colour_address

    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_line_loop:
    slt $t2, $t1, $a2           # i < width ?
    beq $t2, $0, draw_line_epi  # if not, then done

        sw $t0, 0($a0)          # Paint unit with colour
        addi $a0, $a0, 4        # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    j draw_line_loop

draw_line_epi:
    jr $ra
