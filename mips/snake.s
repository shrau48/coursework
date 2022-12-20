########################################################################
# COMP1521 21T2 -- Assignment 1 -- Snake!
# <https://www.cse.unsw.edu.au/~cs1521/21T2/assignments/ass1/index.html>
#
#
# !!! IMPORTANT !!!
# Before starting work on the assignment, make sure you set your tab-width to 8!
# For instructions, see: https://www.cse.unsw.edu.au/~cs1521/21T2/resources/mips-editors.html
# !!! IMPORTANT !!!
#
#
# This program was written by Shreyas Ananthula (z5360586)
# on 13/07//21
#
# Version 1.0 (2021-06-24): Team COMP1521 <cs1521@cse.unsw.edu.au>
#

	# Requires:
	# - [no external symbols]
	#
	# Provides:
	# - Global variables:
	.globl	symbols
	.globl	grid
	.globl	snake_body_row
	.globl	snake_body_col
	.globl	snake_body_len
	.globl	snake_growth
	.globl	snake_tail

	# - Utility global variables:
	.globl	last_direction
	.globl	rand_seed
	.globl  input_direction__buf

	# - Functions for you to implement
	.globl	main
	.globl	init_snake
	.globl	update_apple
	.globl	move_snake_in_grid
	.globl	move_snake_in_array

	# - Utility functions provided for you
	.globl	set_snake
	.globl  set_snake_grid
	.globl	set_snake_array
	.globl  print_grid
	.globl	input_direction
	.globl	get_d_row
	.globl	get_d_col
	.globl	seed_rng
	.globl	rand_value


########################################################################
# Constant definitions.

N_COLS          = 15
N_ROWS          = 15
MAX_SNAKE_LEN   = N_COLS * N_ROWS

EMPTY           = 0
SNAKE_HEAD      = 1
SNAKE_BODY      = 2
APPLE           = 3

NORTH       = 0
EAST        = 1
SOUTH       = 2
WEST        = 3


########################################################################
# .DATA
	.data

# const char symbols[4] = {'.', '#', 'o', '@'};
symbols:
	.byte	'.', '#', 'o', '@'

	.align 2
# int8_t grid[N_ROWS][N_COLS] = { EMPTY };
grid:
	.space	N_ROWS * N_COLS

	.align 2
# int8_t snake_body_row[MAX_SNAKE_LEN] = { EMPTY };
snake_body_row:
	.space	MAX_SNAKE_LEN

	.align 2
# int8_t snake_body_col[MAX_SNAKE_LEN] = { EMPTY };
snake_body_col:
	.space	MAX_SNAKE_LEN

# int snake_body_len = 0;
snake_body_len:
	.word	0

# int snake_growth = 0;
snake_growth:
	.word	0

# int snake_tail = 0;
snake_tail:
	.word	0

# Game over prompt, for your convenience...
main__game_over:
	.asciiz	"Game over! Your score was "


########################################################################
#
# Your journey begins here, intrepid adventurer!
#
# Implement the following 6 functions, and check these boxes as you
# finish implementing each function
#
#  - [ 1 ] main
#  - [ 1 ] init_snake
#  - [ 1 ] update_apple
#  - [ 1 ] update_snake
#  - [ 1 ] move_snake_in_grid
#  - [ 1 ] move_snake_in_array
#

########################################################################
# .TEXT <main>
	.text
main:

	# Args:     void
	# Returns:
	#   - $v0: int
	#
	# Frame:    $ra, [$s0]
	# Uses:	    [$s0, $a0, $t0, $t1, $t2]
	# Clobbers: [$a0, $t0, $t1, $t2]
	#
	# Locals:
	#   - $s0 = input direction
	#   - $t1 = snake_body_len
	#   - $t2 = score
	#
	# Structure:
	#   main
	#   -> [prologue]
	#   -> body
	#   -> loop_update_snake
	#   -> loop_update_snake_condition
	#   -> [epilogue]

	# Code:
main__prologue:
	    # set up stack frame
	    addiu	$sp, $sp, -8
	    sw	$ra, 4($sp)
	    sw	$s0, 0($sp)

main__body:
	# TODO ... complete this function.

        jal init_snake 		# calling init_snake 

        jal update_apple 	# calling update_apple

loop_update_snake:

		jal print_grid	# calling print_grid 

		jal input_direction 	# calling input_direction, return value at $v0
		move $s0, $v0   	# storing return of input_direction into $s0 = direction

		j loop_update_snake_condition

