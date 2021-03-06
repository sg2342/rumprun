/*-
 * Copyright (c) 2014, 2015 Antti Kantee.  All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <bmk/multiboot.h>
#include <bmk/kernel.h>

/*
 * Default trap handlers, which just print info on what type of trap
 * it was.  Generally speaking, we don't except trouble here.
 */
itsatrap:
	.asciz "trap: "
#define SYSTRAP(num, reason) \
trapstr##num: ;\
	.asciz reason ;\
ENTRY(bmk_x86_trap_##num) \
	movq $itsatrap, %rdi ;\
	call bmk_cons_puts ;\
	movq $trapstr##num, %rdi ;\
	call bmk_cons_puts ;\
	movq $'\n', %rdi ;\
	call bmk_cons_putc ;\
	iretq ;\
END(bmk_x86_trap_##num)

SYSTRAP(0, "#DE")
SYSTRAP(2, "#NMI")
SYSTRAP(3, "#BP")
SYSTRAP(4, "#OF")
SYSTRAP(5, "#BR")
SYSTRAP(6, "#UD")
SYSTRAP(7, "#NM")
SYSTRAP(8, "#DF")
SYSTRAP(10, "#TS")
SYSTRAP(11, "#NP")
SYSTRAP(12, "#SS")
SYSTRAP(13, "#GP")
SYSTRAP(17, "#AC")

/* page fault */
ENTRY(bmk_x86_trap_14)
	mov %cr2, %rdi
	mov 8(%rsp), %rsi
	call bmk_cpu_pagefault
	hlt
END(bmk_x86_trap_14)

/*
 * we just ignore most interrupts and traps with this
 * convenient inservice routine
 */
ENTRY(bmk_cpu_insr)
	iretq
END(bmk_cpu_insr)

/*
 * The interrupt handlers don't do the normal accounting for cli-depth,
 * but it's hopefully a safe bet that since we're here, interrupts were
 * unmasked, so we can just unmask them before we return.
 */
ENTRY(bmk_cpu_isr_clock)
	cli
	call bmk_isr_clock
	pushq %rax
	movb $0x20, %al
	outb %al, $0x20
	popq %rax
	sti
	iretq
END(bmk_cpu_isr_clock)

/*
 * Macro to define interrupt stub to call C handler.
 * note: interrupt is acked on the PIC as part of bmk_isr
 */
#define INTRSTUB(intnum)						\
ENTRY(bmk_x86_isr_##intnum)						\
	cli								;\
	pushq %rax							;\
	pushq %rbx							;\
	pushq %rcx							;\
	pushq %rdx							;\
	pushq %rdi							;\
	pushq %rsi							;\
	movq $intnum, %rsi						;\
	call bmk_isr							;\
	popq %rsi							;\
	popq %rdi							;\
	popq %rdx							;\
	popq %rcx							;\
	popq %rbx							;\
	popq %rax							;\
	sti								;\
	iretq								;\
END(bmk_x86_isr_##intnum)

INTRSTUB(9)
INTRSTUB(10)
INTRSTUB(11)
INTRSTUB(14)
INTRSTUB(15)
