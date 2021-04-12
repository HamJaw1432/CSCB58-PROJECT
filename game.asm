######################################################################
# CSCB58 Winter2021Assembly Final Project
# University of Toronto, Scarborough
#
# Student: 
#
#
# Bitmap Display Configuration:
# -Unit width in pixels: 8
# -Unit height in pixels: 8
# -Display width in pixels: 256
# -Display height in pixels: 256
# -Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave beenreached in this submission?
# (See the assignment handout for descriptions of the milestones)
# -Milestone 4 (choose the one the applies)
#
# Which approved features have been implementedfor milestone 4?
# (See the assignment handout for the list of additional features)
# 1. objects get faster over time
# 2. score
# 3. smooth graphics
#
# Link to video demonstration for final submission:
# - https://play.library.utoronto.ca/d14b13cfd5d2e271be2c04d113289324
#
#Are you OK with us sharing the video with people outside course staff?
# -yes , https://github.com/HamJaw1432/CSCB58-PROJECT
#
# Any additional information that the TA needs to know:
# - The following are some minor changes made to the game after the recording
#	- New Colours
#	- Can restart after death
#	- Minor bug in collition fixed 
#
#####################################################################
.eqv	BASE_ADDRESS	0x10008000
.eqv 	KEYBOARD_PRESS	0xffff0000
.eqv	WHITE_COLOUR	0xffffff
.eqv	BLACK_COLOUR	0x000000
.eqv	RED_COLOUR	0xff0000
.eqv	OBJECT_COLOUR	0xB37A4C
.eqv	PLAYER_COLOUR	0x45B6FE
.eqv	TOTAL_UNITS	1024
 
 .data
Object_pos:	.word	0:32
Object_type: 	.word	5, 5, 5, 5, 12	
Player_pos:	.word	1928, 2184, 2060

.text

.globl main
main:
	li $s7, 10			# $s7 is player lives starts with 10
	li $s6, 0			# $s6 is player score starts with 0
	la $s5, Player_pos		# $s5 is player ship pos array address 
	la $s4, Object_pos		# $s4 is astroids pos array address
	la $s3, Object_type		# $s3 is astroids len array address 

restart:
	li $s7, 10			# $s7 is player lives starts with 10    
	li $s6, 0			# $s6 is player score starts with 0
	li $s1, 100			# $s1 is player speed
	jal clear_screen
	# init player pos
	li $t0, 1928
	li $t1, 2184
	li $t2, 2060
	sw $t0, 0($s5)
	sw $t1, 4($s5)
	sw $t2, 8($s5)

	# init all the asteroids
	li $a0, 0
	jal make_new_asteroids
	li $a0, 4
	jal make_new_asteroids
	li $a0, 8
	jal make_new_asteroids
	li $a0, 12
	jal make_new_asteroids
	li $a0, 16
	jal make_new_asteroids


	
	####################################
main_loop:
	# if lives == 0 end the game
	blez $s7, end_game
		
	li $v0, 32
	add $a0, $zero, $s1   # Wait one second (40 milliseconds)		###### HERE IS SPEED 
	syscall
	# erase previous locations
	jal erase_player	
	jal erase_objects
	jal erase_health

	# get player movement
	jal movement
	
	# update asteroid postion
	li $a0, 0
	jal update_asteroids
	beqz $v0, skip_1		# if $v0 is 1 that means we have reached the left side
	addi $s6, $s6, 1		# add 1 to score
	jal update_speed
	jal make_new_asteroids

skip_1:	
	# update asteroid postion
	li $a0, 4
	jal update_asteroids
	beqz $v0, skip_2		# if $v0 is 1 that means we have reached the left side
	addi $s6, $s6, 1		# add 1 to score
	jal update_speed
	jal make_new_asteroids

skip_2:	
	# update asteroid postion
	li $a0, 8
	jal update_asteroids
	beqz $v0, skip_3		# if $v0 is 1 that means we have reached the left side
	addi $s6, $s6, 1		# add 1 to score
	jal update_speed
	jal make_new_asteroids

skip_3:	
	# update asteroid postion
	li $a0, 12
	jal update_asteroids
	beqz $v0, skip_4		# if $v0 is 1 that means we have reached the left side
	addi $s6, $s6, 1		# add 1 to score
	jal update_speed	
	jal make_new_asteroids

skip_4:	
	# update asteroid postion
	li $a0, 16
	jal update_asteroids
	beqz $v0, skip_5		# if $v0 is 1 that means we have reached the left side
	addi $s6, $s6, 1		# add 1 to score
	jal update_speed
	jal make_new_asteroids
	

