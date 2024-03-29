# Instructions: 
#   Connect bitmap display:
#         set pixel dim to 16x16
#         set display width to 256
#	  set display height to 512
#	use $gp as base address
#   Connect keyboard and run
#	use a (left), d (right), s (down), r (rotate), space (exit, only in game over screen)
#	all other keys are ignored

#	Rotation/Spawning rules obtained from https://tetris.fandom.com/wiki/SRS

.eqv WIDTH 32
.eqv HEIGHT 32
.eqv RED	0x00FF0000
.eqv WHITE	0x00FFFFFF
.eqv YELLOW	0x00FFFF00
.eqv LIGHT_GRAY 0x00E0E0E0
.eqv MID_GRAY	0x009F9F9F
.eqv GRAY	0x004F4F4F
.eqv BLACK	0x00000000
.eqv COLOR_O	0x00F0F000
.eqv COLOR_I	0x0000F0F0
.eqv COLOR_T	0x00A000F0
.eqv COLOR_S	0x0000F000
.eqv COLOR_Z	0x00F00000
.eqv COLOR_L	0x00F0A000
.eqv COLOR_J	0x000000F0

.data
OFFSET_1000:		.word	0
OFFSET_100:		.word	0
OFFSET_10:		.word	0
OFFSET_1:		.word	0
MAX_PIECE_OFFSET:	.word	0
.text

# game loop:
# 	Spawn piece if no piece falling, otherwise move piece down by one
# 		If moving piece down results in it intersecting with floor, solidify the piece
# 	check and deal with any lines that are complete
#	Check if player is dead
#	Handle player input
# 	increment main counter
	
# $s0: main counter used for timing everything, tickrate of game is ~100 tps
# $s1: current piece that is falling (0 - 6) in order (O, I, T, S, Z, L, J) 
# $s2: current piece rotation status
# $s3: current piece $gp offset
# $s4: score
# $s5: piece fall rate (number of ticks between piece drops)
# $s6: game state flag, 0 is playing, 1 is game over
# $s7: piece is falling flag (0 if no piece is falling, 1 if piece is falling
main:	
	jal init
	game_loop:
	bnez	$s7, piece_still_falling
	jal	spawn_piece
	piece_still_falling:
	
	jal	drop_piece	# drops piece, clears lines, updates score, check for game over
	beq	$s6, 1, game_over
	
	jal	handle_input	# handles rotations and sideways shifts
	# sleep for 10 milliseconds
	li	$v0, 32
	li	$a0, 10
	syscall
	add	$s0, $s0, 1
	
	j	game_loop
	
exit:
	li	$t0, 0
	move	$t1, $gp
	clear_screen:
		sw	$zero, ($t1)
		add	$t1, $t1, 4
		add	$t0, $t0, 1
		blt	$t0, 512, clear_screen
	li	$v0, 10
 	syscall

update_speed:
	blt	$s4, 10, generic_function_return
	blt	$s4, 20, speed_45
	blt	$s4, 30, speed_40
	blt	$s4, 40, speed_35
	blt	$s4, 50, speed_30
	blt	$s4, 75, speed_25
	blt	$s4, 100, speed_20
	blt	$s4, 150, speed_15
	bge	$s4, 150, speed_10
	
	speed_45:
		li	$s5, 45
		jr	$ra
	speed_40:
		li	$s5, 40
		jr	$ra
	speed_35:
		li	$s5, 35
		jr	$ra
	speed_30:
		li	$s5, 30
		jr	$ra
	speed_25:
		li	$s5, 25
		jr	$ra
	speed_20:
		li	$s5, 20
		jr	$ra
	speed_15:
		li	$s5, 15
		jr	$ra
	speed_10:
		li	$s5, 10
		jr	$ra
	
update_score:
	add	$sp, $sp, -4
	sw	$ra, ($sp)
	
	.macro clear_number(%gp_offset)
		li	$t9, 0
		move	$t8, %gp_offset
		clear_number_loop:
			sw	$zero, ($t8)
			sw	$zero, 4($t8)
			sw	$zero, 8($t8)
			add	$t8, $t8, 64
			add	$t9, $t9, 1
		blt	$t9, 5, clear_number_loop
	.end_macro
	
	.macro update_number(%gp_offset, %number)
		clear_number(%gp_offset)
		move	$a0, %gp_offset
		li	$a1, YELLOW
		
		beq	%number, 0, update_0
		beq	%number, 1, update_1
		beq	%number, 2, update_2
		beq	%number, 3, update_3
		beq	%number, 4, update_4
		beq	%number, 5, update_5
		beq	%number, 6, update_6
		beq	%number, 7, update_7
		beq	%number, 8, update_8
		beq	%number, 9, update_9
		
		update_0:
			jal	draw_zero
			j	done_updating
		update_1:
			jal	draw_one
			j	done_updating
		update_2:
			jal	draw_two
			j	done_updating
		update_3:
			jal	draw_three
			j	done_updating
		update_4:
			jal	draw_four
			j	done_updating
		update_5:
			jal	draw_five
			j	done_updating
		update_6:
			jal	draw_six
			j	done_updating
		update_7:
			jal	draw_seven
			j	done_updating
		update_8:
			jal	draw_eight
			j	done_updating
		update_9:
			jal	draw_nine
			j	done_updating
		done_updating:
	.end_macro
	move	$t2, $s4
	rem	$t1, $t2, 10
	lw	$t0, OFFSET_1
	update_number($t0, $t1)
	add	$t0, $t0, -16
	sub	$t2, $t2, $t1
	div	$t2, $t2, 10
	
	rem	$t1, $t2, 10
	lw	$t0, OFFSET_10
	update_number($t0, $t1)
	add	$t0, $t0, -16
	sub	$t2, $t2, $t1
	div	$t2, $t2, 10
	
	rem	$t1, $t2, 10
	lw	$t0, OFFSET_100
	update_number($t0, $t1)
	add	$t0, $t0, -16
	sub	$t2, $t2, $t1
	div	$t2, $t2, 10
	
	rem	$t1, $t2, 10
	lw	$t0, OFFSET_1000
	update_number($t0, $t1)
	
	lw	$ra, ($sp)
	add	$sp, $sp, 4
	jr 	$ra
	
game_over:
	add	$sp, $sp, -4
	sw	$ra, ($sp)
	
	li	$t0, 0
	move	$t1, $gp
	board_clearing_loop:
		sw	$zero, ($t1)
		add	$t1, $t1, 4
		add	$t0, $t0, 1
		blt	$t0, 320, board_clearing_loop
	
	move	$t1, $gp
	add	$t1, $t1, 256
	
	move	$a0, $t1
	li	$a1, RED
	jal 	draw_G
	add	$t1, $t1, 16
	move	$a0, $t1
	li	$a1, RED
	jal	draw_A
	add	$t1, $t1, 16
	move	$a0, $t1
	li	$a1, RED
	jal	draw_M
	add	$t1, $t1, 16
	move	$a0, $t1
	li	$a1, RED
	jal	draw_E
	
	add	$t1, $t1, 464
	
	move	$a0, $t1
	li	$a1, RED
	jal 	draw_O
	add	$t1, $t1, 16
	move	$a0, $t1
	li	$a1, RED
	jal	draw_V
	add	$t1, $t1, 16
	move	$a0, $t1
	li	$a1, RED
	jal	draw_E
	add	$t1, $t1, 16
	move	$a0, $t1
	li	$a1, RED
	jal	draw_R
	
	wait_for_end:
	jal	handle_input
	j	wait_for_end
	
# loop 0: for each row in board (starting from bottom):
#	loop 1: for each square in row:
#		if square is 0, jump to loop 3
#	loop 2: for each square in row:
#		set square to 0
#	j loop 0
#	loop 3: for each square in row:
#		move down square

# $t0: outer loop counter
# $t1: inner loops counter
# $t7: row lowering offset
# $t8: current offset decrementor
# $t9: current offset of the end of the current row
check_line_completion:
	add	$sp, $sp, -4
	sw	$ra, ($sp)

	lw	$t9, MAX_PIECE_OFFSET
	li	$t0, 0	
	li	$t1, 0	
	li	$t7, 0
	
	row_iteration_loop:
		add	$t0, $t0, 1
		
		move	$t8, $t9
		li	$t1, 0	
		row_completion_check_loop:
			add	$t8, $t8, -4
			lw	$t2, ($t8)
			beqz	$t2, lower_row
			
			add	$t1, $t1, 1
			blt	$t1, 10, row_completion_check_loop
		
		delete_row:
			move	$t8, $t9
			li	$t1, 0
			row_deletion_loop:
				add	$t8, $t8, -4
				sw	$zero, ($t8)
				
				add	$t1, $t1, 1
				blt	$t1, 10, row_deletion_loop		
			add	$t9, $t9, -64
			add	$t7, $t7, 64
			blt	$t0, 20, row_iteration_loop
			
			# score
			beqz	$t7, generic_function_return_stack_pop
			
			srl	$t7, $t7, 6
			add	$t7, $t7, -1
			li	$t6, 1
			sllv	$t7, $t6, $t7
			add	$s4, $s4, $t7
			jal	update_score
			jal	update_speed
			
			lw	$ra, ($sp)
			add	$sp, $sp, 4
			jr 	$ra
			
		lower_row:
			beqz	$t7, skip_row_lowering
			move	$t8, $t9
			li	$t1, 0
			row_lowering_loop:
				add	$t8, $t8, -4
				lw	$t3, ($t8)	# save current pixel
				sw	$zero, ($t8)	# set pixel to 0
				add	$t8, $t8, $t7	# go to next row
				sw	$t3, ($t8)	# store pixel
				sub	$t8, $t8, $t7	# go back to previous row
					
				add	$t1, $t1, 1
				blt	$t1, 10, row_lowering_loop
		
			skip_row_lowering:
			add	$t9, $t9, -64
				
			blt	$t0, 20, row_iteration_loop
			
			# score
			beqz	$t7, generic_function_return_stack_pop
			
			srl	$t7, $t7, 6
			add	$t7, $t7, -1
			li	$t6, 1
			sllv	$t7, $t6, $t7
			add	$s4, $s4, $t7
			jal	update_score
			jal	update_speed
			
			lw	$ra, ($sp)
			add	$sp, $sp, 4
			jr 	$ra
			