loop_update_snake_condition:
		
		move $a0, $s0 		# loading direction into $a0 for update_snake	
		jal update_snake	# calling update_snake, return = $v0

		beq $v0, 1, loop_update_snake	# testing if update_snake came back true

		la $t0, snake_body_len 	# storing address of snake_body_len
		lw $t1, 0($t0)		# loading $t1 = snake_body_len

		li $t2, 3
		div $t1, $t2		# snake_body_len / 3

		mflo $t2		# $t2 = score

		la $a0, main__game_over	# printing end of game message string
		li $v0, 4
		syscall

		move $a0, $t2		# printing score
		li $v0, 1
		syscall

		li $a0, '\n'		# printing new line
		li $v0, 11
		syscall

		j main__epilogue

main__epilogue:
	    # tear down stack frame

	    lw	$s0, 0($sp)
	    lw	$ra, 4($sp)
	    addiu 	$sp, $sp, 8

	    li	$v0, 0
	    jr	$ra			# return 0;



########################################################################
# .TEXT <init_snake>
	.text
init_snake:

	# Args:     void
	# Returns:  void
	#
	# Frame:    $ra, [...]
	# Uses:     [$a0, $a1, $a2]
	# Clobbers: [$a0, $a1, $a2]
	#
	# Locals:
	#   - [...]
	#
	# Structure:
	#   init_snake
	#   -> [prologue]
	#   -> body
	#   -> [epilogue]

	# Code:
init_snake__prologue:
	    # set up stack frame
	    addiu	$sp, $sp, -4
	    sw	$ra, 0($sp)

init_snake__body:
	    # TODO ... complete this function.
	    li $a0, 7
	    li $a1, 7
	    li $a2, SNAKE_HEAD		# set_snake(7, 7, SNAKE_BODY)  
	    jal set_snake
        
	    li $a0, 7
	    li $a1, 6
	    li $a2, SNAKE_BODY		# set_snake(7, 6, SNAKE_BODY) 
	    jal set_snake

	    li $a0, 7
	    li $a1, 5
	    li $a2, SNAKE_BODY		# set_snake(7, 5, SNAKE_BODY)
	    jal set_snake

	    li $a0, 7
	    li $a1, 4
	    li $a2, SNAKE_BODY		# set_snake(7, 4, SNAKE_BODY)
	    jal set_snake

	    j init_snake__epilogue

init_snake__epilogue:
	    # tear down stack frame
	    lw	$ra, 0($sp)
	    addiu 	$sp, $sp, 4

	    jr	$ra			# return;



########################################################################
# .TEXT <update_apple>
	.text
update_apple:

	# Args:     void
	# Returns:  void
	#
	# Frame:    $ra, [$s0, $s1]
	# Uses:     [$s0, $s1, $a0, $a1, $t0, $t1, $t2, $v0]
	# Clobbers: [$a0, $a1, $t0, $t1, $v0, $t2 ]
	#
	# Locals:
	#   - $s0 = apple_row	
	#   - $s1 = apple_col
	#   - $t0 = &grid[apple_row][apple_col]
	#   - $t1 = grid[apple_row][apple_col]
	#
	# Structure:
	#   update_apple
	#   -> [prologue]
	#   -> body
	#   -> loop_update_apple
	#   -> loop_update_apple_condtion
	#   -> [epilogue]

	# Code:
update_apple__prologue:
	    # set up stack frame
	    addiu	$sp, $sp, -12
	    sw  $ra, 8($sp)
	    sw  $s1, 4($sp)
	    sw  $s0, 0($sp)

update_apple__body:
	# TODO ... complete this function.

loop_update_apple:

        li $a0, N_ROWS
		jal rand_value	# feeding N_ROWS into ran_values, $s0 = apple_row
		move $s0, $v0

		li $a0, N_COLS
		jal rand_value	# feeding N_COLS into ran_values, $s1 = apple_col
		move $s1, $v0

		j loop_update_apple_condtion

loop_update_apple_condtion:

		move $a0, $s0
		move $a1, $s1		# loading apple_row, apple_col calling grid_address
		jal grid_address

		move $t0, $v0		# $t0 = address of grid[apple_row][apple_col] 

		lb $t1, 0($t0)		# $t1 = grid[apple_row][apple_col]

		bne $t1, EMPTY, loop_update_apple 	# if(grid[apple_row][apple_col] != EMPTY)

		li $t2, APPLE
		sb $t2, 0($t0)

		j update_apple__epilogue

