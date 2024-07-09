.eqv HEADING 0xffff8010 	# Integer: An angle between 0 and 359
 				# 0 : North (up)
				# 90: East (right)
 				# 180: South (down)
 				# 270: West (left)
.eqv MOVING 0xffff8050 	# Boolean: whether or not to move
.eqv LEAVETRACK 0xffff8020 	# Boolean (0 or non-0):
 				# whether or not to leave a track
.eqv WHEREX 0xffff8030 	# Integer: Current x-location of MarsBot
.eqv WHEREY 0xffff8040 	# Integer: Current y-location of MarsBot
.eqv IN_ADRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADRESS_HEXA_KEYBOARD 0xFFFF0014
.data
postscript1: .word 90,3000,0,180,3000,0,180,6500,1,60,2000,1,30,1500,1,0,1500,1,340,2000,1,300,1520,1,270,500,1,90,8000,0,270,1500,1,240,1500,1,210,1500,1,180,1700,1,150,1500,1,120,1500,1,90,1500,1,90,2000,0,0,6000,1,90,2500,1,180,3000,0,270,2500,1,180,3000,0,90,2500,1,180,1000,0,-1 #DCE
postscript2: .word 90,3000,0,180,3000,0,90,1000,1,135,1440,1,315,1440,0,270,1000,0,225,1440,1,180,1000,1,135,1440,1,90,1000,1,135,1440,1,180,1000,1,225,1440,1,270,1000,1,315,1440,1,135,1440,0,90,4000,0,90,1000,1,45,1440,1,0,1000,1,315,1440,1,270,1000,1,225,1440,1,180,1000,1,135,1440,1,90,3000,0,0,6000,1,90,4000,0,270,1500,1,240,1500,1,210,1500,1,180,1700,1,150,1500,1,120,1500,1,90,1500,1,90,3000,0,0,6000,1,270,1500,0,90,3000,1,-1,-1,-1 
postscript3: .word 90,3000,0,180,3000,0,180,6000,1,90,6000,1,0,6000,1,270,6000,1,90,1000,0,180,1000,0,90,1000,1,180,1000,1,270,1000,1,0,1000,1,90,3000,0,90,1000,1,180,1000,1,270,1000,1,0,1000,1,270,4000,0,180,1500,0,90,2750,0,90,500,1,180,1000,1,270,500,1,0,1000,1,270,2750,0,180,1500,0,90,2000,0,90,2000,1,180,1000,1,270,2000,1,0,1000,1,270,2000,0,0,4000,0,315,1500,1,90,500,1,135,1500,1,90,5500,0,45,1500,1,270,500,1,225,1500,1,-1,-1,-1 #robot

.text
main:
	li $t1, IN_ADRESS_HEXA_KEYBOARD	#Address of keyboard Digital Lab Sim
 	li $t2, OUT_ADRESS_HEXA_KEYBOARD	#Address of button
polling: 					#Scan signal on Digital Lab Sim
 reset:						
	li $t3, 0x1 
 loop:	
 	beq $t3, 0x8, reset
 	nop
	sb $t3, 0($t1 ) # must reassign expected row
 	lb $a0, 0($t2) # read scan code of key button
	bnez $a0, select_postscript 
	nop
	sll $t3,$t3,1
	j loop
	nop
 select_postscript:
 	beq $a0, 0x11, select1 #If press 0 -> run Postscript1
 	nop
 	beq $a0, 0x12, select2 #if press 4 -> run postscript2
 	nop
 	beq $a0, 0x14, select3 #if press 8 -> run postscript3
 	nop
 	j reset
 	nop
 select1:
 	la $v1, postscript1
 	j CNC
 	nop
 select2:
 	la $v1, postscript2
 	j CNC
 	nop
 select3:
 	la $v1, postscript3
CNC: 				#Start cut
 	lw $a1, 0($v1) #Rotation
 	lw $a0, 4($v1) #Time
 	lw $a2, 8($v1) #Cut/No Cut
 	addi $v1, $v1, 12
 check_postscript:
 	beq $a1, -1, end_main #Mark -1 to end
 	nop
 	beq $a0, -1, end_main
 	nop
 	beq $a2, -1, end_main
 	nop
 run_postscript:
 	jal ROTATE  		#Turn with rotation 
 	nop
 	beq $a2, 1, TRACK	#Select cut/no cut
 	nop
  cont:
  	jal GO			#Robot run in orbit
 	nop
 	li $v0, 32		#Time that robot run in orbit
 	syscall
 	jal STOP		#Robot stop
 	nop
 	jal UNTRACK		#Stop cutting
 	nop
 	j CNC			#Update new orbit
 	nop
end_main:
	li $v0,10		
	syscall
#-----------------------------------------------------------
# GO procedure, to start running
# param[in] none
#-----------------------------------------------------------
GO: 
	li $at, MOVING # change MOVING port
 	addi $k0, $zero,1 # to logic 1,
 	sb $k0, 0($at) # to start running
 	nop 
 	jr $ra
 	nop
#-----------------------------------------------------------
# STOP procedure, to stop running
# param[in] none
#------------------------------------------------------------
STOP: 
	li $at, MOVING # change MOVING port to 0
 	sb $zero, 0($at) # to stop
 	nop
 	jr $ra
 	nop
#-----------------------------------------------------------
# TRACK procedure, to start drawing line 
# param[in] none
#----------------------------------------------------------- 
TRACK: 
	li $at, LEAVETRACK # change LEAVETRACK port
 	addi $k0, $zero,1 # to logic 1,
 	sb $k0, 0($at) # to start tracking
 	nop
 	j cont
 	nop 
#-----------------------------------------------------------
# UNTRACK procedure, to stop drawing line
# param[in] none
#----------------------------------------------------------- 
UNTRACK:
	li $at, LEAVETRACK # change LEAVETRACK port to 0
 	sb $zero, 0($at) # to stop drawing tail
 	nop
 	jr $ra
 	nop
#-----------------------------------------------------------
# ROTATE procedure, to rotate the robot
# param[in] $a1, An angle between 0 and 359
# 0 : North (up)
# 90: East (right)
# 180: South (down)
# 270: West (left)
#-----------------------------------------------------------
ROTATE: 
	li $at, HEADING # change HEADING port
 	sw $a1, 0($at) # to rotate robot
 	nop
 	jr $ra
 	nop
