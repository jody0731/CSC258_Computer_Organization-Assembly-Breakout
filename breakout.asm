################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: ZIXUAN ZENG, 1008533419
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    512
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

.data
	.space	491520 # To prevent bitmap address overflow
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word	0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word	0xffff0000
# The address of colours.
MY_COLOURS:
	.word	0x00ff0000	# red: first row of bricks
	.word	0x00ffff00	# yellow
	.word	0x0000ff00	# green
	.word	0x0000ffff	# tiffany
	.word	0x000000ff	# blue
	.word	0x00ffffff	# white: walls, paddle
	.word	0x00000000	# black
	.word	0x00fffffe	# grey: ball
	.word	0x00555555	# grey: brick
	

##############################################################################
# Mutable Data
##############################################################################
BRICKS:
	.space	600 # store coordinates x, y and remaining lives for all 50 bricks over 5 rows (200*3)
PADDLE:
	.space	4	# store location of paddle
BALL:
	.space	16	# store coordinates x, y and momentum x, y of ball
LIVES:
	.space	4	# store player's remaining attempts

##############################################################################
# Code
##############################################################################
.text
	.globl main

	# Run the Brick Breaker game.
main:	
    # Initialize the game
    jal draw_walls
    
    jal inicialize_bricks
    jal draw_bricks	
    
	li $a0, 206
	li $a1, 248
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 20($a1)
	la $s1, PADDLE
    sw $a0, 0($s1)	# set location
    jal draw_paddle
    
	li $a0, 252
	li $a1, 236
	la $s1, BALL
    sw $a0, 0($s1)	# set coordinate x
    sw $a1, 4($s1)	# set coordinate y
    li $t6, 0	
    sw $t6, 8($s1)	# store momentum x
    li $t6, -1	
    sw $t6, 12($s1)	# store momentum y
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 28($a1)
    jal draw_ball
    
	la $s1, LIVES
	li $t0, 3
	sw $t0, 0($s1)	# inicialize 3 player attempts
    
    li $s5, 0
    li $s7, 3
    li $t9, 0
    
    j game_loop
exit:
	li	$v0, 10
	syscall
	

game_loop:
	# time limit
    addi $a0, $t9, 0
    li $v0, 1
    #syscall
	bge $t9, 16384, game_over # times up after 16384 iterations
	addi $t9, $t9, 1
	# 1a. Check if key has been pressed
    lw $s3, ADDR_KBRD               # $s3 = base address for keyboard
    lw $s4, 0($s3)                  # Load first word from keyboard
    bne $s4, 1, after_key      # If first word 0, skip key pressing instructions
    # 1b. Check which key has been pressed, if first word is 1
    lw $s4, 4($s3)                  # Load second word from keyboard
    beq $s4, 0x71, respond_to_q     # Check if the key q was pressed
    beq $s4, 0x61, respond_to_a     # Check if the key a was pressed, remove current paddle
    beq $s4, 0x64, respond_to_d     # Check if the key d was pressed
    beq $s4, 0x70, respond_to_p     # Check if the key p was pressed
    
	after_key:
	blt $s5, $s7, after_ball_update	#update ball after n loops
    li $s5, 0
    # 2a. Check for collisions
	la $s1, BALL
	lw $t0, 4($s1)	# current ball y
	bge $t0, 242, drop_ball_loop	# ball is dropped when hitting bottom
	
	li $s6, 0
	jal detect_ball_collision
	beq $s6, $0, after_brick_collision
	#####################################################################
	beq $s7, 3, speed_to_five
	li $s7, 3
	j speed_to_three
	speed_to_five:
	li $s7, 5
	speed_to_three:
	
	li $s6, 0
	jal detect_brick_collision
	
	after_brick_collision:
	# 2b. Update locations (ball)
	la $s1, BALL
	lw $a0, 0($s1)	# current ball x
	lw $a1, 4($s1)	# current ball y
	lw $t6, 8($s1)	# momentum x
	lw $t7, 12($s1)	# momentum y
	add $t6, $a0, $t6
	add $t7, $a1, $t7
	jal get_location_address
	addi $a0, $v0, 0
	la $s2, MY_COLOURS
	lw $a1, 24($s2)
	jal draw_ball
	sw $t6, 0($s1)	# update current ball x
	sw $t7, 4($s1)	# update current ball y
	
	# 3. Draw the screen
    # jal draw_bricks 
    after_ball_update: 
    jal draw_time
	addi $s5, $s5, 1
	la $s1, BALL
	lw $a0, 0($s1)	# current ball x
	lw $a1, 4($s1)	# current ball y
	jal get_location_address
	addi $a0, $v0, 0
	la $s1, MY_COLOURS
	lw $a1, 28($s1)
	jal draw_ball	# draw current ball
	la $s1, PADDLE	
	lw $a0, 0($s1)
	la $s1, MY_COLOURS
	lw $a1, 20($s1)
    jal draw_paddle	# draw current paddle
	beq $s6, $0, skip_draw_bricks_jal
	jal draw_bricks
	skip_draw_bricks_jal:
	# 4. Sleep
	li	$v0, 32
	li	$a0, 1
	syscall

    #5. Go back to 1
    j game_loop


    
	
	