update_apple__epilogue:
	    # tear down stack frame
	    lw      $s0, 0($sp)
	    lw 	$s1, 4($sp)
	    lw	$ra, 8($sp)
	    addiu 	$sp, $sp, 12

	    jr	$ra			# return;


########################################################################
# .TEXT <update_snake>
	.text
update_snake:

	# Args:
	#   - $a0: int direction
	# Returns:
	#   - $v0: bool
	#
	# Frame:    $ra, [$s0, $s1, $s2, $s3,]
	# Uses:     [$a0, $s0, $s1, $s2, $s3, $t1, $t2, $t0, $t3, $t4]
	# Clobbers: [$a0, $t1, $t2, $t0, $t3, $t4]
	#
	# Locals:
	#   - $t0 = d_row
	#   - $t1 = d_col
	#   - $t2 = head_row
	#   - $t3 = head_col
	#   - $s1 = apple
	#   - $s0 = direction
	#   - $s2 = new_head_row
	#   - $s3 = new_head_col
	
	#
	# Structure:
	#   update_snake
	#   -> [prologue]
	#   -> body
	#   -> update_snake_body_continue
	#   -> [epilogue_true or epilougue_false]

	# Code:
update_snake__prologue:
	    # set up stack frame
	    addiu	$sp, $sp, -20
	    sw	$ra, 16($sp)
	    sw	$s0, 12($sp)
	    sw	$s1, 8($sp)
	    sw	$s2, 4($sp)
	    sw	$s3, 0($sp)

update_snake__body:
	# TODO ... complete this function.

    	move $s0, $a0		# $s0 = $a0 (direction)
    	jal get_d_row
    	move $t0, $v0		# calling get_d_row, return in $t0 = d_row

	    move $a0, $s0		# $a0 = $s0 (direction)
	    jal get_d_col
	    move $t1, $v0		# calling get_d_col, return in $t1 = d_col

    	la $s0, snake_body_row	# $t2 = head_row
	    lb $t2, 0($s0)

	    la $s0, snake_body_col	
	    lb $t3, 0($s0)        	# $t3 = head_col

	    move $a0, $t2
	    move $a1, $t3
	    jal grid_address	# getting address of grid[head_row][head_col]

	    move $s0, $v0		# storing addresss in $s0

	    li $t4, SNAKE_BODY
	    sb $t4, 0($s0)		# grid[head_row][head_col] = SNAKE_BODY

	    add $s2, $t2, $t0 	# new_head_row = head_row + d_row = $s2
	    add $s3, $t3, $t1 	# new_head_col = head_col + d_col = $s3

	    blt $s2, 0, update_snake__epilogue_false	# if (new_head_row < 0) return false
	    bge $s2, N_ROWS, update_snake__epilogue_false	# if (new_head_row >= N_ROWS)  return false
	    blt $s3, 0, update_snake__epilogue_false	# if (new_head_col < 0)  return false
	    bge $s3, N_COLS, update_snake__epilogue_false	# if (new_head_col >= N_COLS)  return false

    	move $a0, $s2
    	move $a1, $s3
    	jal grid_address	# getting address of grid[new_head_row][new_head_col]

    	move $s0, $v0		# storing addresss in $s0

    	lb $t0, 0($s0)	# load byte from grid
    	li $t4, APPLE	# load value of APPLE

    	beq $t0, $t4, apple_bool_true  # Checking if apple on grid where snake head is going

		li $s1, 0	# $s1 = apple

		j update_snake__body_continue

apple_bool_true:

		li $s1, 1	# $s1 = apple

		j update_snake__body_continue


update_snake__body_continue:

    	la $t2, snake_body_len
    	lw $t3, 0($t2)		# $s0 = snake_body_len - 1
	    sub $s0, $t3, 1

	    la $t2, snake_tail	# storing new snake_body_len into snake_tail
	    sw $s0, 0($t2)
	 
	    move $a0, $s2
    	move $a1, $s3		# calling move_snake_in_grid(new_head_row, new_head_col)
	    jal move_snake_in_grid


        beq $v0, 0, update_snake__epilogue_false	# if(! move_snake_in_grid(new_head_row, new_head_col)

	    move $a0, $s2
	    move $a1, $s3		# calling move_snake_in_array(new_head_row, new_head_col)
    	jal move_snake_in_array

    	beq $s1, 0, update_snake_epilogue_true	# if(apple)

		la $t0, snake_growth
		lw $t1, 0($t0)
		addi $t1, $t1, 3	# snake_growth += 3;
		sw $t1, 0($t0)

		jal update_apple	# calling update_apple()

    	j update_snake_epilogue_true

