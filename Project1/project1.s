	.eqv	EXIT_0, 10
	.eqv	PRT_STR, 4
	# file operations
	.eqv	OPEN_FILE, 1024
	.eqv	CLOSE_FILE, 57
	.eqv	READ_FILE, 63
	.eqv	WRITE_FILE, 64
	
	.eqv	BUF_SIZE, 512
	.eqv	BUF_SIZE_MINUS_ONE, 511
	
	.data
# 512 bytes buffer used in getc function
buf:	.space	BUF_SIZE
# pointer to the character inside the buffer
# this character will be returned in the next getc call
buf_pointer:	.word	-1
# buffer used to output characters
# 1 character is saved per every call of putc function
buf_output:	.space	1

# files paths
fin:	.asciz	"input.c"
fout:	.asciz 	"output.c"
# error messages
open_err: 	.asciz	"Unable to open file: "
read_err: 	.asciz	"Unable to read from file: "

	.text
main:
# ------------------------------------------------------------------
# ---------------------INITIALIZATION-------------------------------
# ------------------------------------------------------------------
	# open input file
	li	a7, OPEN_FILE
	la	a0, fin
	li	a1, 0	# read-only mode
	ecall
	
	# close program if failed to open
	la	t1, fin		# file to print error about
	li	t0, -1
	beq	a0, t0, open_error
	
	mv	s0, a0	# save input file descriptor to s0
	
	# open output file
	li	a7, OPEN_FILE
	la	a0, fout
	li	a1, 1	# write-only mode
	ecall
	
	# close program if failed to open
	la	t1, fout	# file to print error about
	li	t0, -1
	beq	a0, t0, open_error
	
	mv	s1, a0 # save output file descriptor to s1

	# set registers holding characters to 0
	li	s10, 0	# current character
	li	s9, 0 	# previous character
	li	s11, 0	# next character
	
	# initalize "boolean" values holding current state of the program
	li	s8, 0	# inside single line comment ;
	li	s7, 0	# inside multi line comment /* */
	li	s6, 0	# inside string	" "

	li	s5, 0	# is hexadecimal number
	
next_char:
# ------------------------------------------------------------------
# ---------------------MAIN LOOP-----------------------------------
# ------------------------------------------------------------------

	# read character from input file - s0
	mv	a0, s0
	jal	getc
	
	# check if end of file
	beqz	a0, close_files
	
	mv	s10, a0	# current character
	
# check if inside comment or string

	bnez	s8, single_comment	# we are in comment
	
	bnez	s7, multi_line_comment	# we are in multi line comment
	
	bnez	s6, string		# we are in string
	
	bnez	s5, hex			# we are in hex digit
	
# check if start of comment or string

# single line comment
	li	t0, '/'		# is current character '/'
	
	mv	t1, s10 	# character copy
	sub	t1, t1, t0
	
	seqz	t2, t1		# t2 is 1 if current character is '/'
	
	mv	t1, s9		# previous character copy
	sub	t1, t1, t0
	seqz	t3, t1		# t3 is 1 if previous character was '/'
	
	and	t2, t2, t3	# 1 if //, 0 otherwise
	
	mv	s8, t2		# set flag if we are in comment
	bnez	s8, copy	# if we are in the comment we jump to copy the '/' character
				# if not inside the comment, then check other options
	
# multi line comment
	li	t0, '*'		# is current character *
	mv	t1, s10
	sub	t1, t1, t0
	seqz	t2, t1		# t2 is 1 if currect character is '*'
	
	li	t0, '/'		# is previous character /
	mv	t1, s9
	sub	t1, t1, t0
	seqz	t3, t1		# t3 is 1 if previous character is '/'
	
	and	t2, t2, t3	# t2 is 1 if /*, 0 otherwise
	
	mv	s7, t2
	bnez	s7, copy	# if multi-line then let's copy '*' character
	
	# check other options
	
# string
	# is current character "
	li	t0, '"'
	mv	t1, s10
	sub	t1, t1, t0
	seqz	t1, t1		# 1 if ", 0 otherwise
	
	mv	s6, t1		# set flag if "
	bnez	s6, copy	# if comment then copy '"' character
	