# quit_game()
quit_game:
	li $a0, 0
	li $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 24($a1)
	li $a2, 512
	li $a3, 256
	jal draw_rect
	j exit
	
	
# game_over()
game_over:
	li $a0, 0
	li $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 0($a1)
	li $a2, 512
	li $a3, 256
	jal draw_rect
	li	$v0, 32
	li	$a0, 1000
	syscall
	j quit_game

	
# retry_loop()
retry_loop:
	# 1a. Check if key has been pressed
    lw $s3, ADDR_KBRD               # $t0 = base address for keyboard
    # 1b. Check which key has been pressed, if first word is 1
    lw $s4, 4($s3)                  # Load second word from keyboard
    beq $s4, 0x71, respond_to_q     # Check if the key q was pressed
    beq $s4, 0x72, respond_to_r_retry     # Check if the key r was pressed
    b drop_ball_loop
    
    
# drop_ball_loop()
drop_ball_loop:
	la $s1, LIVES
    lw $t0, 0($s1)
    beq $t0, 1, game_over				# Check if player have remaining attempts, game over if none.
	
	# 1a. Check if key has been pressed
    lw $s3, ADDR_KBRD               # $t0 = base address for keyboard
    # 1b. Check which key has been pressed, if first word is 1
    lw $s4, 4($s3)                  # Load second word from keyboard
    beq $s4, 0x71, respond_to_q     # Check if the key q was pressed
    beq $s4, 0x72, respond_to_r_new_attempt     # Check if the key r was pressed
    b drop_ball_loop
	
	
# detect_brick_collision() -> detect if a brick is hit by ball
detect_brick_collision:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $s1, BRICKS	
	li $t2, 0	#i
	la $t7, MY_COLOURS
	lw $t7, 28($t7)
detect_bricks_loop:
    slti $t3, $t2, 50	# i < #of bricks
    beq $t3, $0, detect_bricks_epi  # if not, then done
		lw $t0, 0($s1)	# x
		lw $t1, 4($s1)	# y
		jal brick_peripheral
    addi $s1, $s1, 12
    addi $t2, $t2, 1	# i = i + 1
    j detect_bricks_loop
detect_bricks_epi:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
brick_peripheral:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi, $a0, $t0, 0
	addi, $a1, $t1, -1
	jal get_location_address
	addi $t5, $v0, 0
	li $t4, 0
	brick_peripheral_loop1:
    slti $t8, $t4, 48	# i < #of pixels
    beq $t8, $0, brick_peripheral_epi1  # if not, then done
		lw $t6, 0($t5)
		beq $t6, $t7, brick_collision
	addi $t5, $t5, 4
    addi $t4, $t4, 1	# i = i + 1
    j brick_peripheral_loop1
	brick_peripheral_loop2:
    slti $t8, $t4, 17	# i < #of pixels
    beq $t8, $0, brick_peripheral_epi2  # if not, then done
		lw $t6, 0($t5)
		beq $t6, $t7, brick_collision
	addi $t5, $t5, 2048
    addi $t4, $t4, 1	# i = i + 1
    j brick_peripheral_loop2
	brick_peripheral_loop3:
    slti $t8, $t4, 49	# i < #of pixels
    beq $t8, $0, brick_peripheral_epi3  # if not, then done
		lw $t6, 0($t5)
		beq $t6, $t7, brick_collision
	addi $t5, $t5, -4
    addi $t4, $t4, 1	# i = i + 1
    j brick_peripheral_loop3
	brick_peripheral_loop4:
    slti $t8, $t4, 17	# i < #of pixels
    beq $t8, $0, brick_peripheral_epi4  # if not, then done
		lw $t6, 0($t5)
		beq $t6, $t7, brick_collision
	addi $t5, $t5, -2048
    addi $t4, $t4, 1	# i = i + 1
    j brick_peripheral_loop4
    
	brick_peripheral_epi1:
	li $t4, 0
	j brick_peripheral_loop2
	brick_peripheral_epi2:
	li $t4, 0
	j brick_peripheral_loop3
	brick_peripheral_epi3:
	li $t4, 0
	j brick_peripheral_loop4
	brick_peripheral_epi4:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