skip_5:




					
#	jal clear_screen	# clear the screen
	jal collision		# check for colision	

	jal draw_objects	# redarw new objects pos
	jal draw_player		# redarw new player pos
	jal draw_health
	
	# make delay to  make sure player knows they colided
	beq $s2, 0 skip_wait
	li $v0, 32
	li $a0, 1000   # Wait one second (1000 milliseconds)
	syscall
	
skip_wait:
	j main_loop		# restart loop
	#################################
	
 
end_game:	
	jal clear_screen	# clear the screen
	jal draw_gameover
	jal draw_score
wait_for_restart:	
	jal movement
	j wait_for_restart

	li $v0, 10 			# terminate the program gracefully
	syscall
	
######################################################	 FUNTION CLEAR SCREEN	#############################################
clear_screen:
	li $t0, TOTAL_UNITS		#
	li $t1, 0			# i counter
	li $t2, BASE_ADDRESS		# offset
	li $t3, BLACK_COLOUR
clear_screen_loop:	
	bge $t1, $t0, clear_screen_loop_break
	sw $t3, 0($t2)			# trun the pixel balck
	addi $t1, $t1, 1		# increment counter by 1
	addi $t2, $t2, 4		# increment by 4
	j clear_screen_loop		# loop to top
	
clear_screen_loop_break:	
	jr $ra
	
#############################################################################################################################
######################################################	 FUNTION DRAW PLAYER	#############################################
draw_player:
	li $t0, 3 			# number of pos units
	li $t1, 0			# i counter
	li $t2, BASE_ADDRESS		
	add $t3, $zero, $s5		# store player array
	beqz $s2, colour_not_collided	# set the colour if colided
	li $t4, RED_COLOUR		
	j draw_player_loop
colour_not_collided:
	li $t4, PLAYER_COLOUR
draw_player_loop:	
	bge $t1, $t0, draw_player_loop_break	
	li $t2, BASE_ADDRESS
	
	lw $t5, 0($t3)			# get offset form player array
	add $t2, $t2, $t5		# add to base
	sw $t4, 0($t2)			# store value on display
	addi $t1, $t1, 1		# incerment counter by 1
	addi $t3, $t3, 4		# increment by 4 for next pos
	j draw_player_loop
	
draw_player_loop_break:	
	jr $ra	


#############################################################################################################################
######################################################	 FUNTION MOVEMENT	#############################################
movement:
	li $t0, KEYBOARD_PRESS 
	lw $t1, 0($t0)
	bne $t1, 1, movement_end	# if $t1 i.e. keyboard_press is 0 leave funtion
	
	lw $t2, 4($t0) 			# this assumes $t9 is set to 0xfff0000from before
	
	beq $t2, 0x77, move_up		# ASCII code of 'w' is 0x77
	beq $t2, 0x61, move_left	# ASCII code of 'a' is 0x61
	beq $t2, 0x73, move_down	# ASCII code of 's' is 0x73
	beq $t2, 0x64, move_right	# ASCII code of 'd' is 0x64 
	beq $t2, 0x70, restart		# ASCII code of 'p' is 0x70
	j movement_end
	
move_up:
	lw $t3, 0($s5)
	addi $t3, $t3, -128		# subtract 128 to move pixel up
	ble $t3, $zero, movement_end	# check not outof bounds
	
	sw $t3, 0($s5)			# store the new location
	
	lw $t3, 4($s5) 
	addi $t3, $t3, -128 
	sw $t3, 4($s5)			# store the new location
	
	lw $t3, 8($s5) 
	addi $t3, $t3, -128
	sw $t3, 8($s5)			# store the new location
	
	
	j movement_end
	
move_down:
	lw $t3, 8($s5)
	addi $t3, $t3, 128		# add 128 to move pixel down
	li $t4, 3456
	bge $t3, $t4, movement_end	# check not outof bounds
	
	sw $t3, 8($s5)			# store the new location
	
	lw $t3, 4($s5) 
	addi $t3, $t3, 128
	sw $t3, 4($s5)			# store the new location
	
	lw $t3, 0($s5) 
	addi $t3, $t3, 128
	sw $t3, 0($s5)			# store the new location
	
	
	j movement_end	
			
move_left:	
	lw $t3, 0($s5)
	addi $t3, $t3, -4		# sutract 4 to move pixel left
	li $t4, 4
	
	li $t5, 128
	div $t3, $t5			# calculate x index
	mfhi $t3
	
	ble $t3, $t4, movement_end	# check not outof bounds
	
	lw $t3, 0($s5)
	addi $t3, $t3, -4
	sw $t3, 0($s5)			# store the new location
	
	lw $t3, 4($s5) 
	addi $t3, $t3, -4
	sw $t3, 4($s5)			# store the new location
	
	lw $t3, 8($s5) 
	addi $t3, $t3, -4
	sw $t3, 8($s5)			# store the new location
	
	
	j movement_end
	