handle_input:
	
	lw	$t0, 0xffff0000
    	beq	$t0, 0, generic_function_return
    	
	add	$sp, $sp, -4
	sw	$ra, ($sp)

	# process input
	lw 	$t0, 0xffff0004
	beq	$s6, 1, game_over_input_handler
	beq	$t0, 115, input_down 	# input s
	beq	$t0, 97, input_left  	# input a
	beq	$t0, 100, input_right	# input d
	beq	$t0, 114, input_rotate	# inpur r
	
	.macro	shift_piece(%draw_function, %color, %shift_offset)
		move	$a0, $s3
		li	$a1, BLACK
		move	$a2, $s2
		jal	%draw_function
		add	$s3, $s3, %shift_offset
		move	$a0, $s3
		li	$a1, %color
		jal	%draw_function
		lw	$ra, ($sp)
		add	$sp, $sp, 4
		jr 	$ra
	.end_macro
	
	.macro	side_is_occupied(%side, %block_offset, %block_offset_shift_amt)
		add	%block_offset, %block_offset, %block_offset_shift_amt
		lw	$t9, %side(%block_offset)
		bnez	$t9, generic_function_return_stack_pop
	.end_macro
	
	input_down:
		li	$s0, -1
		lw	$ra, ($sp)
		add	$sp, $sp, 4
		jr 	$ra
		
	input_left:
		move	$t0, $s3
		beq	$s1, 0, shift_left_O
		beq	$s1, 1, shift_left_I
		beq	$s1, 2, shift_left_T
		beq	$s1, 3, shift_left_S
		beq	$s1, 4, shift_left_Z
		beq	$s1, 5, shift_left_L
		beq	$s1, 6, shift_left_J
		
		shift_left_O:
			side_is_occupied(-4, $t0, 0)
			side_is_occupied(-4, $t0, 64)
			shift_piece(draw_piece_O, COLOR_O, -4)
			
		shift_left_I:
			beq	$s2, 1, shift_left_I_rotation_1
			beq	$s2, 0, shift_left_I_rotation_0
			beq	$s2, 3, shift_left_I_rotation_3
			
			# horizontal I
			shift_left_I_rotation_2:
				add	$t0, $t0, 64
			shift_left_I_rotation_0:
				side_is_occupied(-4, $t0, 64)
				shift_piece(draw_piece_I, COLOR_I, -4)
			
			# vertical I
			shift_left_I_rotation_1:
				add	$t0, $t0, 4
			shift_left_I_rotation_3:
				side_is_occupied(-4, $t0, 4)
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 64)
				shift_piece(draw_piece_I, COLOR_I, -4)
			
		shift_left_T:
			beq	$s2, 1, shift_left_T_rotation_1
			beq	$s2, 2, shift_left_T_rotation_2
			beq	$s2, 3, shift_left_T_rotation_3
			
			shift_left_T_rotation_0:
				side_is_occupied(-4, $t0, 4)
				side_is_occupied(-4, $t0, 60)
				shift_piece(draw_piece_T, COLOR_T, -4)

			shift_left_T_rotation_1:
				side_is_occupied(-4, $t0, 4)
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 64)
				shift_piece(draw_piece_T, COLOR_T, -4)
				
			shift_left_T_rotation_2:
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 68)
				shift_piece(draw_piece_T, COLOR_T, -4)
				
			shift_left_T_rotation_3:
				side_is_occupied(-4, $t0, 4)
				side_is_occupied(-4, $t0, 60)
				side_is_occupied(-4, $t0, 68)
				shift_piece(draw_piece_T, COLOR_T, -4)
			
		shift_left_S:
			beq	$s2, 1, shift_left_S_rotation_1
			beq	$s2, 0, shift_left_S_rotation_0
			beq	$s2, 3, shift_left_S_rotation_3
			
			shift_left_S_rotation_2:
				add	$t0, $t0, 64
			shift_left_S_rotation_0:
				side_is_occupied(-4, $t0, 4)
				side_is_occupied(-4, $t0, 60)
				shift_piece(draw_piece_S, COLOR_S, -4)
				
			shift_left_S_rotation_1:
				add	$t0, $t0, 4
			shift_left_S_rotation_3:
				side_is_occupied(-4, $t0, 0)
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 68)
				shift_piece(draw_piece_S, COLOR_S, -4)
				
		shift_left_Z:
			beq	$s2, 1, shift_left_Z_rotation_1
			beq	$s2, 0, shift_left_Z_rotation_0
			beq	$s2, 3, shift_left_Z_rotation_3
			
			shift_left_Z_rotation_2:
				add	$t0, $t0, 64
			shift_left_Z_rotation_0:
				side_is_occupied(-4, $t0, 0)
				side_is_occupied(-4, $t0, 68)
				shift_piece(draw_piece_Z, COLOR_Z, -4)
				
			shift_left_Z_rotation_1:
				add	$t0, $t0, 4
			shift_left_Z_rotation_3:
				side_is_occupied(-4, $t0, 4)
				side_is_occupied(-4, $t0, 60)
				side_is_occupied(-4, $t0, 64)
				shift_piece(draw_piece_Z, COLOR_Z, -4)
		shift_left_L:
			beq	$s2, 1, shift_left_L_rotation_1
			beq	$s2, 2, shift_left_L_rotation_2
			beq	$s2, 3, shift_left_L_rotation_3
			
			shift_left_L_rotation_0:
				side_is_occupied(-4, $t0, 8)
				side_is_occupied(-4, $t0, 56)
				shift_piece(draw_piece_L, COLOR_L, -4)
			shift_left_L_rotation_1:
				side_is_occupied(-4, $t0, 4)
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 64)
				shift_piece(draw_piece_L, COLOR_L, -4)
			shift_left_L_rotation_2:
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 64)
				shift_piece(draw_piece_L, COLOR_L, -4)
			shift_left_L_rotation_3:
				side_is_occupied(-4, $t0, 0)
				side_is_occupied(-4, $t0, 68)
				side_is_occupied(-4, $t0, 64)
				shift_piece(draw_piece_L, COLOR_L, -4)
		shift_left_J:
			beq	$s2, 1, shift_left_J_rotation_1
			beq	$s2, 2, shift_left_J_rotation_2
			beq	$s2, 3, shift_left_J_rotation_3
			
			shift_left_J_rotation_0:
				side_is_occupied(-4, $t0, 0)
				side_is_occupied(-4, $t0, 64)
				shift_piece(draw_piece_J, COLOR_J, -4)
			shift_left_J_rotation_1:
				side_is_occupied(-4, $t0, 4)
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 64)
				shift_piece(draw_piece_J, COLOR_J, -4)
			shift_left_J_rotation_2:
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 72)
				shift_piece(draw_piece_J, COLOR_J, -4)
			shift_left_J_rotation_3:
				side_is_occupied(-4, $t0, 4)
				side_is_occupied(-4, $t0, 64)
				side_is_occupied(-4, $t0, 60)
				shift_piece(draw_piece_J, COLOR_J, -4)
				
	input_right:
		move	$t0, $s3
		beq	$s1, 0, shift_right_O
		beq	$s1, 1, shift_right_I
		beq	$s1, 2, shift_right_T
		beq	$s1, 3, shift_right_S
		beq	$s1, 4, shift_right_Z
		beq	$s1, 5, shift_right_L
		beq	$s1, 6, shift_right_J
		
		shift_right_O:
			side_is_occupied(4, $t0, 4)
			side_is_occupied(4, $t0, 64)
			shift_piece(draw_piece_O, COLOR_O, 4)
			
		shift_right_I:
			
			beq	$s2, 1, shift_right_I_rotation_1
			beq	$s2, 0, shift_right_I_rotation_0
			beq	$s2, 3, shift_right_I_rotation_3
			
			# horizontal I
			shift_right_I_rotation_2:
				add	$t0, $t0, 64
			shift_right_I_rotation_0:
				side_is_occupied(4, $t0, 76)
				shift_piece(draw_piece_I, COLOR_I, 4)
			
			# vertical I
			shift_right_I_rotation_1:
				add	$t0, $t0, 4
			shift_right_I_rotation_3:
				side_is_occupied(4, $t0, 4)
				side_is_occupied(4, $t0, 64)
				side_is_occupied(4, $t0, 64)
				side_is_occupied(4, $t0, 64)
				shift_piece(draw_piece_I, COLOR_I, 4)
			
		shift_right_T:
			beq	$s2, 1, shift_right_T_rotation_1
			beq	$s2, 2, shift_right_T_rotation_2
			beq	$s2, 3, shift_right_T_rotation_3
			
			shift_right_T_rotation_0:
				side_is_occupied(4, $t0, 4)
				side_is_occupied(4, $t0, 68)
				shift_piece(draw_piece_T, COLOR_T, 4)

			shift_right_T_rotation_1:
				side_is_occupied(4, $t0, 4)
				side_is_occupied(4, $t0, 68)
				side_is_occupied(4, $t0, 60)
				shift_piece(draw_piece_T, COLOR_T, 4)
				
			shift_right_T_rotation_2:
				side_is_occupied(4, $t0, 72)
				side_is_occupied(4, $t0, 60)
				shift_piece(draw_piece_T, COLOR_T, 4)
				
			shift_right_T_rotation_3:
				side_is_occupied(4, $t0, 4)
				side_is_occupied(4, $t0, 64)
				side_is_occupied(4, $t0, 64)
				shift_piece(draw_piece_T, COLOR_T, 4)
			
		shift_right_S:
			beq	$s2, 1, shift_right_S_rotation_1
			beq	$s2, 0, shift_right_S_rotation_0
			beq	$s2, 3, shift_right_S_rotation_3
			
			shift_right_S_rotation_2:
				add	$t0, $t0, 64
			shift_right_S_rotation_0:
				side_is_occupied(4, $t0, 8)
				side_is_occupied(4, $t0, 60)
				shift_piece(draw_piece_S, COLOR_S, 4)
				
			shift_right_S_rotation_1:
				add	$t0, $t0, 4
			shift_right_S_rotation_3:
				side_is_occupied(4, $t0, 0)
				side_is_occupied(4, $t0, 68)
				side_is_occupied(4, $t0, 64)
				shift_piece(draw_piece_S, COLOR_S, 4)
				
		shift_right_Z:
			beq	$s2, 1, shift_right_Z_rotation_1
			beq	$s2, 0, shift_right_Z_rotation_0
			beq	$s2, 3, shift_right_Z_rotation_3
			
			shift_right_Z_rotation_2:
				add	$t0, $t0, 64
			shift_right_Z_rotation_0:
				side_is_occupied(4, $t0, 4)
				side_is_occupied(4, $t0, 68)
				shift_piece(draw_piece_Z, COLOR_Z, 4)
				
			shift_right_Z_rotation_1:
				add	$t0, $t0, 4
			shift_right_Z_rotation_3:
				side_is_occupied(4, $t0, 4)
				side_is_occupied(4, $t0, 64)
				side_is_occupied(4, $t0, 60)
				shift_piece(draw_piece_Z, COLOR_Z, 4)
		shift_right_L:
			beq	$s2, 1, shift_right_L_rotation_1
			beq	$s2, 2, shift_right_L_rotation_2
			beq	$s2, 3, shift_right_L_rotation_3
			
			shift_right_L_rotation_0:
				side_is_occupied(4, $t0, 8)
				side_is_occupied(4, $t0, 64)
				shift_piece(draw_piece_L, COLOR_L, 4)
			shift_right_L_rotation_1:
				side_is_occupied(4, $t0, 4)
				side_is_occupied(4, $t0, 64)
				side_is_occupied(4, $t0, 68)
				shift_piece(draw_piece_L, COLOR_L, 4)
			shift_right_L_rotation_2:
				side_is_occupied(4, $t0, 72)
				side_is_occupied(4, $t0, 56)
				shift_piece(draw_piece_L, COLOR_L, 4)
			shift_right_L_rotation_3:
				side_is_occupied(4, $t0, 4)
				side_is_occupied(4, $t0, 64)
				side_is_occupied(4, $t0, 64)
				shift_piece(draw_piece_L, COLOR_L, 4)
		shift_right_J:
			beq	$s2, 1, shift_right_J_rotation_1
			beq	$s2, 2, shift_right_J_rotation_2
			beq	$s2, 3, shift_right_J_rotation_3
			
			shift_right_J_rotation_0:
				side_is_occupied(4, $t0, 0)
				side_is_occupied(4, $t0, 72)
				shift_piece(draw_piece_J, COLOR_J, 4)
			shift_right_J_rotation_1:
				side_is_occupied(4, $t0, 8)
				side_is_occupied(4, $t0, 60)
				side_is_occupied(4, $t0, 64)
				shift_piece(draw_piece_J, COLOR_J, 4)
			shift_right_J_rotation_2:
				side_is_occupied(4, $t0, 72)
				side_is_occupied(4, $t0, 64)
				shift_piece(draw_piece_J, COLOR_J, 4)
			shift_right_J_rotation_3:
				side_is_occupied(4, $t0, 4)
				side_is_occupied(4, $t0, 64)
				side_is_occupied(4, $t0, 64)
				shift_piece(draw_piece_J, COLOR_J, 4)
	
	input_rotate:
		jal	rotate_piece
		lw	$ra, ($sp)
		add	$sp, $sp, 4
		jr 	$ra
		
	game_over_input_handler:
		beq	$t0, 32, exit	# space to exit
		lw	$ra, ($sp)
		add	$sp, $sp, 4
		jr 	$ra

