
# CS 2640 - Wordle Final Project
# Spencer Davis, Felix Zheng, Aniket Subramanian, Jesston Li
# All code combined version
#
# Spencer: UI, menu, game flow, attempts, win/loss, replay
# Felix: Dictionary and random word selection
# Aniket: Guess input and length validation
# Jesston: Guess comparison, letter feedback, win detection
#
# INTEGRATION:
# select_word: puts selected word address in $s3
# get_guess: reads valid guess into 'guess' buffer
# check_guess: returns $v0 = 1 if won, 0 otherwise
# $s0: Spencer's attempt counter


# ==================================================
# PART 4 - JESSTON: GUESS COMPARISON MACRO
# Original green/yellow algorithm preserved
#
# INTEGRATION CHANGE:
# Use move for secret word because $s3 already contains the address selected by Felix.
# ==================================================

.macro compareGuess(%secretWord, %guessWord)
    move $a0, %secretWord
    la $a1, %guessWord
    la $a2, feedbackStr
    la $a3, usedSlots

    # First pass: exact matches = G
    li $t0, 0
    li $t9, 0

greenLoop:
    beq $t0, 5, yellowStart

    add $t1, $a0, $t0
    lb $t2, 0($t1)       # secret character

    add $t1, $a1, $t0
    lb $t3, 0($t1)       # guessed character

    li $t4, '-'          # default: absent
    li $t5, 0           # slot unused

    bne $t2, $t3, saveSlot

    li $t4, 'G'
    li $t5, 1
    addi $t9, $t9, 1

saveSlot:
    add $t1, $a2, $t0
    sb $t4, 0($t1)

    add $t1, $a3, $t0
    sb $t5, 0($t1)

    addi $t0, $t0, 1
    j greenLoop

    # Second pass: misplaced letters = Y
yellowStart:
    li $t0, 0

yellowOuter:
    beq $t0, 5, finalizeComparison

    add $t1, $a2, $t0
    lb $t2, 0($t1)
    beq $t2, 'G', finalOuter

    add $t1, $a1, $t0
    lb $t3, 0($t1)

    li $t4, 0

yellowInner:
    beq $t4, 5, finalOuter

    add $t5, $a3, $t4
    lb $t6, 0($t5)
    bnez $t6, finalInner

    add $t6, $a0, $t4
    lb $t7, 0($t6)
    bne $t3, $t7, finalInner

    # Correct letter, wrong position
    li $t2, 'Y'
    add $t1, $a2, $t0
    sb $t2, 0($t1)

    li $t6, 1
    sb $t6, 0($t5)
    j finalOuter

finalInner:
    addi $t4, $t4, 1
    j yellowInner

finalOuter:
    addi $t0, $t0, 1
    j yellowOuter

finalizeComparison:
    # Null terminate feedback
    sb $zero, 5($a2)

    # INTEGRATION CHANGE: Print feedback label and result separately
    li $v0, 4
    la $a0, feedbackText
    syscall

    li $v0, 4
    la $a0, feedbackStr
    syscall

    li $v0, 4
    la $a0, feedbackNewline
    syscall

    # Return 1 if all 5 letters correct, otherwise return 0
    seq $v0, $t9, 5
.end_macro

# ==================================================
# SHARED DATA SECTION
# Data from all four contributors
# ==================================================

.data

# PART 1 - SPENCER: UI STRINGS

welcome: .asciiz "\n==============================\n       WORDLE\n==============================\n"

menuText: .asciiz "\n1. Play Wordle\n2. Instructions\n3. Exit\nChoose an option (1-3): "

# UI CHANGE: Explain feedback symbols and lowercase requirement
instructions: .asciiz "\nGuess the secret five-letter word in six tries.\nUse lowercase letters only.\nG = Correct letter, correct position\nY = Correct letter, wrong position\n- = No match (absent or extra repeated letter)\nOnly five-character guesses use an attempt.\n"

invalidMenu: .asciiz "\nInvalid menu option. Please choose 1, 2, or 3.\n"

startText: .asciiz "\n--- NEW GAME ---\n"

# UI CHANGE: Remind players to use lowercase
feedbackGuide: .asciiz "Use lowercase letters only.\nG = correct spot, Y = wrong spot, - = no match\n"

attemptText: .asciiz "\nAttempt "

ofSix: .asciiz " of 6\n"

winText: .asciiz "\nYou guessed the word! You win!\n"

loseText: .asciiz "\nNo attempts left. Game over!\n"

# UI CHANGE: Answer reveal message
answerText: .asciiz "The secret word was: "

# UI CHANGE: Clearer replay options
replayText: .asciiz "\n1. Play Again\n2. Main Menu\nChoose an option (1-2): "

invalidReplay: .asciiz "\nPlease enter 1 or 2.\n"

byeText: .asciiz "\nThanks for playing!\n"


# PART 2 - FELIX: WORD DICTIONARY

word1: .asciiz "spawn"
word2: .asciiz "apple"
word3: .asciiz "table"
word4: .asciiz "house"
word5: .asciiz "chair"

.align 2
word_list: .word word1, word2, word3, word4, word5


# PART 3 - ANIKET: GUESS INPUT