update_snake_epilogue_true:
	    # tear down stack frame
	    lw	$s3, 0($sp)
	    lw	$s2, 4($sp)
	    lw	$s1, 8($sp)
	    lw	$s0, 12($sp)
	    lw	$ra, 16($sp)
	    addiu 	$sp, $sp, 20

	    li	$v0, 1
	    jr	$ra			# return true;
    
update_snake__epilogue_false:
	    # tear down stack frame
	    lw	$s3, 0($sp)
	    lw	$s2, 4($sp)
	    lw	$s1, 8($sp)
	    lw	$s0, 12($sp)
	    lw	$ra, 16($sp)
	    addiu 	$sp, $sp, 20

	    li	$v0, 0
	    jr	$ra			# return false;

########################################################################
# .TEXT <move_snake_in_grid>
	.text
move_snake_in_grid:

	# Args:
	#   - $a0: new_head_row
	#   - $a1: new_head_col
	# Returns:
	#   - $v0: bool
	#
	# Frame:    $ra, [$s0]
	# Uses:     [$s0, $t0, $t1, $t3, $t4, $t5, $t6]
	# Clobbers: [$t0, $t1, $t3, $t4, $t5, $t6]
	#
	# Locals:
	#   - $t0 = new_head_row
	#   - $t1 = new_head_col
	# Structure:
	#   move_snake_in_grid
	#   -> [prologue]
	#   -> body
	#   -> snake_growth_else
	#   -> move_snake_in_grid_body_continue
	#   -> [epilogue_true or epilogue_false]

	# Code:
move_snake_in_grid__prologue:
	    # set up stack frame
	    addiu	$sp, $sp, -8
	    sw	$ra, 4($sp)
	    sw	$s0, 0($sp)

move_snake_in_grid__body:
	# TODO ... complete this function.
    	move $t0, $a0		# $t0 = new_head_row
    	move $t1, $a1		# $t1 = new_head_col
	
	    la $t3, snake_growth	
	    lw $t4, 0($t3)		# $t3 = snake_growth

	    ble $t4, 0, snake_growth_else

		la $t5, snake_tail
		lw $t6, 0($t5)		# $t6 = snake_tail
		addi $t6, $t6, 1	# snake_tail++
		sw $t6, 0($t5)

		la $t5, snake_body_len
		lw $t6, 0($t5)		# $t6 = snake_body_len
		addi $t6, $t6, 1	# snake_body_len++
		sw $t6, 0($t5)


		sub $t4, $t4, 1		# snake_growth--
		sw $t4, 0($t3)

		j move_snake_in_grid__body_continue


snake_growth_else:

	    la $t5, snake_tail
    	lw $t6, 0($t5)		# $t6 = snake_tail = int tail

	    la $t5, snake_body_row
    	mul $s0, $t6, 1
	    add $t5, $t5, $s0
	    lb $t3, 0($t5)		# $t3 = tail_row

    	la $t5, snake_body_col 
	    add $t5, $t5, $s0
    	lb $t4, 0($t5)		# $t4 = tail_col

	    move $a0, $t3
    	move $a1, $t4
	    jal grid_address

    	move $t5, $v0		# $t5 = address of grid[tail_row][tail_col]
    	li $t4, EMPTY
	    sb $t4, 0($t5)		# grid[tail_row][tail_col] = EMPTY

	    j move_snake_in_grid__body_continue 

move_snake_in_grid__body_continue:

	    move $a0, $t0
	    move $a1, $t1	# move into args (new_head_row, new_head_col)
	    jal grid_address
	    move $t5, $v0	
	    lb $t2 0($t5)	# $t2 = grid[new_head_row][new_head_col]

	    beq $t2, SNAKE_BODY, move_snake_in_grid__epilogue_false	  # if (grid[new_head_row][new_head_col] == SNAKE_BODY)

	    li $t4, SNAKE_HEAD	
	    sb $t4, 0($t5)

	    j move_snake_in_grid__epilogue_true		# grid[new_head_row][new_head_col] = SNAKE_HEAD

move_snake_in_grid__epilogue_true:
	    # tear down stack frame
    	lw 	$s0, 0($sp)
	    lw	$ra, 4($sp)
    	addiu 	$sp, $sp, 8

	    li	$v0, 1
	    jr	$ra			# return true;

