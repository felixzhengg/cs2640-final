# CS 2640 - Wordle Final Project
# Spencer Davis, Felix Zheng, Aniket Subramanian, Jesston Li 
# Part 4 - Guess Comparison and Feedback; Jesston

# Macro (Guess Comparison & Feedback)

# $v0 = 1 means you won, 0 otherwise
.macro compareGuess(%secretWord, %guessWord)
	la $a0, %secretWord
	la $a1, %guessWord
	la $a2, feedbackStr
	la $a3, usedSlots

# exact/correct matches are marked with "G" for green
	li $t0, 0 # i = 0
	li $t9, 0 # number of greens starts with 0

greenLoop:
	beq $t0, 5, yellowStart

	add $t1, $a0, $t0
	lb $t2, 0($t1) # secret word character, $t1 is the start of the word + i

	add $t1, $a1, $t0
	lb $t3, 0($t1) # guess word character

	li $t4, '-' # Default/Incorrect letter representation, since "G" will represent green, "-" will have to represent gray.
	li $t5, 0 #slots

	bne $t2, $t3, saveSlot
	li $t4, 'G' # Correct letters are marked G
	li $t5, 1 #used a slot
	addi $t9, $t9, 1

saveSlot:
	add $t1, $a2, $t0
	sb $t4, 0($t1) # stores the result for feedback

	add $t1, $a3, $t0
	sb $t5, 0($t1) # stores used slot

	addi $t0, $t0, 1
	j greenLoop

# correct but misplaced letters are marked as "Y" representing yellow
yellowStart:
	li $t0, 0 # i = 0 again

yellowOuter:
	beq $t0, 5, finalizeComparison

	add $t1, $a2, $t0
	lb $t2, 0($t1)
	beq $t2, 'G', finalOuter # this skips letters that were already marked as green "G"

	add $t1, $a1, $t0
	lb $t3, 0($t1)
	li $t4, 0 # x = 0, this represents the index for the secret wrod

yellowInner:
	beq $t4, 5, finalOuter

	add $t5, $a3, $t4
	lb $t6, 0($t5)
	bnez $t6, finalInner # skips used slots for the secret word, basically means characters that are already marked are skipped

	add $t6, $a0, $t4
	lb $t7, 0($t6)#secret word character with its "x" index
	bne $t3, $t7, finalInner

# this part actually marks the letter yellow and used
	add $t1, $a2, $t0
	li $t2, 'Y'
	sb $t2, 0($t1)

	li $t6, 1
	sb $t6, 0($t5) #used slot with index
	j finalOuter

finalInner:
	addi $t4, $t4, 1
	j yellowInner

finalOuter:
	addi $t0, $t0, 1
	j yellowOuter

# prints feedback and checks if the user won when the guess is marked all green/G
finalizeComparison:
	sb $zero, 5($a2) #stops the print right after printing the feedback string by adding null
	li $v0, 4
	la $a0, feedbackText #prints the feedback text along with the feedback string
	syscall

	la $a0, nooneusethisnewlinepls
	syscall

	seq $v0, $t9, 5 # $v0 = 1 (victory) if all 5 slots are marked green "G", else 0 (nothing happens, then continues on with the ui interface/integration)
.end_macro

.data
feedbackText: .ascii "Guess Result: "
feedbackStr: .space 6
usedSlots: .space 5
nooneusethisnewlinepls: .asciiz "\n"
.text
check_guess:
	compareGuess(secretWord, userGuess)
	jr $ra