# rotation consists of 5 different tries
rotate_piece:
	# no rotate_O since square rotation does nothing
	beq	$s1, 0, generic_function_return
	# if no piece is spawned, do not rotate
	beqz	$s7, generic_function_return
	
	add	$sp, $sp, -4
	sw	$ra, ($sp)
	 
	beq	$s1, 1, rotate_I
	beq	$s1, 2, rotate_T
	beq	$s1, 3, rotate_S
	beq	$s1, 4, rotate_Z
	beq	$s1, 5, rotate_L
	beq	$s1, 6, rotate_J
	
	.macro rotate(%draw_function, %color)
		move	$a0, $s3
		li	$a1, BLACK
		move	$a2, $s2
		jal	%draw_function
		
		# rotation overflow check
		add	$s2, $s2, 1
		li	$t0, 4
		div	$s2, $t0
		mfhi	$s2
		
		move	$a0, $s3
		li	$a1, %color
		move	$a2, $s2
		jal	%draw_function
		
		lw	$ra, ($sp)
		add	$sp, $sp, 4
		jr 	$ra
		
	.end_macro
	
	.macro redraw_and_return(%function, %color, %gp_offset)
		move	$a0, %gp_offset
		li	$a1, %color
		move	$a2, $s2
		jal	%function
		
		lw	$ra, ($sp)
		add	$sp, $sp, 4
		jr 	$ra
	.end_macro
	
	rotate_I:
		move	$a0, $s3
		li	$a1, BLACK
		move	$a2, $s2
		jal	draw_piece_I
	
		beq	$s2, 0, rotate_I_0_to_1
		beq	$s2, 1, rotate_I_1_to_2
		beq	$s2, 2	rotate_I_2_to_3
		beq	$s2, 3, rotate_I_3_to_0
			
		rotate_I_0_to_1:
			.macro try_rotate_I_0_to_1(%gp_offset)
				lw	$t0, 8(%gp_offset)
				bnez	$t0, rotate_I_0_to_1_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_I_0_to_1_failed
				lw	$t0, 136(%gp_offset)
				bnez	$t0, rotate_I_0_to_1_failed
				lw	$t0, 200(%gp_offset)
				bnez	$t0, rotate_I_0_to_1_failed
				
				move	$s3, %gp_offset
				li	$s2, 1
				redraw_and_return(draw_piece_I, COLOR_I, %gp_offset)
				rotate_I_0_to_1_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_I_0_to_1($t1)
			add	$t1, $s3, -8
			try_rotate_I_0_to_1($t1)
			add	$t1, $s3, 4
			try_rotate_I_0_to_1($t1)
			add	$t1, $s3, 56
			try_rotate_I_0_to_1($t1)
			add	$t1, $s3, -124
			try_rotate_I_0_to_1($t1)
			redraw_and_return(draw_piece_I, COLOR_I, $s3)
		
		rotate_I_1_to_2:
			.macro try_rotate_I_1_to_2(%gp_offset)
				lw	$t0, 128(%gp_offset)
				bnez	$t0, rotate_I_1_to_2_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_I_1_to_2_failed
				lw	$t0, 136(%gp_offset)
				bnez	$t0, rotate_I_1_to_2_failed
				lw	$t0, 140(%gp_offset)
				bnez	$t0, rotate_I_1_to_2_failed
				
				move	$s3, %gp_offset
				li	$s2, 2
				redraw_and_return(draw_piece_I, COLOR_I, %gp_offset)
				rotate_I_1_to_2_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_I_1_to_2($t1)
			add	$t1, $s3, -4
			try_rotate_I_1_to_2($t1)
			add	$t1, $s3, 8
			try_rotate_I_1_to_2($t1)
			add	$t1, $s3, -132
			try_rotate_I_1_to_2($t1)
			add	$t1, $s3, 72
			try_rotate_I_1_to_2($t1)
			redraw_and_return(draw_piece_I, COLOR_I, $s3)
			
		rotate_I_2_to_3:
			.macro try_rotate_I_2_to_3(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_I_2_to_3_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_I_2_to_3_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_I_2_to_3_failed
				lw	$t0, 196(%gp_offset)
				bnez	$t0, rotate_I_2_to_3_failed
				
				move	$s3, %gp_offset
				li	$s2, 3
				redraw_and_return(draw_piece_I, COLOR_I, %gp_offset)
				rotate_I_2_to_3_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_I_2_to_3($t1)
			add	$t1, $s3, 8
			try_rotate_I_2_to_3($t1)
			add	$t1, $s3, -4
			try_rotate_I_2_to_3($t1)
			add	$t1, $s3, -56
			try_rotate_I_2_to_3($t1)
			add	$t1, $s3, 124
			try_rotate_I_2_to_3($t1)
			redraw_and_return(draw_piece_I, COLOR_I, $s3)
		rotate_I_3_to_0:
			.macro try_rotate_I_3_to_0(%gp_offset)
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_I_3_to_0_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_I_3_to_0_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_I_3_to_0_failed
				lw	$t0, 76(%gp_offset)
				bnez	$t0, rotate_I_3_to_0_failed
				
				move	$s3, %gp_offset
				li	$s2, 0
				redraw_and_return(draw_piece_I, COLOR_I, %gp_offset)
				rotate_I_3_to_0_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_I_3_to_0($t1)
			add	$t1, $s3, 4
			try_rotate_I_3_to_0($t1)
			add	$t1, $s3, -8
			try_rotate_I_3_to_0($t1)
			add	$t1, $s3, 132
			try_rotate_I_3_to_0($t1)
			add	$t1, $s3, -72
			try_rotate_I_3_to_0($t1)
			redraw_and_return(draw_piece_I, COLOR_I, $s3)
	rotate_T:
		move	$a0, $s3
		li	$a1, BLACK
		move	$a2, $s2
		jal	draw_piece_T
	
		beq	$s2, 0, rotate_T_0_to_1
		beq	$s2, 1, rotate_T_1_to_2
		beq	$s2, 2	rotate_T_2_to_3
		beq	$s2, 3, rotate_T_3_to_0
		
		rotate_T_0_to_1:
			.macro try_rotate_T_0_to_1(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_T_0_to_1_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_T_0_to_1_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_T_0_to_1_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_T_0_to_1_failed
				
				move	$s3, %gp_offset
				li	$s2, 1
				redraw_and_return(draw_piece_T, COLOR_T, %gp_offset)
				rotate_T_0_to_1_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_T_0_to_1($t1)
			add	$t1, $s3, -4
			try_rotate_T_0_to_1($t1)
			add	$t1, $s3, -68
			try_rotate_T_0_to_1($t1)
			add	$t1, $s3, 128
			try_rotate_T_0_to_1($t1)
			add	$t1, $s3, 124
			try_rotate_T_0_to_1($t1)
			redraw_and_return(draw_piece_T, COLOR_T, $s3)
		
		rotate_T_1_to_2:
			.macro try_rotate_T_1_to_2(%gp_offset)
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_T_1_to_2_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_T_1_to_2_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_T_1_to_2_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_T_1_to_2_failed
				
				move	$s3, %gp_offset
				li	$s2, 2
				redraw_and_return(draw_piece_T, COLOR_T, %gp_offset)
				rotate_T_1_to_2_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_T_1_to_2($t1)
			add	$t1, $s3, 4
			try_rotate_T_1_to_2($t1)
			add	$t1, $s3, 68
			try_rotate_T_1_to_2($t1)
			add	$t1, $s3, -128
			try_rotate_T_1_to_2($t1)
			add	$t1, $s3, -124
			try_rotate_T_1_to_2($t1)
			redraw_and_return(draw_piece_T, COLOR_T, $s3)
			
		rotate_T_2_to_3:
			.macro try_rotate_T_2_to_3(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_T_2_to_3_failed
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_T_2_to_3_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_T_2_to_3_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_T_2_to_3_failed
				
				move	$s3, %gp_offset
				li	$s2, 3
				redraw_and_return(draw_piece_T, COLOR_T, %gp_offset)
				rotate_T_2_to_3_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_T_2_to_3($t1)
			add	$t1, $s3, 4
			try_rotate_T_2_to_3($t1)
			add	$t1, $s3, -60
			try_rotate_T_2_to_3($t1)
			add	$t1, $s3, 128
			try_rotate_T_2_to_3($t1)
			add	$t1, $s3, 132
			try_rotate_T_2_to_3($t1)
			redraw_and_return(draw_piece_T, COLOR_T, $s3)
			
		rotate_T_3_to_0:
			.macro try_rotate_T_3_to_0(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_T_3_to_0_failed
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_T_3_to_0_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_T_3_to_0_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_T_3_to_0_failed
				
				move	$s3, %gp_offset
				li	$s2, 0
				redraw_and_return(draw_piece_T, COLOR_T, %gp_offset)
				rotate_T_3_to_0_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_T_3_to_0($t1)
			add	$t1, $s3, -4
			try_rotate_T_3_to_0($t1)
			add	$t1, $s3, 60
			try_rotate_T_3_to_0($t1)
			add	$t1, $s3, -128
			try_rotate_T_3_to_0($t1)
			add	$t1, $s3, -132
			try_rotate_T_3_to_0($t1)
			redraw_and_return(draw_piece_T, COLOR_T, $s3)
	rotate_S:
		move	$a0, $s3
		li	$a1, BLACK
		move	$a2, $s2
		jal	draw_piece_S
	
		beq	$s2, 0, rotate_S_0_to_1
		beq	$s2, 1, rotate_S_1_to_2
		beq	$s2, 2	rotate_S_2_to_3
		beq	$s2, 3, rotate_S_3_to_0
		
		rotate_S_0_to_1:
			.macro try_rotate_S_0_to_1(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_S_0_to_1_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_S_0_to_1_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_S_0_to_1_failed
				lw	$t0, 136(%gp_offset)
				bnez	$t0, rotate_S_0_to_1_failed
				
				move	$s3, %gp_offset
				li	$s2, 1
				redraw_and_return(draw_piece_S, COLOR_S, %gp_offset)
				rotate_S_0_to_1_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_S_0_to_1($t1)
			add	$t1, $s3, -4
			try_rotate_S_0_to_1($t1)
			add	$t1, $s3, -68
			try_rotate_S_0_to_1($t1)
			add	$t1, $s3, 128
			try_rotate_S_0_to_1($t1)
			add	$t1, $s3, 124
			try_rotate_S_0_to_1($t1)
			redraw_and_return(draw_piece_S, COLOR_S, $s3)
		
		rotate_S_1_to_2:
			.macro try_rotate_S_1_to_2(%gp_offset)
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_S_1_to_2_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_S_1_to_2_failed
				lw	$t0, 128(%gp_offset)
				bnez	$t0, rotate_S_1_to_2_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_S_1_to_2_failed
				
				move	$s3, %gp_offset
				li	$s2, 2
				redraw_and_return(draw_piece_S, COLOR_S, %gp_offset)
				rotate_S_1_to_2_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_S_1_to_2($t1)
			add	$t1, $s3, 4
			try_rotate_S_1_to_2($t1)
			add	$t1, $s3, 68
			try_rotate_S_1_to_2($t1)
			add	$t1, $s3, -128
			try_rotate_S_1_to_2($t1)
			add	$t1, $s3, -124
			try_rotate_S_1_to_2($t1)
			redraw_and_return(draw_piece_S, COLOR_S, $s3)
			
		rotate_S_2_to_3:
			.macro try_rotate_S_2_to_3(%gp_offset)
				lw	$t0, 0(%gp_offset)
				bnez	$t0, rotate_S_2_to_3_failed
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_S_2_to_3_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_S_2_to_3_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_S_2_to_3_failed
				
				move	$s3, %gp_offset
				li	$s2, 3
				redraw_and_return(draw_piece_S, COLOR_S, %gp_offset)
				rotate_S_2_to_3_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_S_2_to_3($t1)
			add	$t1, $s3, 4
			try_rotate_S_2_to_3($t1)
			add	$t1, $s3, -60
			try_rotate_S_2_to_3($t1)
			add	$t1, $s3, 128
			try_rotate_S_2_to_3($t1)
			add	$t1, $s3, 132
			try_rotate_S_2_to_3($t1)
			redraw_and_return(draw_piece_S, COLOR_S, $s3)
			
		rotate_S_3_to_0:
			.macro try_rotate_S_3_to_0(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_S_3_to_0_failed
				lw	$t0, 8(%gp_offset)
				bnez	$t0, rotate_S_3_to_0_failed
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_S_3_to_0_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_S_3_to_0_failed
				
				move	$s3, %gp_offset
				li	$s2, 0
				redraw_and_return(draw_piece_S, COLOR_S, %gp_offset)
				rotate_S_3_to_0_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_S_3_to_0($t1)
			add	$t1, $s3, -4
			try_rotate_S_3_to_0($t1)
			add	$t1, $s3, 60
			try_rotate_S_3_to_0($t1)
			add	$t1, $s3, -128
			try_rotate_S_3_to_0($t1)
			add	$t1, $s3, -132
			try_rotate_S_3_to_0($t1)
			redraw_and_return(draw_piece_S, COLOR_S, $s3)
	rotate_Z:
		move	$a0, $s3
		li	$a1, BLACK
		move	$a2, $s2
		jal	draw_piece_Z
	
		beq	$s2, 0, rotate_Z_0_to_1
		beq	$s2, 1, rotate_Z_1_to_2
		beq	$s2, 2	rotate_Z_2_to_3
		beq	$s2, 3, rotate_Z_3_to_0
		
		rotate_Z_0_to_1:
			.macro try_rotate_Z_0_to_1(%gp_offset)
				lw	$t0, 8(%gp_offset)
				bnez	$t0, rotate_Z_0_to_1_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_Z_0_to_1_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_Z_0_to_1_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_Z_0_to_1_failed
				
				move	$s3, %gp_offset
				li	$s2, 1
				redraw_and_return(draw_piece_Z, COLOR_Z, %gp_offset)
				rotate_Z_0_to_1_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_Z_0_to_1($t1)
			add	$t1, $s3, -4
			try_rotate_Z_0_to_1($t1)
			add	$t1, $s3, -68
			try_rotate_Z_0_to_1($t1)
			add	$t1, $s3, 128
			try_rotate_Z_0_to_1($t1)
			add	$t1, $s3, 124
			try_rotate_Z_0_to_1($t1)
			redraw_and_return(draw_piece_Z, COLOR_Z, $s3)
		
		rotate_Z_1_to_2:
			.macro try_rotate_Z_1_to_2(%gp_offset)
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_Z_1_to_2_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_Z_1_to_2_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_Z_1_to_2_failed
				lw	$t0, 136(%gp_offset)
				bnez	$t0, rotate_Z_1_to_2_failed
				
				move	$s3, %gp_offset
				li	$s2, 2
				redraw_and_return(draw_piece_Z, COLOR_Z, %gp_offset)
				rotate_Z_1_to_2_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_Z_1_to_2($t1)
			add	$t1, $s3, 4
			try_rotate_Z_1_to_2($t1)
			add	$t1, $s3, 68
			try_rotate_Z_1_to_2($t1)
			add	$t1, $s3, -128
			try_rotate_Z_1_to_2($t1)
			add	$t1, $s3, -124
			try_rotate_Z_1_to_2($t1)
			redraw_and_return(draw_piece_Z, COLOR_Z, $s3)
			
		rotate_Z_2_to_3:
			.macro try_rotate_Z_2_to_3(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_Z_2_to_3_failed
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_Z_2_to_3_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_Z_2_to_3_failed
				lw	$t0, 128(%gp_offset)
				bnez	$t0, rotate_Z_2_to_3_failed
				
				move	$s3, %gp_offset
				li	$s2, 3
				redraw_and_return(draw_piece_Z, COLOR_Z, %gp_offset)
				rotate_Z_2_to_3_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_Z_2_to_3($t1)
			add	$t1, $s3, 4
			try_rotate_Z_2_to_3($t1)
			add	$t1, $s3, -60
			try_rotate_Z_2_to_3($t1)
			add	$t1, $s3, 128
			try_rotate_Z_2_to_3($t1)
			add	$t1, $s3, 132
			try_rotate_Z_2_to_3($t1)
			redraw_and_return(draw_piece_Z, COLOR_Z, $s3)
		
		rotate_Z_3_to_0:
			.macro try_rotate_Z_3_to_0(%gp_offset)
				lw	$t0, 0(%gp_offset)
				bnez	$t0, rotate_Z_3_to_0_failed
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_Z_3_to_0_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_Z_3_to_0_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_Z_3_to_0_failed
				
				move	$s3, %gp_offset
				li	$s2, 0
				redraw_and_return(draw_piece_Z, COLOR_Z, %gp_offset)
				rotate_Z_3_to_0_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_Z_3_to_0($t1)
			add	$t1, $s3, -4
			try_rotate_Z_3_to_0($t1)
			add	$t1, $s3, 60
			try_rotate_Z_3_to_0($t1)
			add	$t1, $s3, -128
			try_rotate_Z_3_to_0($t1)
			add	$t1, $s3, -132
			try_rotate_Z_3_to_0($t1)
			redraw_and_return(draw_piece_Z, COLOR_Z, $s3)
		
	rotate_L:
		move	$a0, $s3
		li	$a1, BLACK
		move	$a2, $s2
		jal	draw_piece_L
	
		beq	$s2, 0, rotate_L_0_to_1
		beq	$s2, 1, rotate_L_1_to_2
		beq	$s2, 2	rotate_L_2_to_3
		beq	$s2, 3, rotate_L_3_to_0
		
		rotate_L_0_to_1:
			.macro try_rotate_L_0_to_1(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_L_0_to_1_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_L_0_to_1_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_L_0_to_1_failed
				lw	$t0, 136(%gp_offset)
				bnez	$t0, rotate_L_0_to_1_failed
				
				move	$s3, %gp_offset
				li	$s2, 1
				redraw_and_return(draw_piece_L, COLOR_L, %gp_offset)
				rotate_L_0_to_1_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_L_0_to_1($t1)
			add	$t1, $s3, -4
			try_rotate_L_0_to_1($t1)
			add	$t1, $s3, -68
			try_rotate_L_0_to_1($t1)
			add	$t1, $s3, 128
			try_rotate_L_0_to_1($t1)
			add	$t1, $s3, 124
			try_rotate_L_0_to_1($t1)
			redraw_and_return(draw_piece_L, COLOR_L, $s3)
		
		rotate_L_1_to_2:
			.macro try_rotate_L_1_to_2(%gp_offset)
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_L_1_to_2_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_L_1_to_2_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_L_1_to_2_failed
				lw	$t0, 128(%gp_offset)
				bnez	$t0, rotate_L_1_to_2_failed
				
				move	$s3, %gp_offset
				li	$s2, 2
				redraw_and_return(draw_piece_L, COLOR_L, %gp_offset)
				rotate_L_1_to_2_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_L_1_to_2($t1)
			add	$t1, $s3, 4
			try_rotate_L_1_to_2($t1)
			add	$t1, $s3, 68
			try_rotate_L_1_to_2($t1)
			add	$t1, $s3, -128
			try_rotate_L_1_to_2($t1)
			add	$t1, $s3, -124
			try_rotate_L_1_to_2($t1)
			redraw_and_return(draw_piece_L, COLOR_L, $s3)
			
		rotate_L_2_to_3:
			.macro try_rotate_L_2_to_3(%gp_offset)
				lw	$t0, 0(%gp_offset)
				bnez	$t0, rotate_L_2_to_3_failed
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_L_2_to_3_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_L_2_to_3_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_L_2_to_3_failed
				
				move	$s3, %gp_offset
				li	$s2, 3
				redraw_and_return(draw_piece_L, COLOR_L, %gp_offset)
				rotate_L_2_to_3_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_L_2_to_3($t1)
			add	$t1, $s3, 4
			try_rotate_L_2_to_3($t1)
			add	$t1, $s3, -60
			try_rotate_L_2_to_3($t1)
			add	$t1, $s3, 128
			try_rotate_L_2_to_3($t1)
			add	$t1, $s3, 132
			try_rotate_L_2_to_3($t1)
			redraw_and_return(draw_piece_L, COLOR_L, $s3)
		
		rotate_L_3_to_0:
			.macro try_rotate_L_3_to_0(%gp_offset)
				lw	$t0, 8(%gp_offset)
				bnez	$t0, rotate_L_3_to_0_failed
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_L_3_to_0_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_L_3_to_0_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_L_3_to_0_failed
				
				move	$s3, %gp_offset
				li	$s2, 0
				redraw_and_return(draw_piece_L, COLOR_L, %gp_offset)
				rotate_L_3_to_0_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_L_3_to_0($t1)
			add	$t1, $s3, -4
			try_rotate_L_3_to_0($t1)
			add	$t1, $s3, 60
			try_rotate_L_3_to_0($t1)
			add	$t1, $s3, -128
			try_rotate_L_3_to_0($t1)
			add	$t1, $s3, -132
			try_rotate_L_3_to_0($t1)
			redraw_and_return(draw_piece_L, COLOR_L, $s3)
	rotate_J:
		move	$a0, $s3
		li	$a1, BLACK
		move	$a2, $s2
		jal	draw_piece_J
	
		beq	$s2, 0, rotate_J_0_to_1
		beq	$s2, 1, rotate_J_1_to_2
		beq	$s2, 2	rotate_J_2_to_3
		beq	$s2, 3, rotate_J_3_to_0
		
		rotate_J_0_to_1:
			.macro try_rotate_J_0_to_1(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_J_0_to_1_failed
				lw	$t0, 8(%gp_offset)
				bnez	$t0, rotate_J_0_to_1_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_J_0_to_1_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_J_0_to_1_failed
				
				move	$s3, %gp_offset
				li	$s2, 1
				redraw_and_return(draw_piece_J, COLOR_J, %gp_offset)
				rotate_J_0_to_1_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_J_0_to_1($t1)
			add	$t1, $s3, -4
			try_rotate_J_0_to_1($t1)
			add	$t1, $s3, -68
			try_rotate_J_0_to_1($t1)
			add	$t1, $s3, 128
			try_rotate_J_0_to_1($t1)
			add	$t1, $s3, 124
			try_rotate_J_0_to_1($t1)
			redraw_and_return(draw_piece_J, COLOR_J, $s3)
		
		rotate_J_1_to_2:
			.macro try_rotate_J_1_to_2(%gp_offset)
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_J_1_to_2_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_J_1_to_2_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_J_1_to_2_failed
				lw	$t0, 136(%gp_offset)
				bnez	$t0, rotate_J_1_to_2_failed
				
				move	$s3, %gp_offset
				li	$s2, 2
				redraw_and_return(draw_piece_J, COLOR_J, %gp_offset)
				rotate_J_1_to_2_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_J_1_to_2($t1)
			add	$t1, $s3, 4
			try_rotate_J_1_to_2($t1)
			add	$t1, $s3, 68
			try_rotate_J_1_to_2($t1)
			add	$t1, $s3, -128
			try_rotate_J_1_to_2($t1)
			add	$t1, $s3, -124
			try_rotate_J_1_to_2($t1)
			redraw_and_return(draw_piece_J, COLOR_J, $s3)
			
		rotate_J_2_to_3:
			.macro try_rotate_J_2_to_3(%gp_offset)
				lw	$t0, 4(%gp_offset)
				bnez	$t0, rotate_J_2_to_3_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_J_2_to_3_failed
				lw	$t0, 128(%gp_offset)
				bnez	$t0, rotate_J_2_to_3_failed
				lw	$t0, 132(%gp_offset)
				bnez	$t0, rotate_J_2_to_3_failed
				
				move	$s3, %gp_offset
				li	$s2, 3
				redraw_and_return(draw_piece_J, COLOR_J, %gp_offset)
				rotate_J_2_to_3_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_J_2_to_3($t1)
			add	$t1, $s3, 4
			try_rotate_J_2_to_3($t1)
			add	$t1, $s3, -60
			try_rotate_J_2_to_3($t1)
			add	$t1, $s3, 128
			try_rotate_J_2_to_3($t1)
			add	$t1, $s3, 132
			try_rotate_J_2_to_3($t1)
			redraw_and_return(draw_piece_J, COLOR_J, $s3)
		
		rotate_J_3_to_0:
			.macro try_rotate_J_3_to_0(%gp_offset)
				lw	$t0, 0(%gp_offset)
				bnez	$t0, rotate_J_3_to_0_failed
				lw	$t0, 64(%gp_offset)
				bnez	$t0, rotate_J_3_to_0_failed
				lw	$t0, 68(%gp_offset)
				bnez	$t0, rotate_J_3_to_0_failed
				lw	$t0, 72(%gp_offset)
				bnez	$t0, rotate_J_3_to_0_failed
				
				move	$s3, %gp_offset
				li	$s2, 0
				redraw_and_return(draw_piece_J, COLOR_J, %gp_offset)
				rotate_J_3_to_0_failed:
			.end_macro
			
			move	$t1, $s3
			try_rotate_J_3_to_0($t1)
			add	$t1, $s3, -4
			try_rotate_J_3_to_0($t1)
			add	$t1, $s3, 60
			try_rotate_J_3_to_0($t1)
			add	$t1, $s3, -128
			try_rotate_J_3_to_0($t1)
			add	$t1, $s3, -132
			try_rotate_J_3_to_0($t1)
			redraw_and_return(draw_piece_J, COLOR_J, $s3)
			
# piece drop algorithm:
# check if the piece is at the bottom of the screen
#	this is done by looking at the piece shape and how close the piece offset is to the base
# check if the piece will intersect an already solidified piece
#	this is done by checking each block in the piece with their bottom exposed
# move the piece down
#	done by moving the top pixel of each column to the bottom
drop_piece:
	# check if piece should fall on this frame
	div	$s0, $s5
	mfhi	$t0
	bnez	$t0, generic_function_return
	
	add	$sp, $sp, -4
	sw	$ra, ($sp)
	
	# check if piece should solidify
	lw	$t0, MAX_PIECE_OFFSET
	beq	$s1, 0, drop_O
	beq	$s1, 1, drop_I
	beq	$s1, 2, drop_T
	beq	$s1, 3, drop_S
	beq	$s1, 4, drop_Z
	beq	$s1, 5, drop_L
	beq	$s1, 6, drop_J
	
	finish_piece_drop:
	# increment piece $gp offset by 1 line
	add	$s3, $s3, 64
	
	lw	$ra, ($sp)
	add	$sp, $sp, 4
	jr 	$ra
	
	solidify_piece:
	# set piece is falling flag to false
	li	$s7, 0
	jal	check_line_completion
	
	# check if player is dead
	move	$t2, $gp
	add	$t2, $t2, -16
	li	$t0, 0
	li	$t1, 0
	death_check_loop:
		lw	$t3, ($t2)
		add	$t1, $t1, $t3
		add	$t2, $t2, -4

		add	$t0, $t0, 1
		blt	$t0, 10, death_check_loop
	sne	$s6, $t1, $zero
	
	lw	$ra, ($sp)
	add	$sp, $sp, 4
	jr 	$ra

	.macro move_block(%placement_offset, %piece_offset, %piece_offset_shift_amt)
		add	%piece_offset, %piece_offset, %piece_offset_shift_amt
		lw	$t9, (%piece_offset)
		sw	$zero, (%piece_offset)
		sw	$t9, %placement_offset(%piece_offset)
	.end_macro
	
	.macro below_is_occupied(%offset, %piece_offset)
		lw	$t9, %offset(%piece_offset)
		bnez	$t9, solidify_piece
	.end_macro
	
	drop_O:
		below_is_occupied(128, $s3)	
		below_is_occupied(132, $s3)
		move	$t0, $s3
		move_block(128, $t0, 0)
		move_block(128, $t0, 4)
		j	finish_piece_drop
	
	drop_I:
		beq	$s2, 1, drop_I_rotation_1
		beq	$s2, 2, drop_I_rotation_2
		beq	$s2, 3, drop_I_rotation_3
	
		drop_I_rotation_0:
			below_is_occupied(128, $s3)
			below_is_occupied(132, $s3)
			below_is_occupied(136, $s3)
			below_is_occupied(140, $s3)
			move	$t0, $s3
			move_block(64, $t0, 64)
			move_block(64, $t0, 4)
			move_block(64, $t0, 4)
			move_block(64, $t0, 4)
			j	finish_piece_drop
	
		drop_I_rotation_1:
			below_is_occupied(264, $s3)
			move	$t0, $s3
			move_block(256, $t0, 8)
			j	finish_piece_drop
		
		drop_I_rotation_2:
			below_is_occupied(192, $s3)
			below_is_occupied(196, $s3)
			below_is_occupied(200, $s3)
			below_is_occupied(204, $s3)
			move	$t0, $s3
			move_block(64, $t0, 128)
			move_block(64, $t0, 4)
			move_block(64, $t0, 4)
			move_block(64, $t0, 4)
			j	finish_piece_drop
	
		drop_I_rotation_3:
			below_is_occupied(260, $s3)
			move	$t0, $s3
			move_block(256, $t0, 4)
			j	finish_piece_drop
	
	drop_T:
		beq	$s2, 1, drop_T_rotation_1
		beq	$s2, 2, drop_T_rotation_2
		beq	$s2, 3, drop_T_rotation_3
	
		drop_T_rotation_0:
			below_is_occupied(128, $s3)
			below_is_occupied(132, $s3)
			below_is_occupied(136, $s3)
			move	$t0, $s3
			move_block(128, $t0, 4)
			move_block(64, $t0, 60)
			move_block(64, $t0, 8)
			j	finish_piece_drop
	
		drop_T_rotation_1:
			below_is_occupied(136, $s3)
			below_is_occupied(196, $s3)
			move	$t0, $s3
			move_block(192, $t0, 4)
			move_block(64, $t0, 68)
			j	finish_piece_drop
	
		drop_T_rotation_2:
			below_is_occupied(128, $s3)
			below_is_occupied(136, $s3)
			below_is_occupied(196, $s3)
			move	$t0, $s3
			move_block(64, $t0, 64)
			move_block(128, $t0, 4)
			move_block(64, $t0, 4)
			j	finish_piece_drop
	
		drop_T_rotation_3:
			below_is_occupied(128, $s3)
			below_is_occupied(196, $s3)
			move	$t0, $s3
			move_block(192, $t0, 4)
			move_block(64, $t0, 60)
			j	finish_piece_drop
		
	drop_S:
		beq	$s2, 1, drop_S_rotation_1
		beq	$s2, 2, drop_S_rotation_2
		beq	$s2, 3, drop_S_rotation_3
		
		drop_S_rotation_0:
			below_is_occupied(72, $s3)
			below_is_occupied(128, $s3)
			below_is_occupied(132, $s3)
			move	$t0, $s3
			move_block(128, $t0, 4)
			move_block(64, $t0, 4)
			move_block(64, $t0,56)
			j	finish_piece_drop
		
		drop_S_rotation_1:
			below_is_occupied(132, $s3)
			below_is_occupied(200, $s3)
			move	$t0, $s3
			move_block(128, $t0, 4)
			move_block(128, $t0, 68)
			j	finish_piece_drop
		
		drop_S_rotation_2:
			below_is_occupied(136, $s3)
			below_is_occupied(192, $s3)
			below_is_occupied(196, $s3)
			move	$t0, $s3
			move_block(128, $t0, 68)
			move_block(64, $t0, 4)
			move_block(64, $t0,56)
			j	finish_piece_drop
		
		drop_S_rotation_3:
			below_is_occupied(128, $s3)
			below_is_occupied(196, $s3)
			move	$t0, $s3
			move_block(128, $t0, 0)
			move_block(128, $t0, 68)
			j	finish_piece_drop
		
	drop_Z:
		beq	$s2, 1, drop_Z_rotation_1
		beq	$s2, 2, drop_Z_rotation_2
		beq	$s2, 3, drop_Z_rotation_3
		
		drop_Z_rotation_0:
			below_is_occupied(64, $s3)
			below_is_occupied(132, $s3)
			below_is_occupied(136, $s3)
			move	$t0, $s3
			move_block(64, $t0, 0)
			move_block(128, $t0, 4)
			move_block(64, $t0,68)
			j	finish_piece_drop
		
		drop_Z_rotation_1:
			below_is_occupied(136, $s3)
			below_is_occupied(196, $s3)
			move	$t0, $s3
			move_block(128, $t0, 8)
			move_block(128, $t0, 60)
			j	finish_piece_drop
		
		drop_Z_rotation_2:
			below_is_occupied(128, $s3)
			below_is_occupied(196, $s3)
			below_is_occupied(200, $s3)
			move	$t0, $s3
			move_block(64, $t0, 64)
			move_block(128, $t0, 4)
			move_block(64, $t0,68)
			j	finish_piece_drop
		
		drop_Z_rotation_3:
			below_is_occupied(132, $s3)
			below_is_occupied(192, $s3)
			move	$t0, $s3
			move_block(128, $t0, 4)
			move_block(128, $t0, 60)
			j	finish_piece_drop
		
	drop_L:
		beq	$s2, 1, drop_L_rotation_1
		beq	$s2, 2, drop_L_rotation_2
		beq	$s2, 3, drop_L_rotation_3
		
		drop_L_rotation_0:
			below_is_occupied(128, $s3)
			below_is_occupied(132, $s3)
			below_is_occupied(136, $s3)
			move	$t0, $s3
			move_block(128, $t0, 8)
			move_block(64, $t0, 56)
			move_block(64, $t0,4)
			j	finish_piece_drop
		
		drop_L_rotation_1:
			below_is_occupied(196, $s3)
			below_is_occupied(200, $s3)
			move	$t0, $s3
			move_block(192, $t0, 4)
			move_block(64, $t0, 132)
			j	finish_piece_drop
		
		drop_L_rotation_2:
			below_is_occupied(132, $s3)
			below_is_occupied(136, $s3)
			below_is_occupied(192, $s3)
			move	$t0, $s3
			move_block(128, $t0, 64)
			move_block(64, $t0, 4)
			move_block(64, $t0,4)
			j	finish_piece_drop
		
		drop_L_rotation_3:
			below_is_occupied(64, $s3)
			below_is_occupied(196, $s3)
			move	$t0, $s3
			move_block(64, $t0, 0)
			move_block(192, $t0, 4)
			j	finish_piece_drop		

	drop_J:
		beq	$s2, 1, drop_J_rotation_1
		beq	$s2, 2, drop_J_rotation_2
		beq	$s2, 3, drop_J_rotation_3
		
		drop_J_rotation_0:
			below_is_occupied(128, $s3)
			below_is_occupied(132, $s3)
			below_is_occupied(136, $s3)
			move	$t0, $s3
			move_block(128, $t0, 0)
			move_block(64, $t0, 68)
			move_block(64, $t0,4)
			j	finish_piece_drop
		
		drop_J_rotation_1:
			below_is_occupied(72, $s3)
			below_is_occupied(196, $s3)
			move	$t0, $s3
			move_block(192, $t0, 4)
			move_block(64, $t0, 4)
			j	finish_piece_drop
		
		drop_J_rotation_2:
			below_is_occupied(128, $s3)
			below_is_occupied(132, $s3)
			below_is_occupied(200, $s3)
			move	$t0, $s3
			move_block(64, $t0, 64)
			move_block(64, $t0, 4)
			move_block(128, $t0,4)
			j	finish_piece_drop
		
		drop_J_rotation_3:
			below_is_occupied(192, $s3)
			below_is_occupied(196, $s3)
			move	$t0, $s3
			move_block(192, $t0, 4)
			move_block(64, $t0, 124)
			j	finish_piece_drop
		
spawn_piece:
	add	$sp, $sp, -4
	sw	$ra, ($sp)
	
	# set piece is falling flag to true
	li	$s7, 1
	# get random piece
	li	$v0, 42
	li	$a1, 7
	syscall
	move	$s1, $a0

	#li	$s1, 1
	# reset piece rotation
	li	$a2, 0
	li	$s2, 0	
	
	beq	$s1, 0, spawn_O
	beq	$s1, 1, spawn_I
	beq	$s1, 2, spawn_T
	beq	$s1, 3, spawn_S
	beq	$s1, 4, spawn_Z
	beq	$s1, 5, spawn_L
	beq	$s1, 6, spawn_J
	
	.macro	spawn(%horz_offset, %function, %color)
		add	$s3, $gp, %horz_offset
		add	$s3, $s3, -128
	
		move	$a0, $s3
		li	$a1, %color
		jal	%function
	
		lw	$ra, ($sp)
		add	$sp, $sp, 4
		jr	$ra
	.end_macro
	
	spawn_O:
		spawn(28, draw_piece_O, COLOR_O)
	spawn_I:
		spawn(24, draw_piece_I, COLOR_I)
	spawn_T:
		spawn(24, draw_piece_T, COLOR_T)
	spawn_S:
		spawn(24, draw_piece_S, COLOR_S)
	spawn_Z:
		spawn(24, draw_piece_Z, COLOR_Z)
	spawn_L:
		spawn(24, draw_piece_L, COLOR_L)
	spawn_J:
		spawn(24, draw_piece_J, COLOR_J)
	
	
init:
	add	$sp, $sp, -4
	sw	$ra, ($sp)
	
	# seeds the PRNG with the current system time
	li	$v0, 30
	syscall		# system time
		
	li	$v0, 40
	move	$a1, $a0
	syscall		# seed rng
	
	# pieces start out dropping 1 square every 50 ticks (half a second)
	li	$s5, 50
	
	# pieces cannot exist past this offset
	add	$t0, $gp, 1204
	sw	$t0, MAX_PIECE_OFFSET
	
	# store score digits $gp offsets
	add	$t0, $gp, 1728
	sw	$t0, OFFSET_1000
	add	$t0, $t0, 16
	sw	$t0, OFFSET_100
	add	$t0, $t0, 16
	sw	$t0, OFFSET_10
	add	$t0, $t0, 16
	sw	$t0, OFFSET_1
	
	la	$t1, ($gp)	# used as offset during entire initilization
	
	# draw game-field border
	li	$t0, 19		# board is 20 tall
	li	$t2, GRAY	
	draw_border_edge:
	sw	$t2, ($t1)
	sw	$t2, 4($t1)
	sw	$t2, 8($t1)
	sw	$t2, 52($t1)
	sw	$t2, 56($t1)
	sw	$t2, 60($t1)
	add	$t1, $t1, 64
	add	$t0, $t0, -1
	bnez	$t0, draw_border_edge
	
	li	$t0, 16
	draw_border_bottom:
	sw	$t2, ($t1)
	add	$t1, $t1, 4
	add	$t0, $t0, -1
	bnez	$t0, draw_border_bottom
	
	add	$t1, $t1, 64
	# draw S
	move	$a0, $t1
	li	$a1, MID_GRAY
	jal	draw_S
	
	
	add	$t1, $t1, 12
	
	# draw C
	move	$a0, $t1
	li	$a1, LIGHT_GRAY
	jal	draw_C
	
	add	$t1, $t1, 12
	
	# draw O
	move	$a0, $t1
	li	$a1, MID_GRAY
	jal	draw_O
	
	add	$t1, $t1, 12
	
	# draw R
	move	$a0, $t1
	li	$a1, LIGHT_GRAY
	jal	draw_R
	
	add	$t1, $t1, 12
	
	# draw E
	move	$a0, $t1
	li	$a1, MID_GRAY
	jal	draw_E
	
	# draw score
	lw	$a0, OFFSET_1000
	li	$a1, YELLOW
	jal 	draw_zero
	add	$a0, $a0, 16
	jal	draw_zero
	add	$a0, $a0, 16
	jal	draw_zero
	add	$a0, $a0, 16
	jal	draw_zero
	
	lw	$ra, ($sp)
	add	$sp, $sp, 4
	jr 	$ra

# $a0 - $gp offset
# $a1 - color
draw_S:
	move	$t1, $a0
	move	$t2, $a1
	sw	$t2, 4($t1)
	sw	$t2, 8($t1)
	sw	$t2, 64($t1)
	sw	$t2, 128($t1)
	sw	$t2, 132($t1)
	sw	$t2, 136($t1)
	sw	$t2, 200($t1)
	sw	$t2, 256($t1)
	sw	$t2, 260($t1)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_C:
	move	$t1, $a0
	move	$t2, $a1
	sw	$t2, 4($t1)
	sw	$t2, 8($t1)
	sw	$t2, 64($t1)
	sw	$t2, 128($t1)
	sw	$t2, 192($t1)
	sw	$t2, 260($t1)
	sw	$t2, 264($t1)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_O:
	move	$t1, $a0
	move	$t2, $a1
	sw	$t2, 4($t1)
	sw	$t2, 64($t1)
	sw	$t2, 72($t1)
	sw	$t2, 128($t1)
	sw	$t2, 136($t1)
	sw	$t2, 192($t1)
	sw	$t2, 200($t1)
	sw	$t2, 260($t1)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_R:
	move	$t1, $a0
	move	$t2, $a1
	sw	$t2, ($t1)
	sw	$t2, 4($t1)
	sw	$t2, 64($t1)
	sw	$t2, 72($t1)
	sw	$t2, 128($t1)
	sw	$t2, 132($t1)
	sw	$t2, 192($t1)
	sw	$t2, 200($t1)
	sw	$t2, 256($t1)
	sw	$t2, 264($t1)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_E:
	move	$t1, $a0
	move	$t2, $a1
	sw	$t2, ($t1)
	sw	$t2, 4($t1)
	sw	$t2, 8($t1)
	sw	$t2, 64($t1)
	sw	$t2, 128($t1)
	sw	$t2, 132($t1)
	sw	$t2, 192($t1)
	sw	$t2, 256($t1)
	sw	$t2, 260($t1)
	sw	$t2, 264($t1)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_G:
	move	$t1, $a0
	move	$t2, $a1
	sw	$t2, ($t1)
	sw	$t2, 4($t1)
	sw	$t2, 8($t1)
	sw	$t2, 64($t1)
	sw	$t2, 128($t1)
	sw	$t2, 192($t1)
	sw	$t2, 200($t1)
	sw	$t2, 256($t1)
	sw	$t2, 260($t1)
	sw	$t2, 264($t1)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_A:
	move	$t1, $a0
	move	$t2, $a1
	sw	$t2, 4($t1)
	sw	$t2, 64($t1)
	sw	$t2, 72($t1)
	sw	$t2, 128($t1)
	sw	$t2, 132($t1)
	sw	$t2, 136($t1)
	sw	$t2, 192($t1)
	sw	$t2, 200($t1)
	sw	$t2, 256($t1)
	sw	$t2, 264($t1)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_M:
	move	$t1, $a0
	move	$t2, $a1
	sw	$t2, ($t1)
	sw	$t2, 8($t1)
	sw	$t2, 64($t1)
	sw	$t2, 68($t1)
	sw	$t2, 72($t1)
	sw	$t2, 128($t1)
	sw	$t2, 136($t1)
	sw	$t2, 192($t1)
	sw	$t2, 200($t1)
	sw	$t2, 256($t1)
	sw	$t2, 264($t1)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_V:
	move	$t1, $a0
	move	$t2, $a1
	sw	$t2, ($t1)
	sw	$t2, 8($t1)
	sw	$t2, 64($t1)
	sw	$t2, 72($t1)
	sw	$t2, 128($t1)
	sw	$t2, 136($t1)
	sw	$t2, 192($t1)
	sw	$t2, 200($t1)
	sw	$t2, 260($t1)
	jr	$ra
	
# $a0 - $gp offset
# $a1 - color
draw_zero:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 64($a0)
	sw	$a1, 72($a0)
	sw	$a1, 128($a0)
	sw	$a1, 136($a0)
	sw	$a1, 192($a0)
	sw	$a1, 200($a0)
	sw	$a1, 256($a0)
	sw	$a1, 260($a0)
	sw	$a1, 264($a0)
	jr	$ra


# $a0 - $gp offset
draw_one:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 68($a0)
	sw	$a1, 132($a0)
	sw	$a1, 196($a0)
	sw	$a1, 256($a0)
	sw	$a1, 260($a0)
	sw	$a1, 264($a0)
	jr	$ra
# $a0 - $gp offset
# $a1 - color
draw_two:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 72($a0)
	sw	$a1, 128($a0)
	sw	$a1, 132($a0)
	sw	$a1, 136($a0)
	sw	$a1, 192($a0)
	sw	$a1, 260($a0)
	sw	$a1, 264($a0)
	jr	$ra
	
# $a0 - $gp offset
# $a1 - color
draw_three:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 72($a0)
	sw	$a1, 132($a0)
	sw	$a1, 136($a0)
	sw	$a1, 200($a0)
	sw	$a1, 256($a0)
	sw	$a1, 260($a0)
	sw	$a1, 264($a0)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_four:
	sw	$a1, ($a0)
	sw	$a1, 64($a0)
	sw	$a1, 72($a0)
	sw	$a1, 128($a0)
	sw	$a1, 132($a0)
	sw	$a1, 136($a0)
	sw	$a1, 200($a0)
	sw	$a1, 264($a0)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_five:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 64($a0)
	sw	$a1, 128($a0)
	sw	$a1, 132($a0)
	sw	$a1, 136($a0)
	sw	$a1, 200($a0)
	sw	$a1, 256($a0)
	sw	$a1, 260($a0)
	sw	$a1, 264($a0)
	
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_six:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 64($a0)
	sw	$a1, 128($a0)
	sw	$a1, 132($a0)
	sw	$a1, 136($a0)
	sw	$a1, 192($a0)
	sw	$a1, 200($a0)
	sw	$a1, 256($a0)
	sw	$a1, 260($a0)
	sw	$a1, 264($a0)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_seven:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 72($a0)
	sw	$a1, 136($a0)
	sw	$a1, 196($a0)
	sw	$a1, 260($a0)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_eight:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 64($a0)
	sw	$a1, 72($a0)
	sw	$a1, 132($a0)
	sw	$a1, 192($a0)
	sw	$a1, 200($a0)
	sw	$a1, 256($a0)
	sw	$a1, 260($a0)
	sw	$a1, 264($a0)
	jr	$ra

# $a0 - $gp offset
# $a1 - color
draw_nine:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 64($a0)
	sw	$a1, 72($a0)
	sw	$a1, 128($a0)
	sw	$a1, 132($a0)
	sw	$a1, 136($a0)
	sw	$a1, 200($a0)
	sw	$a1, 256($a0)
	sw	$a1, 260($a0)
	sw	$a1, 264($a0)
	jr	$ra
	
# $a0 - $gp offset
# $a1 - color
# $a2 - rotation (unused for O piece)
draw_piece_O:
	sw	$a1, ($a0)
	sw	$a1, 4($a0)
	sw	$a1, 64($a0)
	sw	$a1, 68($a0)
	jr	$ra
	
# $a0 - $gp offset (top left corner of the rectangle the piece occupies)
# $a1 - color
# $a2 - rotation (0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees)
draw_piece_I:
	# rotation 0
	beq	$a2, 0, I_rotation_0
	beq	$a2, 1, I_rotation_1
	beq	$a2, 3, I_rotation_3

	I_rotation_2:	
		add	$a0, $a0, 64
	I_rotation_0:
		add	$a0, $a0, 64
		sw	$a1, ($a0)
		sw	$a1, 4($a0)
		sw	$a1, 8($a0)
		sw	$a1, 12($a0)
		jr	$ra
	
	I_rotation_1:
		add	$a0, $a0, 4
	I_rotation_3:
		add	$a0, $a0, 4
		sw	$a1, ($a0)
		sw	$a1, 64($a0)
		sw	$a1, 128($a0)
		sw	$a1, 192($a0)
		jr	$ra

# $a0 - $gp offset (top left corner of the rectangle the piece occupies)
# $a1 - color
# $a2 - rotation (0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees)
draw_piece_T:
	beq	$a2, 1, T_rotation_1
	beq	$a2, 2, T_rotation_2
	beq	$a2, 3, T_rotation_3
	
	T_rotation_0:
		sw	$a1, 4($a0)
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		sw	$a1, 72($a0)
		jr	$ra
	T_rotation_1:
		sw	$a1, 4($a0)
		sw	$a1, 68($a0)
		sw	$a1, 72($a0)
		sw	$a1, 132($a0)
		jr	$ra
	T_rotation_2:
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		sw	$a1, 72($a0)
		sw	$a1, 132($a0)
		jr	$ra
	T_rotation_3:
		sw	$a1, 4($a0)
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		sw	$a1, 132($a0)
		jr	$ra
	
# $a0 - $gp offset (top left corner of the square the piece and all its orientations occupies)
# $a1 - color
# $a2 - rotation (0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees)
draw_piece_S:
	beq	$a2, 0, S_rotation_0
	beq	$a2, 1, S_rotation_1
	beq	$a2, 3, S_rotation_3

	S_rotation_2:	
		add	$a0, $a0, 64
	S_rotation_0:
		sw	$a1, 4($a0)
		sw	$a1, 8($a0)
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		jr	$ra
	
	S_rotation_1:
		add	$a0, $a0, 4
	S_rotation_3:
		sw	$a1, ($a0)
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		sw	$a1, 132($a0)
		jr	$ra

	
# $a0 - $gp offset (top left corner of the square the piece and all its orientations occupies)
# $a1 - color
# $a2 - rotation (0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees)	
draw_piece_Z:
	beq	$a2, 0, Z_rotation_0
	beq	$a2, 1, Z_rotation_1
	beq	$a2, 3, Z_rotation_3
	
	Z_rotation_2:
		add	$a0, $a0, 64
	Z_rotation_0:
		sw	$a1, 0($a0)
		sw	$a1, 4($a0)
		sw	$a1, 68($a0)
		sw	$a1, 72($a0)
		jr	$ra
	
	Z_rotation_1:
		add	$a0, $a0, 4
	Z_rotation_3:
		sw	$a1, 4($a0)
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		sw	$a1, 128($a0)
		jr	$ra
	
# $a0 - $gp offset (top left corner of the square the piece and all its orientations occupies)
# $a1 - color
# $a2 - rotation (0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees)	
draw_piece_L:
	beq	$a2, 1, L_rotation_1
	beq	$a2, 2, L_rotation_2
	beq	$a2, 3, L_rotation_3
	
	L_rotation_0:
		sw	$a1, 8($a0)
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		sw	$a1, 72($a0)
		jr	$ra
	L_rotation_1:
		sw	$a1, 4($a0)
		sw	$a1, 68($a0)
		sw	$a1, 132($a0)
		sw	$a1, 136($a0)
		jr	$ra
	L_rotation_2:
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		sw	$a1, 72($a0)
		sw	$a1, 128($a0)
		jr	$ra
	L_rotation_3:
		sw	$a1, 0($a0)
		sw	$a1, 4($a0)
		sw	$a1, 68($a0)
		sw	$a1, 132($a0)
		jr	$ra
	
# $a0 - $gp offset (top left corner of the square the piece and all its orientations occupies)
# $a1 - color
# $a2 - rotation (0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees)	
draw_piece_J:
	beq	$a2, 1, J_rotation_1
	beq	$a2, 2, J_rotation_2
	beq	$a2, 3, J_rotation_3
	
	J_rotation_0:
		sw	$a1, ($a0)
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		sw	$a1, 72($a0)
		jr	$ra
	J_rotation_1:
		sw	$a1, 4($a0)
		sw	$a1, 8($a0)
		sw	$a1, 68($a0)
		sw	$a1, 132($a0)
		jr	$ra
	J_rotation_2:
		sw	$a1, 64($a0)
		sw	$a1, 68($a0)
		sw	$a1, 72($a0)
		sw	$a1, 136($a0)
		jr	$ra
	J_rotation_3:
		sw	$a1, 4($a0)
		sw	$a1, 68($a0)
		sw	$a1, 128($a0)
		sw	$a1, 132($a0)
		jr	$ra
	
generic_function_return:
	jr	$ra
	
generic_function_return_stack_pop:
	lw	$ra, ($sp)
	add	$sp, $sp, 4
	jr 	$ra