move_snake_in_grid__epilogue_false:
	    # tear down stack frame
	    lw	$s0, 0($sp)
	    lw	$ra, 4($sp)
	    addiu 	$sp, $sp, 8

	    li	$v0, 0
	    jr	$ra			# return false;

########################################################################
# .TEXT <move_snake_in_array>
	.text
move_snake_in_array:

	# Arguments:
	#   - $a0: int new_head_row
	#   - $a1: int new_head_col
	# Returns:  void
	#
	# Frame:    $ra, [$s0, $s1]
	# Uses:     [$s0, $s1, $t9, $t8, $t2, $t3, $t4, $t5, $t6]
	# Clobbers: [$t9, $t8, $t2, $t3, $t4, $t5, $t6]
	#
	# Locals:
	#   - $t9 = new_head_row
	#   - $t8 = new_head_col
	#   - $t1 = snake_tail
	#   - $t5 = snake_body_row[i - 1]
	#   - $t6 = snake_body_col[i - 1]

	#
	# Structure:
	#   move_snake_in_array
	#   -> [prologue]
	#   -> body
	#   -> move_snake)n_array_body_continue
	#   -> [epilogue]

	# Code:
move_snake_in_array__prologue:
	# set up stack frame
	    addiu	$sp, $sp, -12
	    sw	$ra, 8($sp)
	    sw	$s0, 4($sp) 
	    sw	$s1, 0($sp)

move_snake_in_array__body:
	    # TODO ... complete this function 

	    move $t9, $a0		# storing new_head_row = $t9
	    move $t8, $a1		# storing new_head_col = $t8

	    la $s0, snake_tail
	    lw $s1, 0($s0)		# loading snake_tail = $t1


	    loop_move_snake_in_array__body:

	    blt $s1, 1, move_snake_in_array__body_continue

	    sub $t2, $s1, 1		# i - 1 = $t2

	    la $t3, snake_body_row	# load address of snake_body_row
	    la $t4, snake_body_col	# load address of snake_body_col

	    add $t3, $t3, $t2
	    add $t4, $t4, $t2

	    lb $t5, ($t3) 	# $t5 = snake_body_row[i - 1]
	    lb $t6, ($t4)	# $t6 = snake_body_col[i - 1]

	    move $a0, $t5
	    move $a1, $t6		
	    move $a2, $s1		
	    jal set_snake_array	# calling set_snake_array(snake_body_row[i - 1], snake_body_col[i - 1], i)

	    sub $s1, $s1, 1		# i--
	    j loop_move_snake_in_array__body

move_snake_in_array__body_continue:

	    move $a0, $t9
	    move $a1, $t8
	    li $a2, 0	
	    jal set_snake_array	# calling set_snake_array(new_head_row, new_head_col, 0)

	    j move_snake_in_array__epilogue
	
move_snake_in_array__epilogue:
	    # tear down stack frame
	    lw	$s1, 0($sp)
	    lw	$s0, 4($sp)
	    lw	$ra, 8($sp)
	    addiu 	$sp, $sp, 12

	    jr	$ra			# return;


########################################################################
# .TEXT <grid_address>
	.text

grid_address:
	# Arguments:
	#   - $a0: int row
	#   - $a1: int col
	# Returns:  address of grid[row][col]
	# Frame:    $ra, [$s0, $s1, $s3, $s4, $s5, $s6, #s7]
	# Uses:     [$s0, $s1, $s3, $s4, $s5, $s6, #s7]
	# Clobbers: [...]
	#
	# Locals:
	#   - $s0 = row
	#   - $s1 = col
	#   - $s2 = snake_tail
	#   - $s3 = &grid[row][col]
	#   - $s7 = &grid

	#
	# Structure:
	#   -> grid_address
	#   -> grid_address_body
	#   -> grid_address_epilogue

	# Code:

grid_address_body:

    	# set up stack frame
    	addiu	$sp, $sp, -32
    	sw	$ra, 28($sp)
	    sw	$s7, 24($sp)
	    sw	$s6, 20($sp)
	    sw	$s5, 16($sp)
	    sw	$s4, 12($sp)
	    sw	$s3, 8($sp)
	    sw	$s1, 4($sp)
	    sw	$s0, 0($sp)

	# start of function

	    move $s0, $a0	# $s0 = given row
	    move $s1, $a1	# st1 = given col

	    la $s7, grid		# base address of grid = $s7
	    mul $s6, $s0, N_COLS 	# (given row) * (number of cols) = $s6
	    add $s5, $s6, $s1 	# (given row) * (number of cols) + given col = $s5
	    add $s3, $s5, $s7 	# base address of grid + $t6 = address of testing array element

	    # loading address of element to $v0 to return
	    move $v0, $s3