brick_collision:
	lw $t8, 8($s1)
	sub $t8, $t8, 1
	sw $t8, 8($s1)
	addi $s6, $s6, 1
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
# detect_ball_collision() -> object the ball collided with
detect_ball_collision:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $s1, BALL	
	lw $t0, 0($s1)	# x
	lw $t1, 4($s1)	# y
	la $s1, MY_COLOURS		
	lw $t5, 24($s1)		
	lw $t7, 20($s1)	
	jal ball_left
	jal ball_right
	jal ball_up
	jal ball_down
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
# ball_left(x, y)
ball_left:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi, $a0, $t0, -1
	addi, $a1, $t1, 0
	jal get_location_address
	addi $t3, $v0, 0
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
ball_right:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi, $a0, $t0, 8
	addi, $a1, $t1, 0
	jal get_location_address
	addi $t3, $v0, 0
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	addi $t3, $t3, 2048
	lw $t6, 0($t3)
	bne $t6, $t5, horizontal_collision
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
ball_up:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi, $a0, $t0, 0
	addi, $a1, $t1, -1
	jal get_location_address
	addi $t3, $v0, 0
	lw $t6, 0($t3)
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	bne $t6, $t5, vertical_collision
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	lw $t6, 0($t3)
	jr $ra
ball_down:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi, $a0, $t0, 0
	addi, $a1, $t1, 8
	jal get_location_address
	addi $t3, $v0, 0
	lw $t6, 0($t3)
	beq $t6, $t7, paddle_collision
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	beq $t6, $t7, paddle_collision
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	beq $t6, $t7, paddle_collision
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	beq $t6, $t7, paddle_collision
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	beq $t6, $t7, paddle_collision
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	beq $t6, $t7, paddle_collision
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	beq $t6, $t7, paddle_collision
	bne $t6, $t5, vertical_collision
	addi $t3, $t3, 4
	lw $t6, 0($t3)
	beq $t6, $t7, paddle_collision
	bne $t6, $t5, vertical_collision
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
horizontal_collision:
	la $s1, BALL
	lw $t4, 8($s1)	#flip momentum x
	sub $t4, $0, $t4
	sw $t4, 8($s1)
	li $s6, 1
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
vertical_collision:
	la $s1, BALL
	lw $t4, 12($s1)	#flip momentum y
	sub $t4, $0, $t4
	sw $t4, 12($s1)
	li $s6, 1
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
# momentum x change when hitting paddle
paddle_collision:
	la $s1, BALL
	lw $t4, 12($s1)	
	sub $t4, $0, $t4
	sw $t4, 12($s1)	#flip momentum y
	
	la $s1, PADDLE	
	lw $t2, 0($s1)
	li $t3, 4
	div $t2, $t3
	mflo $t2
	li $t3, 2048
	div $t2, $t3	#get x of paddle by remainder of div(hi)
	mfhi $t3
	sub $t2, $t0, $t3
	ble $t2, 20, left1
	ble $t2, 40, left2
	ble $t2, 60, mid
	ble $t2, 80, right1
	ble $t2, 100, right2
	left1:
	li $t3, -2
	b paddle_collision_epi
	left2:
	li $t3, -1
	b paddle_collision_epi
	mid:
	li $t3, 0
	b paddle_collision_epi
	right1:
	li $t3, 1
	b paddle_collision_epi
	right2:
	li $t3, 2
	b paddle_collision_epi
paddle_collision_epi:
	la $s1, BALL
	sw $t3, 8($s1)#set momentum x
	li $s6, 1
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
    
# Keyboard responses
# respond_to_p(keypressed)
respond_to_p:
	# 1a. Check if key has been pressed
    lw $s3, ADDR_KBRD               # $t0 = base address for keyboard
    # 1b. Check which key has been pressed, if first word is 1
    lw $s4, 4($s3)                  # Load second word from keyboard
    beq $s4, 0x72, game_loop     # Check if the key r was pressed
    b respond_to_p	