move_right:	
	lw $t3, 8($s5)
	addi $t3, $t3, 4		# add 4 to move pixel right
	li $t4, 128
	li $t5, 124			# calculate x index
	div $t3, $t4 
	mfhi $t3
		
	bge $t3, $t5, movement_end	# check not outof bounds
	
	lw $t3, 8($s5)
	addi $t3, $t3, 4
	sw $t3, 8($s5)			# store the new location
	
	lw $t3, 0($s5) 
	addi $t3, $t3, 4
	sw $t3, 0($s5)			# store the new location
	
	lw $t3, 4($s5) 
	addi $t3, $t3, 4
	sw $t3, 4($s5)			# store the new location
	
	
	j movement_end
	
movement_end:	
	jr $ra	


#############################################################################################################################
#######################################		 FUNTION UPDATE ASTEROIDS	#############################################
update_asteroids:
	
	la $t0, Object_type		# load object type array
	add $t0, $t0, $a0		# move by offset
	move $t1, $a0			
	li, $v0, 0			
	
	li $t2, 0
	li $t3, 0
	la $t4, Object_type
corrisponding_pos_start_in_update:
	# move pointer to the start of the object in the object pos array
	bge $t3, $t1, corrisponding_pos_start_end_in_update
	
	lw $t5, 0($t4)			# get the first object type
	add $t2, $t2, $t5
	
	addi $t4, $t4, 4
	addi $t3, $t3, 4
	j corrisponding_pos_start_in_update
	