grid_address_epilogue:

	    # tear down stack frame

	    lw	$s7, 24($sp)
	    lw	$s6, 20($sp)
	    lw	$s5, 16($sp)
	    lw	$s4, 12($sp)
	    lw	$s3, 8($sp)
	    lw	$s1, 4($sp)	
	    lw	$s0, 0($sp)
	    lw	$ra, 28($sp)
	    addiu 	$sp, $sp, 32

	    jr	$ra			# return;


########################################################################
####                                                                ####
####        STOP HERE ... YOU HAVE COMPLETED THE ASSIGNMENT!        ####
####                                                                ####
########################################################################

##
## The following is various utility functions provided for you.
##
## You don't need to modify any of the following.  But you may find it
## useful to read through --- you'll be calling some of these functions
## from your code.
##

	.data

last_direction:
	.word	EAST

rand_seed:
	.word	0

input_direction__invalid_direction:
	.asciiz	"invalid direction: "

input_direction__bonk:
	.asciiz	"bonk! cannot turn around 180 degrees\n"

	.align	2
input_direction__buf:
	.space	2



########################################################################
# .TEXT <set_snake>
	.text
set_snake:

	# Args:
	#   - $a0: int row
	#   - $a1: int col
	#   - $a2: int body_piece
	# Returns:  void
	#
	# Frame:    $ra, $s0, $s1
	# Uses:     $a0, $a1, $a2, $t0, $s0, $s1
	# Clobbers: $t0
	#
	# Locals:
	#   - `int row` in $s0
	#   - `int col` in $s1
	#
	# Structure:
	#   set_snake
	#   -> [prologue]
	#   -> body
	#   -> [epilogue]

	# Code:
set_snake__prologue:
	# set up stack frame
	addiu	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$s0, 4($sp)
	sw	$s1,  ($sp)

set_snake__body:
	move	$s0, $a0		# $s0 = row
	move	$s1, $a1		# $s1 = col

	jal	set_snake_grid		# set_snake_grid(row, col, body_piece);

	move	$a0, $s0
	move	$a1, $s1
	lw	$a2, snake_body_len
	jal	set_snake_array		# set_snake_array(row, col, snake_body_len);

	lw	$t0, snake_body_len
	addiu	$t0, $t0, 1
	sw	$t0, snake_body_len	# snake_body_len++;

set_snake__epilogue:
	# tear down stack frame
	lw	$s1,  ($sp)
	lw	$s0, 4($sp)
	lw	$ra, 8($sp)
	addiu 	$sp, $sp, 12

	jr	$ra			# return;



########################################################################
# .TEXT <set_snake_grid>
	.text
set_snake_grid:

	# Args:
	#   - $a0: int row
	#   - $a1: int col
	#   - $a2: int body_piece
	# Returns:  void
	#
	# Frame:    None
	# Uses:     $a0, $a1, $a2, $t0
	# Clobbers: $t0
	#
	# Locals:   None
	#
	# Structure:
	#   set_snake
	#   -> body

	# Code:
	li	$t0, N_COLS
	mul	$t0, $t0, $a0		#  15 * row
	add	$t0, $t0, $a1		# (15 * row) + col
	sb	$a2, grid($t0)		# grid[row][col] = body_piece;

	jr	$ra			# return;



########################################################################
# .TEXT <set_snake_array>
	.text
set_snake_array:

	# Args:
	#   - $a0: int row
	#   - $a1: int col
	#   - $a2: int nth_body_piece
	# Returns:  void
	#
	# Frame:    None
	# Uses:     $a0, $a1, $a2
	# Clobbers: None
	#
	# Locals:   None
	#
	# Structure:
	#   set_snake_array
	#   -> body

	# Code:
	sb	$a0, snake_body_row($a2)	# snake_body_row[nth_body_piece] = row;
	sb	$a1, snake_body_col($a2)	# snake_body_col[nth_body_piece] = col;

	jr	$ra				# return;



########################################################################
# .TEXT <print_grid>
	.text