# respond_to_r_retry(keypressed)
respond_to_r_retry:
	li $a0, 0
	li $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 24($a1)
	li $a2, 512
	li $a3, 256
	jal draw_rect
	j exit
# respond_to_r_new_attempt(keypressed)
respond_to_r_new_attempt:
	la $s1, LIVES
    lw $t0, 0($s1)                
      
    addi $a0, $t0, 0
    li $v0, 1
    #syscall
    
    sub $t0, $t0, 1				# Minus 1 to player's remaining attempts
    sw $t0, 0($s1) 
    
	#erase old ball and paddle
	la $s1, BALL
	lw $a0, 0($s1)
	lw $a1, 4($s1)
	jal get_location_address
	la $a1, MY_COLOURS
	lw $a1, 24($a1)
	addi $a0, $v0, 0
	jal draw_ball
	
	la $s1, PADDLE
    lw $a0, 0($s1)	# set location
    jal draw_paddle
	
	#draw new ball and paddle
	li $a0, 206
	li $a1, 248
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 20($a1)
	la $s1, PADDLE
    sw $a0, 0($s1)	# set location
    jal draw_paddle
    
	li $a0, 252
	li $a1, 236
	la $s1, BALL
    sw $a0, 0($s1)	# set coordinate x
    sw $a1, 4($s1)	# set coordinate y
    li $t6, 0	
    sw $t6, 8($s1)	# store momentum x
    li $t6, -1	
    sw $t6, 12($s1)	# store momentum y
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 28($a1)
    jal draw_ball
	j game_loop 
# respond_to_q(keypressed)
respond_to_q:
	j quit_game   
# respond_to_a(keypressed)
respond_to_a:
	la $t6, PADDLE	
	lw $a0, 0($t6)
	ble $a0, 268976208, after_key	# prevent paddle passing through the wall
	la $t7, MY_COLOURS
	lw $a1, 24($t7)
    jal draw_paddle
    addi $a0, $a0, -20
    sw $a0, 0($t6)
    j after_key
# respond_to_d(keypressed)
respond_to_d:
	la $t6, PADDLE	
	lw $a0, 0($t6)
	bgt $a0, 268977692, after_key	# prevent paddle passing through the wall
	la $t7, MY_COLOURS
	lw $a1, 24($t7)
    jal draw_paddle
    addi $a0, $a0, 20
    sw $a0, 0($t6)
    j after_key
    
    
# draw_time()
draw_time:   
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a0, 0
	li $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 0($a1)
	addi $t1, $t9, 0
	li $t2, 32
	div $t1, $t2
	mflo $a2
	li $a3, 8
	jal draw_rect
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
    
    
# draw_ball(start, color)
#   Draw ball.
draw_ball:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $t5, $a0, 0
	addi $a0, $a0, 0
	li $a2, 8
	li $a3, 8
	jal draw_rect
	addi $a0, $t5, 0
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# draw_paddle(start, colour)
#   Draw paddle.
draw_paddle:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a2, 100
	li $a3, 8
	jal draw_rect # paddle
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
    
    
# inicialize_bricks()
inicialize_bricks:
	la $s1, BRICKS
	addi $a0, $s1, 0
	li $v0, 1
	#syscall
inicialize_bricks_loop:
    slti $t5, $t6, 50	# i < #of bricks
    beq $t5, $0, inicialize_bricks_epi  # if not, then done
    beq $t6, 42, unbreakable_brick	#breakable bricks skip
    beq $t6, 47, unbreakable_brick
    li $s2, 2
    sw $s2, 8($s1)	# set lives to 1
    b after_set_brick_lives
	unbreakable_brick:
    li $s2, 100000
    sw $s2, 8($s1)	# set lives to infinity(100000)
	after_set_brick_lives:
    addi $s1, $s1, 12
    addi $t6, $t6, 1	# i = i + 1
    b inicialize_bricks_loop
inicialize_bricks_epi:
	jr $ra
    