corrisponding_pos_start_end_in_update:
	li $t5, 4
	mult $t2, $t5
	mflo $t2
		
	la $t5, Object_pos
	add $t2, $t2, $t5
	
	lw $t4, 0($t0)
	beq $t4, 5, small_asteroid_in_update 
	
	# get x coordinate
	lw $t6, 0($t2)
	addi $t6, $t6, -4
	li $t4, 0
	
	li $t5, 128
	div $t6, $t5  
	mfhi $t3
	
	ble $t3, $t4, update_asteroids_end	# check if its valid
	
	lw $t3, 0($t2)
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 0($t2)			# store the new location
	
	lw $t3, 4($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 4($t2)			# store the new location
	
	lw $t3, 8($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 8($t2)			# store the new location
	
	lw $t3, 12($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 12($t2)			# store the new location
	
	lw $t3, 16($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 16($t2)			# store the new location
	
	lw $t3, 20($t2)
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 20($t2)			# store the new location
	
	lw $t3, 24($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 24($t2)			# store the new location
	
	lw $t3, 28($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 28($t2)			# store the new location
	
	lw $t3, 32($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 32($t2)			# store the new location
	
	lw $t3, 36($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 36($t2)			# store the new location
	
	lw $t3, 40($t2)
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 40($t2)			# store the new location
	
	lw $t3, 44($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 44($t2)			# store the new location
	
	jr $ra
	
small_asteroid_in_update:
	# get x coordinate
	lw $t6, 4($t2)
	addi $t6, $t6, -4
	li $t4, 0
	
	li $t5, 128
	div $t6, $t5  
	mfhi $t3
	
	ble $t3, $t4, update_asteroids_end	# check if its valid
	
	lw $t3, 0($t2)
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 0($t2)			# store the new location
	
	lw $t3, 4($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 4($t2)			# store the new location
				
	lw $t3, 8($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 8($t2)			# store the new location
	
	lw $t3, 12($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 12($t2)			# store the new location
	
	lw $t3, 16($t2) 
	addi $t3, $t3, -4		# move to left 1 unit
	sw $t3, 16($t2)			# store the new location
	
	jr $ra
	
update_asteroids_end:
	li, $v0, 1	
	jr $ra	




#############################################################################################################################
#######################################		 FUNTION MAKE NEW ASTEROIDS		#####################################
make_new_asteroids:
	
	la $t0, Object_type		# load object type array 
	add $t0, $t0, $a0		# add the offset
	move $t1, $a0
	 
	li $v0, 42
	li $a0, 0
	li $a1, 27
	syscall				# get a random start location y dir
	
	li $t2, 128
	
	mult $t2, $a0
	mflo $t2	
	
	addi $t2, $t2, 88		# move 88 units to the right from the left side
	
	li $v0, 42
	li $a0, 0
	li $a1, 5
	syscall				# get a random start location x dir
	
	li $t3, 4
	
	mult $t3, $a0
	mflo $t3
	
	add $t2, $t2, $t3		# move the random units to the right
	

	li $t3, 0
	li $t6, 0
	la $t4, Object_type
corrisponding_pos_start:
	# move pointer to the start of the object in the object pos array
	bge $t6, $t1, corrisponding_pos_start_end
	
	lw $t5, 0($t4)
	add $t3, $t3, $t5
	
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	j corrisponding_pos_start
	
corrisponding_pos_start_end:
	li $t5, 4
	mult $t3, $t5
	mflo $t3
		
	la $t5, Object_pos
	add $t3, $t3, $t5
		
	lw $t4, 0($t0)
	beq $t4, 5, small_asteroid 
	
	# make large asteroid
	sw $t2, 0($t3)
	
	addi $t3, $t3, 4
	addi $t2, $t2, 20	# move to next location
	sw $t2, 0($t3)		
	
	addi $t3, $t3, 4
	addi $t2, $t2, 112	# move to next location
	sw $t2, 0($t3)
	
	addi $t3, $t3, 4
	addi $t2, $t2, 12	# move to next location
	sw $t2, 0($t3)

	addi $t3, $t3, 4
	addi $t2, $t2, 120	# move to next location
	sw $t2, 0($t3)
	
	addi $t3, $t3, 4
	addi $t2, $t2, 4	# move to next location
	sw $t2, 0($t3)
	
	addi $t3, $t3, 4
	addi $t2, $t2, 124	# move to next location
	sw $t2, 0($t3)
	
	addi $t3, $t3, 4
	addi $t2, $t2, 4	# move to next location
	sw $t2, 0($t3)
	
	addi $t3, $t3, 4
	addi $t2, $t2, 120	# move to next location
	sw $t2, 0($t3) 
	
	addi $t3, $t3, 4
	addi $t2, $t2, 12	# move to next location
	sw $t2, 0($t3) 
	
	addi $t3, $t3, 4
	addi $t2, $t2, 112	# move to next location
	sw $t2, 0($t3) 
	
	addi $t3, $t3, 4
	addi $t2, $t2, 20	# move to next location
	sw $t2, 0($t3) 
	
	jr $ra	
	
small_asteroid:
	# make small asteroid 
	sw $t2, 0($t3)
	addi $t3, $t3, 4
	addi $t2, $t2, 124	# move to next location
	sw $t2, 0($t3)
	addi $t3, $t3, 4
	addi $t2, $t2, 4	# move to next location
	sw $t2, 0($t3)
	addi $t3, $t3, 4
	addi $t2, $t2, 4	# move to next location
	sw $t2, 0($t3)
	addi $t3, $t3, 4
	addi $t2, $t2, 124	# move to next location
	sw $t2, 0($t3)


make_new_asteroids_end:	
	jr $ra	

#############################################################################################################################
######################################################	 FUNTION DRAW OBJECTS	#############################################
draw_objects:
	li $t0, 32 			# number of pos units
	li $t1, 0			# i counter
	li $t2, BASE_ADDRESS		
	add $t3, $zero, $s4
	li $t4, OBJECT_COLOUR
draw_objects_loop:	
	# loop through the objects pos array and draw it to the display
	bge $t1, $t0, draw_objects_loop_break
	li $t2, BASE_ADDRESS
	
	lw $t5, 0($t3)
	add $t2, $t2, $t5
	sw $t4, 0($t2)
	addi $t1, $t1, 1
	addi $t3, $t3, 4
	j draw_objects_loop
	
draw_objects_loop_break:	
	jr $ra	


#############################################################################################################################
######################################################	 FUNTION COLLISION	#############################################
collision:
	li $t0, 3			# number of player pos units
	li $t1, 32  			# number of object pos units
	li $t2, 0			# i counter
	li $t3, 0			# j counter
	add $t4, $zero, $s4		# object pos array
	add $t5, $zero, $s5		# player pos array 
collision_loop:	
	# loop over each object 
	bge $t2, $t0, collision_loop_break
	li $t3, 0			# j counter
	add $t4, $zero, $s4		# object pos array
	lw $t6, 0($t5)
collision_inner_loop:	
	# check for a colision with each object pos
	bge $t3, $t1, collision_inner_loop_break
	
	lw $t7, 0($t4)
	beq $t6, $t7, has_collision
	# increment var
	addi $t3, $t3, 1
	addi $t4, $t4, 4
	j collision_inner_loop
collision_inner_loop_break:
	# increment var
	addi $t2, $t2, 1
	addi $t5, $t5, 4
	j collision_loop
	
collision_loop_break:
	li $s2, 0	
	jr $ra	

has_collision:
	# check to see if colision is new if so lose health 
	beq $s2, 1, health_not_lost
	addi $s7, $s7, -1
	
health_not_lost:
	li $s2, 1
	jr $ra

#############################################################################################################################
######################################################	 FUNTION DRAW HEALTH	#############################################
draw_health:			
	li $t1, 0			# i counter
	li $t2, BASE_ADDRESS		
	# make H symbol
	addi $t2, $t2, 3588
	li $t4, RED_COLOUR
	sw $t4, 0($t2)
	sw $t4, 8($t2)
	sw $t4, 128($t2)
	sw $t4, 132($t2)
	sw $t4, 136($t2)
	sw $t4, 256($t2)
	sw $t4, 264($t2)
	addi $t2, $t2, 144
draw_health_loop:	
	# loop thorugh to make the health bar
	bge $t1, $s7, draw_objects_loop_break
	sw $t4, 0($t2)
	sw $t4, 4($t2)
	# increment i and the offset
	addi $t2, $t2, 8
	addi $t1, $t1, 1		# increment i
	j draw_health_loop
	
draw_health_loop_break:	
	jr $ra	
#############################################################################################################################
######################################################	 FUNTION DRAW GAMEOVER	#############################################
draw_gameover:			
	li $t1, 0			# i counter
	li $t2, BASE_ADDRESS	
	addi $t2, $t2, 136	
	# make H symbol
	li $t4, WHITE_COLOUR
	
	# G
	sw $t4, 0($t2)
	sw $t4, 4($t2)
	sw $t4, 8($t2)
	# A
	sw $t4, 16($t2)
	sw $t4, 20($t2)
	sw $t4, 24($t2)
	# M
	sw $t4, 32($t2)
	sw $t4, 36($t2)
	sw $t4, 44($t2)
	sw $t4, 48($t2)
	# E
	sw $t4, 56($t2)
	sw $t4, 60($t2)
	sw $t4, 64($t2)
	addi $t2, $t2, 128
	
	sw $t4, 0($t2)
	sw $t4, 8($t2)
	sw $t4, 16($t2)
	sw $t4, 24($t2)
	sw $t4, 32($t2)
	sw $t4, 40($t2)
	sw $t4, 48($t2)
	sw $t4, 56($t2)
	addi $t2, $t2, 128
	
	# G
	sw $t4, 0($t2)
	sw $t4, 4($t2)
	sw $t4, 8($t2)
	# A
	sw $t4, 16($t2)
	sw $t4, 20($t2)
	sw $t4, 24($t2)
	# M
	sw $t4, 32($t2)
	sw $t4, 48($t2)
	# E
	sw $t4, 56($t2)
	sw $t4, 60($t2)
	sw $t4, 64($t2)
	addi $t2, $t2, 128
	
	# G
	sw $t4, 8($t2)
	# A
	sw $t4, 16($t2)
	sw $t4, 24($t2)
	# M
	sw $t4, 32($t2)
	sw $t4, 48($t2)
	# E
	sw $t4, 56($t2)
	addi $t2, $t2, 128
	
	# G
	sw $t4, 0($t2)
	sw $t4, 4($t2)
	sw $t4, 8($t2)
	# A
	sw $t4, 16($t2)
	sw $t4, 24($t2)
	# M
	sw $t4, 32($t2)
	sw $t4, 48($t2)
	# E
	sw $t4, 56($t2)
	sw $t4, 60($t2)
	sw $t4, 64($t2)
	addi $t2, $t2, 128
	
	addi $t2, $t2, 128
	
	############################################
	#O
	sw $t4, 32($t2)
	sw $t4, 36($t2)
	sw $t4, 40($t2)
	#V
	sw $t4, 48($t2)
	sw $t4, 64($t2)
	#E
	sw $t4, 72($t2)
	sw $t4, 76($t2)
	sw $t4, 80($t2)
	#R
	sw $t4, 88($t2)
	sw $t4, 92($t2)
	sw $t4, 96($t2)
	addi $t2, $t2, 128
	###########################################
	############################################
	#O
	sw $t4, 32($t2)
	sw $t4, 40($t2)
	#V
	sw $t4, 48($t2)
	sw $t4, 64($t2)
	#E
	sw $t4, 72($t2)
	#R
	sw $t4, 88($t2)
	sw $t4, 96($t2)
	addi $t2, $t2, 128
	###########################################
	############################################
	#O
	sw $t4, 32($t2)
	sw $t4, 40($t2)
	#V
	sw $t4, 52($t2)
	sw $t4, 60($t2)
	#E
	sw $t4, 72($t2)
	sw $t4, 76($t2)
	sw $t4, 80($t2)
	#R
	sw $t4, 88($t2)
	sw $t4, 92($t2)
	sw $t4, 96($t2)
	addi $t2, $t2, 128
	###########################################
	############################################
	#O
	sw $t4, 32($t2)
	sw $t4, 40($t2)
	#V
	sw $t4, 52($t2)
	sw $t4, 60($t2)
	#E
	sw $t4, 72($t2)
	#R
	sw $t4, 88($t2)
	sw $t4, 92($t2)
	addi $t2, $t2, 128
	###########################################
	############################################
	#O
	sw $t4, 32($t2)
	sw $t4, 36($t2)
	sw $t4, 40($t2)
	#V
	sw $t4, 56($t2)
	#E
	sw $t4, 72($t2)
	sw $t4, 76($t2)
	sw $t4, 80($t2)
	#R
	sw $t4, 88($t2)
	sw $t4, 96($t2)
	addi $t2, $t2, 128
	###########################################
	addi $t2, $t2, 128
	
	###########################################
	# S
	sw $t4, 0($t2)
	sw $t4, 4($t2)
	sw $t4, 8($t2)
	# C
	sw $t4, 16($t2)
	sw $t4, 20($t2)
	sw $t4, 24($t2)
	# O
	sw $t4, 32($t2)
	sw $t4, 36($t2)
	sw $t4, 40($t2)
	# R
	sw $t4, 48($t2)
	sw $t4, 52($t2)
	sw $t4, 56($t2)
	# E
	sw $t4, 64($t2)
	sw $t4, 68($t2)
	sw $t4, 72($t2)
	# :
	addi $t2, $t2, 128
	###########################################
	###########################################
	# S
	sw $t4, 0($t2)
	# C
	sw $t4, 16($t2)
	# O
	sw $t4, 32($t2)
	sw $t4, 40($t2)
	# R
	sw $t4, 48($t2)
	sw $t4, 56($t2)
	# E
	sw $t4, 64($t2)
	# :
	sw $t4, 80($t2)
	addi $t2, $t2, 128
	###########################################
	###########################################
	# S
	sw $t4, 0($t2)
	sw $t4, 4($t2)
	sw $t4, 8($t2)
	# C
	sw $t4, 16($t2)
	# O
	sw $t4, 32($t2)
	sw $t4, 40($t2)
	# R
	sw $t4, 48($t2)
	sw $t4, 52($t2)
	sw $t4, 56($t2)
	# E
	sw $t4, 64($t2)
	sw $t4, 68($t2)
	sw $t4, 72($t2)
	# :
	addi $t2, $t2, 128
	###########################################
	###########################################
	# S
	sw $t4, 8($t2)
	# C
	sw $t4, 16($t2)
	# O
	sw $t4, 32($t2)
	sw $t4, 40($t2)
	# R
	sw $t4, 48($t2)
	sw $t4, 52($t2)
	# E
	sw $t4, 64($t2)
	# :
	sw $t4, 80($t2)
	addi $t2, $t2, 128
	###########################################
	###########################################
	# S
	sw $t4, 0($t2)
	sw $t4, 4($t2)
	sw $t4, 8($t2)
	# C
	sw $t4, 16($t2)
	sw $t4, 20($t2)
	sw $t4, 24($t2)
	# O
	sw $t4, 32($t2)
	sw $t4, 36($t2)
	sw $t4, 40($t2)
	# R
	sw $t4, 48($t2)
	sw $t4, 56($t2)
	# E
	sw $t4, 64($t2)
	sw $t4, 68($t2)
	sw $t4, 72($t2)
	# :
	addi $t2, $t2, 128
	###########################################
	jr $ra	
#############################################################################################################################
######################################################	 FUNTION DRAW SCORE	#############################################
draw_score:
	li $t0, WHITE_COLOUR
	li $t1, 0
	li $t2, 6
	li $t6, 2540
	addi $t6, $t6, BASE_ADDRESS
	
draw_score_loop:	
	bge $t1, $t2, draw_score_loop_break
	li $t3, 0
	li $t4, 1
	li $t5, 10
power_loop:
	# calculate 10^n
	bge $t3, $t1, power_loop_end
	
	mult $t4, $t5
	mflo $t4		
	addi $t3, $t3, 1
	
	j power_loop		
power_loop_end:
	div $s6, $t4
	mflo $t4 			# score / 10^n
	div $t4, $t5			
	mfhi $t4			# (score / 10^n) % 10
	
	beq $t4, 0, isZero		# if n dight is 0
	beq $t4, 1, isOne		# if n dight is 1
	beq $t4, 2, isTwo		# if n dight is 2
	beq $t4, 3, isThree		# if n dight is 3
	beq $t4, 4, isFour		# if n dight is 4
	beq $t4, 5, isFive		# if n dight is 5
	beq $t4, 6, isSix		# if n dight is 6
	beq $t4, 7, isSeven		# if n dight is 7
	beq $t4, 8, isEight		# if n dight is 8
	beq $t4, 9, isNine		# if n dight is 9
isZero:
	# display 0
	sw $t0, 0($t6)
	sw $t0, 4($t6)
	sw $t0, 8($t6)
	sw $t0, 12($t6)
	sw $t0, 128($t6)
	sw $t0, 140($t6)
	sw $t0, 256($t6)
	sw $t0, 268($t6)
	sw $t0, 384($t6)
	sw $t0, 396($t6)
	sw $t0, 512($t6)
	sw $t0, 524($t6)
	sw $t0, 640($t6)
	sw $t0, 652($t6)
	sw $t0, 768($t6)
	sw $t0, 772($t6)
	sw $t0, 776($t6)
	sw $t0, 780($t6)
	j print_end
	
isOne:
	# display 1
	sw $t0, 12($t6)
	sw $t0, 140($t6)
	sw $t0, 268($t6)
	sw $t0, 396($t6)
	sw $t0, 524($t6)
	sw $t0, 652($t6)
	sw $t0, 780($t6)
	j print_end
	
isTwo:
	# display 2
	sw $t0, 0($t6)
	sw $t0, 4($t6)
	sw $t0, 8($t6)
	sw $t0, 12($t6)
	sw $t0, 140($t6)
	sw $t0, 268($t6)
	sw $t0, 384($t6)
	sw $t0, 388($t6)
	sw $t0, 392($t6)
	sw $t0, 396($t6)
	sw $t0, 512($t6)
	sw $t0, 640($t6)
	sw $t0, 768($t6)
	sw $t0, 772($t6)
	sw $t0, 776($t6)
	sw $t0, 780($t6)
	j print_end
	
isThree:
	# display 3
	sw $t0, 0($t6)
	sw $t0, 4($t6)
	sw $t0, 8($t6)
	sw $t0, 12($t6)
	sw $t0, 140($t6)
	sw $t0, 268($t6)
	sw $t0, 384($t6)
	sw $t0, 388($t6)
	sw $t0, 392($t6)
	sw $t0, 396($t6)
	sw $t0, 524($t6)
	sw $t0, 652($t6)
	sw $t0, 768($t6)
	sw $t0, 772($t6)
	sw $t0, 776($t6)
	sw $t0, 780($t6)
	j print_end
	
isFour:
	# display 4
	sw $t0, 0($t6)
	sw $t0, 12($t6)
	sw $t0, 128($t6)
	sw $t0, 140($t6)
	sw $t0, 256($t6)
	sw $t0, 268($t6)
	sw $t0, 384($t6)
	sw $t0, 388($t6)
	sw $t0, 392($t6)
	sw $t0, 396($t6)
	sw $t0, 524($t6)
	sw $t0, 652($t6)
	sw $t0, 780($t6)
	j print_end
	
isFive:
	# display 5
	sw $t0, 0($t6)
	sw $t0, 4($t6)
	sw $t0, 8($t6)
	sw $t0, 12($t6)
	sw $t0, 140($t6)
	sw $t0, 268($t6)
	sw $t0, 384($t6)
	sw $t0, 388($t6)
	sw $t0, 392($t6)
	sw $t0, 396($t6)
	sw $t0, 524($t6)
	sw $t0, 652($t6)
	sw $t0, 768($t6)
	sw $t0, 772($t6)
	sw $t0, 776($t6)
	sw $t0, 780($t6)
	j print_end

isSix:
	# display 6
	sw $t0, 0($t6)
	sw $t0, 4($t6)
	sw $t0, 8($t6)
	sw $t0, 12($t6)
	sw $t0, 128($t6)
	sw $t0, 256($t6)
	sw $t0, 384($t6)
	sw $t0, 388($t6)
	sw $t0, 392($t6)
	sw $t0, 396($t6)
	sw $t0, 512($t6)
	sw $t0, 524($t6)
	sw $t0, 640($t6)
	sw $t0, 652($t6)
	sw $t0, 768($t6)
	sw $t0, 772($t6)
	sw $t0, 776($t6)
	sw $t0, 780($t6)
	j print_end
	

isSeven:
	# display 7
	sw $t0, 0($t6)
	sw $t0, 4($t6)
	sw $t0, 8($t6)
	sw $t0, 12($t6)
	sw $t0, 140($t6)
	sw $t0, 268($t6)
	sw $t0, 396($t6)
	sw $t0, 524($t6)
	sw $t0, 652($t6)
	sw $t0, 780($t6)
	j print_end

isEight:
	# display 8
	sw $t0, 0($t6)
	sw $t0, 4($t6)
	sw $t0, 8($t6)
	sw $t0, 12($t6)
	sw $t0, 128($t6)
	sw $t0, 140($t6)
	sw $t0, 256($t6)
	sw $t0, 268($t6)
	sw $t0, 384($t6)
	sw $t0, 388($t6)
	sw $t0, 392($t6)
	sw $t0, 396($t6)
	sw $t0, 512($t6)
	sw $t0, 524($t6)
	sw $t0, 640($t6)
	sw $t0, 652($t6)
	sw $t0, 768($t6)
	sw $t0, 772($t6)
	sw $t0, 776($t6)
	sw $t0, 780($t6)
	j print_end


isNine:
	# display 9
	sw $t0, 0($t6)
	sw $t0, 4($t6)
	sw $t0, 8($t6)
	sw $t0, 12($t6)
	sw $t0, 128($t6)
	sw $t0, 140($t6)
	sw $t0, 256($t6)
	sw $t0, 268($t6)
	sw $t0, 384($t6)
	sw $t0, 388($t6)
	sw $t0, 392($t6)
	sw $t0, 396($t6)
	sw $t0, 524($t6)
	sw $t0, 652($t6)
	sw $t0, 780($t6)
	
print_end:
	addi $t6, $t6, -20 	
	addi $t1, $t1, 1
	j draw_score_loop
draw_score_loop_break:	
	jr $ra	


#############################################################################################################################
######################################################	 FUNTION UPDATE SPEED	#############################################
update_speed:			
	
	li $t0, 5
	div $s6, $t0
	mfhi $t1
	bnez $t1, update_speed_end
	
	addi $t2, $s1, -1
	blez $t2, update_speed_end
	addi $s1, $s1, -1
	
update_speed_end:	
	jr $ra	
#############################################################################################################################
######################################################	 FUNTION ERASE OBJECTS	#############################################
erase_objects:
	li $t0, 32 			# number of pos units
	li $t1, 0			# i counter
	li $t2, BASE_ADDRESS		
	add $t3, $zero, $s4
	li $t4, BLACK_COLOUR
erase_objects_loop:	
	# loop through the objects pos array and erase it to the display
	bge $t1, $t0, erase_objects_loop_break
	li $t2, BASE_ADDRESS
	
	lw $t5, 0($t3)
	add $t2, $t2, $t5
	sw $t4, 0($t2)
	addi $t1, $t1, 1
	addi $t3, $t3, 4
	j erase_objects_loop
	
erase_objects_loop_break:	
	jr $ra	


#############################################################################################################################
######################################################	 FUNTION ERASE PLAYER	#############################################
erase_player:
	li $t0, 3 			# number of pos units
	li $t1, 0			# i counter
	li $t2, BASE_ADDRESS		
	add $t3, $zero, $s5		# store player array
	li $t4, BLACK_COLOUR
erase_player_loop:	
	bge $t1, $t0, erase_player_loop_break	
	li $t2, BASE_ADDRESS
	
	lw $t5, 0($t3)			# get offset form player array
	add $t2, $t2, $t5		# add to base
	sw $t4, 0($t2)			# store value on display
	addi $t1, $t1, 1		# incerment counter by 1
	addi $t3, $t3, 4		# increment by 4 for next pos
	j erase_player_loop
	
erase_player_loop_break:	
	jr $ra	


#############################################################################################################################
######################################################	 FUNTION ERASE HEALTH	#############################################
erase_health:			
	li $t1, 0			# i counter
	li $t2, BASE_ADDRESS		
	# make H symbol
	addi $t2, $t2, 3588
	li $t4, BLACK_COLOUR
	addi $t2, $t2, 144
erase_health_loop:	
	# loop through to erase the health bar
	bge $t1, $s7, erase_objects_loop_break
	sw $t4, 0($t2)
	sw $t4, 4($t2)
	addi $t2, $t2, 8
	addi $t1, $t1, 1
	j erase_health_loop
	
erase_health_loop_break:	
	jr $ra	
#############################################################################################################################