check_if_hex:
	# check if hexadecimal number starts
	li	t0, 'x'		# check if currect is 'x'
	mv	t1, s10
	sub	t1, t1, t0
	seqz	t2, t1		# t2 is 1 if current is 'x'
	
	li	t0, '0'		# check if previous was '0'
	mv	t1, s9
	sub	t1, t1, t0
	seqz	t3, t1		# t3 is 1 if previous was '0'
	
	and	t2, t2, t3	# 1 if 0x
	
	# set flag if hexadecimal
	mv	s5, t2		# if t2 is 1 then s5 becomes 1
				
	bnez	s5, copy	# if we are in hex let's copy 'x' character
	
	# we checked all of the possibilities
	# program didn't find any special characters like // /* " 0x
	# all of the flags(is string, is hex) are set to 0
	# so we process current character normally
	
	b 	check_if_remove		# check_if_remove will check if it is ' and if it should be removed


# the following branches are the behaviour of the program
# while instide the string, comment etc.
# it checks if it is the end of the string, comment etc.
# it does not remove characters '

string:
# check if end of string
	li	t0, '"'
	mv	t1, s10
	sub	t1, t1, t0
	seqz	t1, t1		# 1 if "
	
	xori	t1, t1, 1	# 0 if ", 1 otherwise
	
	mv	s6, t1		# if 0 then end of string
	
	# every character inside the string and also character ending the string - "
	# should bo copied without the removal of '
	b	copy

# the behaviour of the program inside the single-line comment //
single_comment:
# check if current character is '/n', which means end of comment
	li	t0, '\n'
	
	mv	t1, s10
	sub	t1, t1, t0
	
	seqz	t1, t1		# t1 is 1 if current character is '/n'
	
	xori	t1, t1, 1	# t1 is 0 if current character is '/n'
	
	mv	s8, t1		# end single line comment if '/n'
	
	# every character inside comment and also character ending the comment /n
	# should bo copied without the removal of '
	b	copy

# the behaviour of the program inside the multi-line comment /*   */
multi_line_comment:
# check if end of comment
	li	t0, '/'		# check if current is /
	
	mv	t1, s10
	sub	t1, t1, t0
	seqz	t2, t1		# 1 if current is '/'
	
	li	t0, '*'		# check if previous is *
	mv	t1, s9
	sub	t1, t1, t0
	seqz	t3, t1		# 1 if previous is *
	
	and	t2, t2, t3	# 1 if */
	
	xori	t2, t2, 1	# 0 if */, 1 otherwise
	
	mv	s7, t2		# if t2 is 0, then end of string - store it inside s7
	
	# every character inside comment and also character ending the comment */
	# should bo copied without the removal of '
	b	copy

hex:
# check if we encountered end of hex digit
# it will be the end of hex number is current character
# is different than 0-F and '
	mv	a0, s10
	mv	a1, s5		# treat as a hex
	jal	is_digit
	
	# a0 holds informations if digit
	
	li	t0, '\''
	sub	t0, t0, s10
	seqz	t0, t0		# 1 if '
	
	# set is_hex flag
	# 1 we encounter hex digit or '
	# 0 if some different character
	or	s5, a0, t0	
	
	# let's check if current character should be removed
			
# behaviour of the program if processing normal text - not string, not comment										
# check if current is '
check_if_remove:
	li	t0, '\''		# check if current is '
	bne	s10, t0, copy
	
	mv	a0, s9			# check previous if digit
	mv	a1, s5
	jal	is_digit
	
	beqz	a0, copy		# not a digit
	
	mv	a0, s0			# check if next is digit
	jal	getc
	
	li	t0, -1
	beq	a0, t0, open_error	# check if error while getc
	
	beqz	a0, copy_one_and_close	# EOF
	
	mv	s11, a0		# next character save
	
	# check if next is a digit
	mv	a0, s11
	mv	a1, s5
	jal	is_digit
	
	beqz	a0, copy_two		# next is not a digit
	
	# previous character was a digit
	# next character is a digit
	# so we have to omit current character which is '
	# so copy only next character which is in s11
	mv	s10, s11
	
copy:
	# write character from a0 to file in a1
	mv	a0, s10
	mv	a1, s1
	jal	putc

	mv	s9, s10		# save current character as previous
	
	b	next_char

copy_two:
	# put two characters - current and next
	mv	a0, s10
	mv	a1, s1
	jal	putc
	
	mv	a0, s11
	mv	a1, s1
	jal	putc
	
	mv	s9, s11		# save next character as previous
	
	b	next_char
	
copy_one_and_close:
	mv	a0, s10
	mv	a1, s1
	jal	putc

close_files:
	li	a7, CLOSE_FILE
	mv	a0, s0		# input file
	ecall
	
	li	a7, CLOSE_FILE
	mv	a0, s1		# output file
	ecall
	
