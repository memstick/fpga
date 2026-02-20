
.section .initf, "ax"
.global start
start:
	la sp, _stack_top
	j main