print_grid:

	# Args:     void
	# Returns:  void
	#
	# Frame:    None
	# Uses:     $v0, $a0, $t0, $t1, $t2
	# Clobbers: $v0, $a0, $t0, $t1, $t2
	#
	# Locals:
	#   - `int i` in $t0
	#   - `int j` in $t1
	#   - `char symbol` in $t2
	#
	# Structure:
	#   print_grid
	#   -> for_i_cond
	#     -> for_j_cond
	#     -> for_j_end
	#   -> for_i_end

	# Code:
	li	$v0, 11			# syscall 11: print_character
	li	$a0, '\n'
	syscall				# putchar('\n');

	li	$t0, 0			# int i = 0;

print_grid__for_i_cond:
	bge	$t0, N_ROWS, print_grid__for_i_end	# while (i < N_ROWS)

	li	$t1, 0			# int j = 0;

print_grid__for_j_cond:
	bge	$t1, N_COLS, print_grid__for_j_end	# while (j < N_COLS)

	li	$t2, N_COLS
	mul	$t2, $t2, $t0		#                             15 * i
	add	$t2, $t2, $t1		#                            (15 * i) + j
	lb	$t2, grid($t2)		#                       grid[(15 * i) + j]
	lb	$t2, symbols($t2)	# char symbol = symbols[grid[(15 * i) + j]]

	li	$v0, 11			# syscall 11: print_character
	move	$a0, $t2
	syscall				# putchar(symbol);

	addiu	$t1, $t1, 1		# j++;

	j	print_grid__for_j_cond

print_grid__for_j_end:

	li	$v0, 11			# syscall 11: print_character
	li	$a0, '\n'
	syscall				# putchar('\n');

	addiu	$t0, $t0, 1		# i++;

	j	print_grid__for_i_cond

print_grid__for_i_end:
	jr	$ra			# return;



########################################################################
# .TEXT <input_direction>
	.text
input_direction:

	# Args:     void
	# Returns:
	#   - $v0: int
	#
	# Frame:    None
	# Uses:     $v0, $a0, $a1, $t0, $t1
	# Clobbers: $v0, $a0, $a1, $t0, $t1
	#
	# Locals:
	#   - `int direction` in $t0
	#
	# Structure:
	#   input_direction
	#   -> input_direction__do
	#     -> input_direction__switch
	#       -> input_direction__switch_w
	#       -> input_direction__switch_a
	#       -> input_direction__switch_s
	#       -> input_direction__switch_d
	#       -> input_direction__switch_newline
	#       -> input_direction__switch_null
	#       -> input_direction__switch_eot
	#       -> input_direction__switch_default
	#     -> input_direction__switch_post
	#     -> input_direction__bonk_branch
	#   -> input_direction__while

	# Code:
input_direction__do:
	li	$v0, 8			# syscall 8: read_string
	la	$a0, input_direction__buf
	li	$a1, 2
	syscall				# direction = getchar()

	lb	$t0, input_direction__buf

input_direction__switch:
	beq	$t0, 'w',  input_direction__switch_w	# case 'w':
	beq	$t0, 'a',  input_direction__switch_a	# case 'a':
	beq	$t0, 's',  input_direction__switch_s	# case 's':
	beq	$t0, 'd',  input_direction__switch_d	# case 'd':
	beq	$t0, '\n', input_direction__switch_newline	# case '\n':
	beq	$t0, 0,    input_direction__switch_null	# case '\0':
	beq	$t0, 4,    input_direction__switch_eot	# case '\004':
	j	input_direction__switch_default		# default:

input_direction__switch_w:
	li	$t0, NORTH			# direction = NORTH;
	j	input_direction__switch_post	# break;

input_direction__switch_a:
	li	$t0, WEST			# direction = WEST;
	j	input_direction__switch_post	# break;

input_direction__switch_s:
	li	$t0, SOUTH			# direction = SOUTH;
	j	input_direction__switch_post	# break;

input_direction__switch_d:
	li	$t0, EAST			# direction = EAST;
	j	input_direction__switch_post	# break;

input_direction__switch_newline:
	j	input_direction__do		# continue;

input_direction__switch_null:
input_direction__switch_eot:
	li	$v0, 17			# syscall 17: exit2
	li	$a0, 0
	syscall				# exit(0);

input_direction__switch_default:
	li	$v0, 4			# syscall 4: print_string
	la	$a0, input_direction__invalid_direction
	syscall				# printf("invalid direction: ");

	li	$v0, 11			# syscall 11: print_character
	move	$a0, $t0
	syscall				# printf("%c", direction);

	li	$v0, 11			# syscall 11: print_character
	li	$a0, '\n'
	syscall				# printf("\n");

	j	input_direction__do	# continue;