# draw_bricks()
#   Draw bricks, record location and initialize each one's life count to 1.
draw_bricks:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $s1, BRICKS
	li $s3, 16
	
    # Iterate 10 times, drawing each brick in red
    li $t6, 0	# i = 0
	li $a0, 16
	li $a1, 48
	addi $s4, $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 0($a1)
	li $a2, 48
	li $a3, 16
	jal draw_bricks_jal
    # Iterate 10 times, drawing each brick in yellow
    li $t6, 0	# i = 0
	li $a0, 16
	li $a1, 64
	addi $s4, $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 4($a1)
	li $a2, 48
	li $a3, 16
	jal draw_bricks_jal
    # Iterate 10 times, drawing each brick in green
    li $t6, 0	# i = 0
	li $a0, 16
	li $a1, 80
	addi $s4, $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 8($a1)
	li $a2, 48
	li $a3, 16
	jal draw_bricks_jal
    # Iterate 10 times, drawing each brick in tiffany
    li $t6, 0	# i = 0
	li $a0, 16
	li $a1, 96
	addi $s4, $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 12($a1)
	li $a2, 48
	li $a3, 16
	jal draw_bricks_jal
    # Iterate 10 times, drawing each brick in blue
    li $t6, 0	# i = 0
	li $a0, 16
	li $a1, 112
	addi $s4, $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 16($a1)
	li $a2, 48
	li $a3, 16
	jal draw_bricks_jal
	# add unbreakable bricks
	li $a0, 112
	li $a1, 112
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 20($a1)
    jal draw_rect
	li $a0, 352
	li $a1, 112
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 20($a1)
    jal draw_rect
	
    j draw_bricks_epi
draw_bricks_jal:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal draw_bricks_loop
draw_bricks_loop:
    slti $t5, $t6, 10	# i < #of bricks in this row
    lw $t7, 8($s1) 
    beq $t5, $0, draw_bricks_epi  # if not, then done
    addi $t8, $a1, 0	#save color
    bgt $t7, 1, after_turn_grey
	la $a1, MY_COLOURS
	lw $a1, 32($a1)
    after_turn_grey:
    bgt $t7, $0, after_delete_brick  # if brick is alive, then skip
	la $a1, MY_COLOURS
	lw $a1, 24($a1)
	b after_delete_brick
    after_delete_brick:
        jal draw_rect
    	sw $s3, 0($s1)	# set coordinate x
    	sw $s4, 4($s1)	# set coordinate y
        addi $a0, $a0, 192
        addi $s3, $s3, 48
    li $s2, 1
    addi $s1, $s1, 12
    addi $t6, $t6, 1	# i = i + 1
    addi $a1, $t8, 0	#restore color
    j draw_bricks_loop
draw_bricks_epi:
	li $s3, 16
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
    
    
# draw_walls()
#   Draw walls.
draw_walls:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a0, 0
	li $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 20($a1)
	li $a2, 512
	li $a3, 16
	jal draw_rect # top wall
	
	li $a2, 16
	li $a3, 256
	addi $a0, $v0, 0
	jal draw_rect # left wall
	
	li $a0, 496
	li $a1, 0
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, MY_COLOURS
	lw $a1, 20($a1)
	li $a2, 16
	li $a3, 256
	jal draw_rect # right wall
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
    

# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 31, inclusive
#       - y is between 0 and 31, inclusive
get_location_address:
	sll	$a0, $a0, 2
	sll	$a1, $a1, 11
	la $v0, ADDR_DSPL
	lw $v0, 0($v0)
	add $v0, $a0, $v0
	add $v0, $a1, $v0
	jr $ra

# draw_rect(start, colour, x(width), y(height)) -> void
#   Draw a rectangle that is x units wide and y units high on the display using the
#   colour
#
#   Preconditions:
#       - The start address can "accommodate" a size x size square
draw_rect:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	
	li $t0, 0
draw_rect_loop:
    slt $t1, $t0, $a3           # i < height
    beq $t1, $0, draw_rect_epi  # if not, then done
        jal draw_line
        add $a0, $a0, 2048
    addi $t0, $t0, 1            # i = i + 1
    j draw_rect_loop
draw_rect_epi:
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
    jr $ra
	

# draw_line(start, colour, width) -> void
#   Draw a line with width units horizontally across the display using the
#   colour.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_line:
	addi $sp, $sp, -4
	sw $a0, 0($sp)
    # Iterate $a2 times, drawing each unit in the line
    li $t3, 0                   # i = 0
draw_line_loop:
    slt $t4, $t3, $a2           # i < width ?
    beq $t4, $0, draw_line_epi  # if not, then done
        sw $a1, 0($a0)          # Paint unit with colour
        addi $a0, $a0, 4        # Go to next unit
    addi $t3, $t3, 1            # i = i + 1
    j draw_line_loop
draw_line_epi:
	lw $a0, 0($sp)
	addi $sp, $sp, 4
    jr $ra