end:
	li	a7, EXIT_0
	ecall
	
open_error:
	li	a7, PRT_STR
	la	a0, open_err
	ecall
	
	li	a7, PRT_STR
	mv	a0, t1
	ecall

	li	a7, EXIT_0
	ecall
	
read_error:
	li	a7, PRT_STR
	la	a0, read_err
	ecall
	
	li	a7, PRT_STR
	la	a0, fin
	ecall
	
	li	a7, EXIT_0
	ecall
	
	
# -------------------------------
# ------------GETC--------------
# ------------------------------
# Get one character from the file
# Use 512 bytes buffer to avoid reading from the file every call
# Arguments:
# a0 - input file
# Return values:
# a0 - character got from the file
# 0 if EOF, -1 if error
getc:
	# check if function is called for the first time
	li	t0, -1
	lw	t1, buf_pointer
	bne	t0, t1, next
	# if yes then it needs to read a characters to the buffer
	
read_buf:
	# read 511 characters to the buffer
	la	a1, buf
	li	a2, BUF_SIZE_MINUS_ONE
	li	a7, READ_FILE
	ecall
	
	# check if there is no error while reading the file
	li	t0, -1
	mv	t1, a0
	beq	t0, t1, error
	
	# check if EOF
	bne	a0, zero, prepare_buf
	
	# EOF
	mv	a0, zero
	ret
	
prepare_buf:
	# add 0 to the end of buffer
	# to know when to stop reading characters
	la	t0, buf
	add	t0, t0, a0		# a0 holds number of characters that were written to the buffer
	sb	zero, (t0)
	
	# set buf_pointer to the beginning of buffer
	la	t0, buf
	sw	t0, buf_pointer, t1

next:
	# read data from the buffer
	lw	t0, buf_pointer
	lb	t1, (t0)
	
	# if end of buffer (0) then read new characters
	beqz	t1, read_buf
	
	# prepare return data
	mv	a0, t1

	# move buf_pointer
	addi	t0, t0, 1
	sw	t0, buf_pointer, t1
	
	ret
error:
	# ret -1 if error
	li	a0, -1
	ret
# --------------------------
#----END OF GETC-------------
# ---------------------------


# --------------------------
#-----------PUTC-------------
# ---------------------------
# Write single character to the file
# Arguments:
# a0 - character to write
# a1 - file to write
# Return values:
# a0 - operation succeed? 1 -> succeed 0->fail
putc:
	sb	a0, buf_output, t0
	
	mv	a0, a1
	la	a1, buf_output
	li	a2, 1
	li	a7, WRITE_FILE
	ecall
	
	# add error handling
	# add return value
	ret
	
# --------------------------
#----END OF PUTC-------------
# ---------------------------
	
	

# --------------------------
#-----------IS DIGIT-------------
# ---------------------------
# Check if given character is a digit
# Arguments:
# a0 - character to check
# a1 - if 1 then check as hexadecimal
# Return values:
# a0 - true of false (1 of 0), digit or not
is_digit:
	li	t0, 0	# <0
	li	t1, 0	# >9
	
	li	t2, '0'
	sltu	t0, a0, t2	# 1 if <0
	
	li	t2, '9'
	sgtu	t1, a0, t2	# 1 if >9
	
	or	t0, t1, t0 	# 1 if <0 or >9 -> 1, if not a digit
	
	# if not a digit, but hex then check A-F and a-f
	and	t1, t0, a1	# 1 if not a digit and hex flag is set
	bnez	t1, if_hex
	
	# prepare output data
	xori	a0, t0, 1	# 1 -> 0, 0 -> 1, 1 if digit
	ret
	
if_hex:
	li	t0, 0	# <A
	li	t1, 0	# >F
	
	li	t2, 'A'
	sltu	t0, a0, t2
	
	li	t2, 'F'
	sgtu	t1, a0, t2
	
	or	t3, t1, t0	# 1 if <A or >F - not a digit
	
	xori	t3, t3, 1	# 1 if >A and <F - digit
	
	li	t0, 0	# <a
	li	t1, 0	# >f
	
	li	t2, 'a'
	sltu	t0, a0, t2
	
	li	t2, 'f'
	sgtu	t1, a0, t2
	
	or	t4, t1, t0	# 1 if <a or >f - not a digit
	
	xori	t4, t4, 1	# 1 if >a and <f - digit
	
	# prepare return value
	or	a0, t3, t4	# 1 if A-F or a-f
	ret
# --------------------------
#----END OF IS DIGIT-------------
# ---------------------------


	