# UI CHANGE: Clarify lowercase requirement in prompt
prompt: .asciiz "Enter a five-letter word (lowercase only): \n"

error: .asciiz "Invalid. Must be exactly five letters. \n"

# INTEGRATION CHANGE:
# Increased input buffer from 8 to 32 bytes
guess: .space 32


# PART 4 - JESSTON: FEEDBACK DATA

# INTEGRATION CHANGE:
# Changed .ascii to .asciiz
feedbackText: .asciiz "Guess Result: "

feedbackStr: .space 6
usedSlots: .space 5
feedbackNewline: .asciiz "\n"


# ==================================================
# PART 1 - SPENCER: MAIN UI AND GAME FLOW
#
# Original menu, game loop, win/loss, replay kept.
# Removed temporary stub procedures.
# ==================================================

.text
.globl main

main:
    # Display welcome screen
    li $v0, 4
    la $a0, welcome
    syscall

main_menu:
    # Display main menu
    li $v0, 4
    la $a0, menuText
    syscall

    # Read menu choice
    li $v0, 5
    syscall

    beq $v0, 1, start_game
    beq $v0, 2, show_instructions
    beq $v0, 3, exit

    # Invalid menu choice
    li $v0, 4
    la $a0, invalidMenu
    syscall
    j main_menu

show_instructions:
    li $v0, 4
    la $a0, instructions
    syscall
    j main_menu

start_game:
    li $v0, 4
    la $a0, startText
    syscall

    # UI CHANGE: Display feedback guide
    li $v0, 4
    la $a0, feedbackGuide
    syscall

    # FELIX: Select random secret word
    jal select_word

    # SPENCER: Reset attempt counter
    li $s0, 0

game_loop:
    # Check six-attempt limit
    li $t0, 6
    bge $s0, $t0, game_lost

    # Print attempt number
    li $v0, 4
    la $a0, attemptText
    syscall

    li $v0, 1
    addiu $a0, $s0, 1
    syscall

    li $v0, 4
    la $a0, ofSix
    syscall

    # ANIKET: Get valid five-letter guess
    jal get_guess

    # JESSTON: Compare and display feedback
    jal check_guess

    # SPENCER: Save result
    move $s1, $v0

    # Count valid attempt
    addiu $s0, $s0, 1

    # Check win condition
    bne $s1, $zero, game_won

    # Continue game
    j game_loop

game_won:
    li $v0, 4
    la $a0, winText
    syscall
    j replay_prompt

game_lost:
    li $v0, 4
    la $a0, loseText
    syscall

    # UI CHANGE: Reveal secret word after losing
    li $v0, 4
    la $a0, answerText
    syscall

    li $v0, 4
    move $a0, $s3
    syscall

    # UI CHANGE: Add newline after secret word
    li $v0, 4
    la $a0, feedbackNewline
    syscall

replay_prompt:
    li $v0, 4
    la $a0, replayText
    syscall

    li $v0, 5
    syscall

    beq $v0, 1, start_game
    beq $v0, 2, main_menu

    li $v0, 4
    la $a0, invalidReplay
    syscall
    j replay_prompt

exit:
    li $v0, 4
    la $a0, byeText
    syscall

    li $v0, 10
    syscall


# ==================================================
# PART 2 - FELIX: DICTIONARY AND WORD SELECTION
#
# Original selection algorithm unchanged.
# Selected word address stored in $s3.
# ==================================================

select_word:
    # Random number from 0 to 4
    li $v0, 42
    li $a0, 0
    li $a1, 5
    syscall

    # Convert index to byte offset
    sll $t0, $a0, 2

    # Load selected word address
    la $t1, word_list
    add $t1, $t1, $t0
    lw $s3, 0($t1)

    jr $ra


# ==================================================
# PART 3 - ANIKET: GUESS INPUT AND VALIDATION
#
# INTEGRATION CHANGES:
# Renamed original main to get_guess.
# Renamed length check to check_length.
# Removed hardcoded "spawn" comparison.
# Return with jr $ra instead of exiting.
# Added null-byte check and length-limit fix.
# ==================================================

get_guess:
read_guess:
    # Prompt player
    li $v0, 4
    la $a0, prompt
    syscall

    # Read input string
    li $v0, 8
    la $a0, guess
    li $a1, 32
    syscall

    # Count input characters
    la $t0, guess
    li $t1, 0

count_guess:
    lb $t2, 0($t0)

    # Stop counting at newline or null
    beq $t2, 10, check_length
    beq $t2, $zero, check_length

    # Reject sixth character
    bge $t1, 5, invalid_guess

    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j count_guess

check_length:
    # Must contain exactly 5 characters
    li $t3, 5
    bne $t1, $t3, invalid_guess

    # Valid guess: return to main game
    jr $ra

invalid_guess:
    li $v0, 4
    la $a0, error
    syscall

    # Try again without consuming attempt
    j read_guess


# ==================================================
# PART 4 - JESSTON: COMPARISON PROCEDURE
#
# INTEGRATION CHANGES:
# Uses $s3 from Felix instead of secretWord label.
# Uses guess buffer from Aniket.
# Calls Jesston's original comparison macro.
# Returns win result to Spencer in $v0.
# ==================================================

check_guess:
    compareGuess($s3, guess)
    jr $ra