input_direction__switch_post:
	blt	$t0, 0, input_direction__bonk_branch	# if (0 <= direction ...
	bgt	$t0, 3, input_direction__bonk_branch	# ... && direction <= 3 ...

	lw	$t1, last_direction	#     last_direction
	sub	$t1, $t1, $t0		#     last_direction - direction
	abs	$t1, $t1		# abs(last_direction - direction)
	beq	$t1, 2, input_direction__bonk_branch	# ... && abs(last_direction - direction) != 2)

	sw	$t0, last_direction	# last_direction = direction;

	move	$v0, $t0
	jr	$ra			# return direction;

input_direction__bonk_branch:
	li	$v0, 4			# syscall 4: print_string
	la	$a0, input_direction__bonk
	syscall				# printf("bonk! cannot turn around 180 degrees\n");

input_direction__while:
	j	input_direction__do	# while (true);



########################################################################
# .TEXT <get_d_row>
	.text
get_d_row:

	# Args:
	#   - $a0: int direction
	# Returns:
	#   - $v0: int
	#
	# Frame:    None
	# Uses:     $v0, $a0
	# Clobbers: $v0
	#
	# Locals:   None
	#
	# Structure:
	#   get_d_row
	#   -> get_d_row__south:
	#   -> get_d_row__north:
	#   -> get_d_row__else:

	# Code:
	beq	$a0, SOUTH, get_d_row__south	# if (direction == SOUTH)
	beq	$a0, NORTH, get_d_row__north	# else if (direction == NORTH)
	j	get_d_row__else			# else

get_d_row__south:
	li	$v0, 1
	jr	$ra				# return 1;

get_d_row__north:
	li	$v0, -1
	jr	$ra				# return -1;

get_d_row__else:
	li	$v0, 0
	jr	$ra				# return 0;



########################################################################
# .TEXT <get_d_col>
	.text
get_d_col:

	# Args:
	#   - $a0: int direction
	# Returns:
	#   - $v0: int
	#
	# Frame:    None
	# Uses:     $v0, $a0
	# Clobbers: $v0
	#
	# Locals:   None
	#
	# Structure:
	#   get_d_col
	#   -> get_d_col__east:
	#   -> get_d_col__west:
	#   -> get_d_col__else:

	# Code:
	beq	$a0, EAST, get_d_col__east	# if (direction == EAST)
	beq	$a0, WEST, get_d_col__west	# else if (direction == WEST)
	j	get_d_col__else			# else

get_d_col__east:
	li	$v0, 1
	jr	$ra				# return 1;

get_d_col__west:
	li	$v0, -1
	jr	$ra				# return -1;

get_d_col__else:
	li	$v0, 0
	jr	$ra				# return 0;



########################################################################
# .TEXT <seed_rng>
	.text
seed_rng:

	# Args:
	#   - $a0: unsigned int seed
	# Returns:  void
	#
	# Frame:    None
	# Uses:     $a0
	# Clobbers: None
	#
	# Locals:   None
	#
	# Structure:
	#   seed_rng
	#   -> body

	# Code:
	sw	$a0, rand_seed		# rand_seed = seed;

	jr	$ra			# return;



########################################################################
# .TEXT <rand_value>
	.text
rand_value:

	# Args:
	#   - $a0: unsigned int n
	# Returns:
	#   - $v0: unsigned int
	#
	# Frame:    None
	# Uses:     $v0, $a0, $t0, $t1
	# Clobbers: $v0, $t0, $t1
	#
	# Locals:
	#   - `unsigned int rand_seed` cached in $t0
	#
	# Structure:
	#   rand_value
	#   -> body

	# Code:
	lw	$t0, rand_seed		#  rand_seed

	li	$t1, 1103515245
	mul	$t0, $t0, $t1		#  rand_seed * 1103515245

	addiu	$t0, $t0, 12345		#  rand_seed * 1103515245 + 12345

	li	$t1, 0x7FFFFFFF
	and	$t0, $t0, $t1		# (rand_seed * 1103515245 + 12345) & 0x7FFFFFFF

	sw	$t0, rand_seed		# rand_seed = (rand_seed * 1103515245 + 12345) & 0x7FFFFFFF;

	rem	$v0, $t0, $a0
	jr	$ra			# return rand_seed % n;

