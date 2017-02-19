// Copyright (c) 2016 Andreas Auernhammer. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// +build go1.7,amd64,!gccgo,!appengine,!nacl

#include "textflag.h"

DATA ·sigma_AVX<>+0x00(SB)/4, $0x61707865
DATA ·sigma_AVX<>+0x04(SB)/4, $0x3320646e
DATA ·sigma_AVX<>+0x08(SB)/4, $0x79622d32
DATA ·sigma_AVX<>+0x0C(SB)/4, $0x6b206574
GLOBL ·sigma_AVX<>(SB), (NOPTR+RODATA), $16

DATA ·one_AVX<>+0x00(SB)/8, $1
DATA ·one_AVX<>+0x08(SB)/8, $0
GLOBL ·one_AVX<>(SB), (NOPTR+RODATA), $16

DATA ·one_AVX2<>+0x00(SB)/8, $0
DATA ·one_AVX2<>+0x08(SB)/8, $0
DATA ·one_AVX2<>+0x10(SB)/8, $1
DATA ·one_AVX2<>+0x18(SB)/8, $0
GLOBL ·one_AVX2<>(SB), (NOPTR+RODATA), $32

DATA ·two_AVX2<>+0x00(SB)/8, $2
DATA ·two_AVX2<>+0x08(SB)/8, $0
DATA ·two_AVX2<>+0x10(SB)/8, $2
DATA ·two_AVX2<>+0x18(SB)/8, $0
GLOBL ·two_AVX2<>(SB), (NOPTR+RODATA), $32

DATA ·rol16_AVX2<>+0x00(SB)/8, $0x0504070601000302
DATA ·rol16_AVX2<>+0x08(SB)/8, $0x0D0C0F0E09080B0A
DATA ·rol16_AVX2<>+0x10(SB)/8, $0x0504070601000302
DATA ·rol16_AVX2<>+0x18(SB)/8, $0x0D0C0F0E09080B0A
GLOBL ·rol16_AVX2<>(SB), (NOPTR+RODATA), $32

DATA ·rol8_AVX2<>+0x00(SB)/8, $0x0605040702010003
DATA ·rol8_AVX2<>+0x08(SB)/8, $0x0E0D0C0F0A09080B
DATA ·rol8_AVX2<>+0x10(SB)/8, $0x0605040702010003
DATA ·rol8_AVX2<>+0x18(SB)/8, $0x0E0D0C0F0A09080B
GLOBL ·rol8_AVX2<>(SB), (NOPTR+RODATA), $32

#define ROTL(n, t, v) \
	VPSLLD $n, v, t; \
	VPSRLD $(32-n), v, v; \
	VPXOR v, t, v

#define CHACHA_QROUND(v0, v1, v2, v3, t, c16, c8) \
	VPADDD v0, v1, v0; \
	VPXOR v3, v0, v3; \
	VPSHUFB c16, v3, v3; \
	VPADDD v2, v3, v2; \
	VPXOR v1, v2, v1; \
	ROTL(12, t, v1); \
	VPADDD v0, v1, v0; \
	VPXOR v3, v0, v3; \
	VPSHUFB c8, v3, v3; \
	VPADDD v2, v3, v2; \
	VPXOR v1, v2, v1; \
	ROTL(7, t, v1)

#define CHACHA_SHUFFLE(v1, v2, v3) \
    VPSHUFD $0x39, v1, v1; \
	VPSHUFD $0x4E, v2, v2; \
	VPSHUFD $-109, v3, v3

#define XOR_AVX2(dst, src, off, v0, v1, v2, v3, t0, t1) \
	VMOVDQU (0+off)(src), t0; \ 
    VPERM2I128 $32, v1, v0, t1; \
	VPXOR t0, t1, t0; \
	VMOVDQU t0, (0+off)(dst); \
	VMOVDQU (32+off)(src), t0; \ 
    VPERM2I128 $32, v3, v2, t1; \
	VPXOR t0, t1, t0; \
	VMOVDQU t0, (32+off)(dst); \
	VMOVDQU (64+off)(src), t0; \ 
    VPERM2I128 $49, v1, v0, t1; \
	VPXOR t0, t1, t0; \
	VMOVDQU t0, (64+off)(dst); \
	VMOVDQU (96+off)(src), t0; \ 
    VPERM2I128 $49, v3, v2, t1; \
	VPXOR t0, t1, t0; \
	VMOVDQU t0, (96+off)(dst)

#define XOR_UPPER_AVX2(dst, src, off, v0, v1, v2, v3, t0, t1) \
    VMOVDQU (0+off)(src), t0; \ 
    VPERM2I128 $32, v1, v0, t1; \
	VPXOR t0, t1, t0; \
	VMOVDQU t0, (0+off)(dst); \
	VMOVDQU (32+off)(src), t0; \ 
    VPERM2I128 $32, v3, v2, t1; \
	VPXOR t0, t1, t0; \
	VMOVDQU t0, (32+off)(dst); \
	
#define EXTRACT_LOWER(dst, v0, v1, v2, v3, t0) \
    VPERM2I128 $49, v1, v0, t0; \
	VMOVDQU t0, 0(dst); \
    VPERM2I128 $49, v3, v2, t0; \
    VMOVDQU t0, 32(dst)

#define XOR_AVX(dst, src, off, v0, v1, v2, v3, t0) \
	VPXOR 0+off(src), v0, t0; \
	VMOVDQU t0, 0+off(dst); \
	VPXOR 16+off(src), v1, t0; \
	VMOVDQU t0, 16+off(dst); \
	VPXOR 32+off(src), v2, t0; \
	VMOVDQU t0, 32+off(dst); \
	VPXOR 48+off(src), v3, t0; \
	VMOVDQU t0, 48+off(dst)

#define TWO 0(SP)
#define C16 32(SP)
#define C8 64(SP)
#define STATE_0 96(SP)
#define STATE_1 128(SP)
#define STATE_2 160(SP)
#define STATE_3 192(SP)
#define TMP_0 224(SP)
#define TMP_1 256(SP)

// func xorKeyStreamAVX(dst, src []byte, block, state *[64]byte, rounds int) int
TEXT ·xorKeyStreamAVX2(SB),4,$320-80
	MOVQ dst_base+0(FP), DI
	MOVQ src_base+24(FP), SI
	MOVQ src_len+32(FP), CX
    MOVQ block+48(FP), BX
    MOVQ state+56(FP), AX
	MOVQ rounds+64(FP), DX

    MOVQ SP, R8
    ADDQ $32, SP
    ANDQ $-32, SP

    VMOVDQU 0(AX), Y2
	VMOVDQU 32(AX), Y3
	VPERM2I128 $0x22, Y2, Y0, Y0
	VPERM2I128 $0x33, Y2, Y1, Y1
	VPERM2I128 $0x22, Y3, Y2, Y2
	VPERM2I128 $0x33, Y3, Y3, Y3

    TESTQ CX, CX
    JZ done

    VMOVDQU ·one_AVX2<>(SB), Y4
	VPADDD Y4, Y3, Y3

    VMOVDQA Y0, STATE_0
    VMOVDQA Y1, STATE_1
    VMOVDQA Y2, STATE_2
    VMOVDQA Y3, STATE_3

    VMOVDQU ·rol16_AVX2<>(SB), Y4
    VMOVDQU ·rol8_AVX2<>(SB), Y5
    VMOVDQU ·two_AVX2<>(SB), Y6
    VMOVDQA Y4, Y14
    VMOVDQA Y5, Y15
    VMOVDQA Y4, C16
    VMOVDQA Y5, C8
    VMOVDQA Y6, TWO

    CMPQ CX, $64
    JBE between_0_and_64
    CMPQ CX, $192
    JBE between_64_and_192
    CMPQ CX, $320
    JBE between_192_and_320
    CMPQ CX, $448
    JBE between_320_and_448
    
at_least_512:
    VMOVDQA Y0, Y4
    VMOVDQA Y1, Y5
    VMOVDQA Y2, Y6
    VPADDQ TWO, Y3, Y7
    VMOVDQA Y0, Y8
    VMOVDQA Y1, Y9
    VMOVDQA Y2, Y10
    VPADDQ TWO, Y7, Y11
    VMOVDQA Y0, Y12
    VMOVDQA Y1, Y13
    VMOVDQA Y2, Y14
    VPADDQ TWO, Y11, Y15

    MOVQ DX, R9
chacha_loop_512:
    VMOVDQA Y8, TMP_0
    CHACHA_QROUND(Y0, Y1, Y2, Y3, Y8, C16, C8)
    CHACHA_QROUND(Y4, Y5, Y6, Y7, Y8, C16, C8)
    VMOVDQA TMP_0, Y8
    VMOVDQA Y0, TMP_0
    CHACHA_QROUND(Y8, Y9, Y10, Y11, Y0, C16, C8)
    CHACHA_QROUND(Y12, Y13, Y14, Y15, Y0, C16, C8)
    CHACHA_SHUFFLE(Y1, Y2, Y3)
    CHACHA_SHUFFLE(Y5, Y6, Y7)
    CHACHA_SHUFFLE(Y9, Y10, Y11)
    CHACHA_SHUFFLE(Y13, Y14, Y15)
    
    CHACHA_QROUND(Y12, Y13, Y14, Y15, Y0, C16, C8)
    CHACHA_QROUND(Y8, Y9, Y10, Y11, Y0, C16, C8)
    VMOVDQA TMP_0, Y0
    VMOVDQA Y8, TMP_0
    CHACHA_QROUND(Y4, Y5, Y6, Y7, Y8, C16, C8)
    CHACHA_QROUND(Y0, Y1, Y2, Y3, Y8, C16, C8)
    VMOVDQA TMP_0, Y8
    CHACHA_SHUFFLE(Y3, Y2, Y1)
    CHACHA_SHUFFLE(Y7, Y6, Y5)
    CHACHA_SHUFFLE(Y11, Y10, Y9)
    CHACHA_SHUFFLE(Y15, Y14, Y13)
    SUBQ $2, R9
    JA chacha_loop_512

    VMOVDQA Y12, TMP_0
    VMOVDQA Y13, TMP_1
    VPADDD STATE_0, Y0, Y0
    VPADDD STATE_1, Y1, Y1
    VPADDD STATE_2, Y2, Y2
    VPADDD STATE_3, Y3, Y3
    XOR_AVX2(DI, SI, 0, Y0, Y1, Y2, Y3, Y12, Y13)
    VMOVDQA STATE_0, Y0
    VMOVDQA STATE_1, Y1
    VMOVDQA STATE_2, Y2
    VMOVDQA STATE_3, Y3
    VPADDQ TWO, Y3, Y3

    VPADDD Y0, Y4, Y4
    VPADDD Y1, Y5, Y5
    VPADDD Y2, Y6, Y6
    VPADDD Y3, Y7, Y7
    XOR_AVX2(DI, SI, 128, Y4, Y5, Y6, Y7, Y12, Y13)
    VPADDQ TWO, Y3, Y3

    VPADDD Y0, Y8, Y8
    VPADDD Y1, Y9, Y9
    VPADDD Y2, Y10, Y10
    VPADDD Y3, Y11, Y11
    XOR_AVX2(DI, SI, 256, Y8, Y9, Y10, Y11, Y12, Y13)
    VPADDQ TWO, Y3, Y3

    VPADDD TMP_0, Y0, Y12
    VPADDD TMP_1, Y1, Y13
    VPADDD Y2, Y14, Y14
    VPADDD Y3, Y15, Y15
    VPADDQ TWO, Y3, Y3

    CMPQ CX, $512
    JB less_than_512

    XOR_AVX2(DI, SI, 384, Y12, Y13, Y14, Y15, Y4, Y5)
    VMOVDQA Y3, STATE_3
    ADDQ $512, SI
    ADDQ $512, DI
    SUBQ $512, CX
    CMPQ CX, $448
    JA at_least_512

    TESTQ CX, CX
    JZ done

    VMOVDQA C16, Y14
    VMOVDQA C8, Y15

    CMPQ CX, $64
    JBE between_0_and_64
    CMPQ CX, $192
    JBE between_64_and_192
    CMPQ CX, $320
    JBE between_192_and_320
    JMP between_320_and_448

less_than_512:
    XOR_UPPER_AVX2(DI, SI, 384, Y12, Y13, Y14, Y15, Y4, Y5)
    EXTRACT_LOWER(BX, Y12, Y13, Y14, Y15, Y4)
    ADDQ $448, SI
    ADDQ $448, DI
    SUBQ $448, CX
    JMP finalize

between_320_and_448:
    VMOVDQA Y0, Y4
    VMOVDQA Y1, Y5
    VMOVDQA Y2, Y6
    VPADDQ TWO, Y3, Y7
    VMOVDQA Y0, Y8
    VMOVDQA Y1, Y9
    VMOVDQA Y2, Y10
    VPADDQ TWO, Y7, Y11

    MOVQ DX, R9
chacha_loop_384:
    CHACHA_QROUND(Y0, Y1, Y2, Y3, Y13, Y14, Y15)
    CHACHA_QROUND(Y4, Y5, Y6, Y7, Y13, Y14, Y15)
    CHACHA_QROUND(Y8, Y9, Y10, Y11, Y13, Y14, Y15)
    CHACHA_SHUFFLE(Y1, Y2, Y3)
    CHACHA_SHUFFLE(Y5, Y6, Y7)
    CHACHA_SHUFFLE(Y9, Y10, Y11)
    CHACHA_QROUND(Y0, Y1, Y2, Y3, Y13, Y14, Y15)
    CHACHA_QROUND(Y4, Y5, Y6, Y7, Y13, Y14, Y15)
    CHACHA_QROUND(Y8, Y9, Y10, Y11, Y13, Y14, Y15)
    CHACHA_SHUFFLE(Y3, Y2, Y1)
    CHACHA_SHUFFLE(Y7, Y6, Y5)
    CHACHA_SHUFFLE(Y11, Y10, Y9)
    SUBQ $2, R9
    JA chacha_loop_384

    VPADDD STATE_0, Y0, Y0
    VPADDD STATE_1, Y1, Y1
    VPADDD STATE_2, Y2, Y2
    VPADDD STATE_3, Y3, Y3
    XOR_AVX2(DI, SI, 0, Y0, Y1, Y2, Y3, Y12, Y13)
    VMOVDQA STATE_0, Y0
    VMOVDQA STATE_1, Y1
    VMOVDQA STATE_2, Y2
    VMOVDQA STATE_3, Y3
    VPADDQ TWO, Y3, Y3

    VPADDD Y0, Y4, Y4
    VPADDD Y1, Y5, Y5
    VPADDD Y2, Y6, Y6
    VPADDD Y3, Y7, Y7
    XOR_AVX2(DI, SI, 128, Y4, Y5, Y6, Y7, Y12, Y13)
    VPADDQ TWO, Y3, Y3

    VPADDD Y0, Y8, Y8
    VPADDD Y1, Y9, Y9
    VPADDD Y2, Y10, Y10
    VPADDD Y3, Y11, Y11
    VPADDQ TWO, Y3, Y3

    CMPQ CX, $384
    JB less_than_384
    
    XOR_AVX2(DI, SI, 256, Y8, Y9, Y10, Y11, Y12, Y13)
    SUBQ $384, CX
    TESTQ CX, CX
    JE done

    ADDQ $384, SI
    ADDQ $384, DI
    JMP between_0_and_64

less_than_384:
    XOR_UPPER_AVX2(DI, SI, 256, Y8, Y9, Y10, Y11, Y12, Y13)
    EXTRACT_LOWER(BX, Y8, Y9, Y10, Y11, Y12)
    ADDQ $320, SI
    ADDQ $320, DI
    SUBQ $320, CX
    JMP finalize

between_192_and_320:
    VMOVDQA Y0, Y4
    VMOVDQA Y1, Y5
    VMOVDQA Y2, Y6
    VMOVDQA Y3, Y7
    VMOVDQA Y0, Y8
    VMOVDQA Y1, Y9
    VMOVDQA Y2, Y10
    VPADDQ TWO, Y3, Y11
    
    MOVQ DX, R9
chacha_loop_256:
    CHACHA_QROUND(Y4, Y5, Y6, Y7, Y13, Y14, Y15)
    CHACHA_QROUND(Y8, Y9, Y10, Y11, Y13, Y14, Y15)
    CHACHA_SHUFFLE(Y5, Y6, Y7)
    CHACHA_SHUFFLE(Y9, Y10, Y11)
    CHACHA_QROUND(Y4, Y5, Y6, Y7, Y13, Y14, Y15)
    CHACHA_QROUND(Y8, Y9, Y10, Y11, Y13, Y14, Y15)
    CHACHA_SHUFFLE(Y7, Y6, Y5)
    CHACHA_SHUFFLE(Y11, Y10, Y9)
    SUBQ $2, R9
    JA chacha_loop_256

    VPADDD Y0, Y4, Y4
    VPADDD Y1, Y5, Y5
    VPADDD Y2, Y6, Y6
    VPADDD Y3, Y7, Y7
    VPADDQ TWO, Y3, Y3
    XOR_AVX2(DI, SI, 0, Y4, Y5, Y6, Y7, Y12, Y13)
    VPADDD Y0, Y8, Y8
    VPADDD Y1, Y9, Y9
    VPADDD Y2, Y10, Y10
    VPADDD Y3, Y11, Y11
    VPADDQ TWO, Y3, Y3

    CMPQ CX, $256
    JB less_than_256
    
    XOR_AVX2(DI, SI, 128, Y8, Y9, Y10, Y11, Y12, Y13)
    SUBQ $256, CX
    TESTQ CX, CX
    JE done

    ADDQ $256, SI
    ADDQ $256, DI
    JMP between_0_and_64
    
less_than_256:
    XOR_UPPER_AVX2(DI, SI, 128, Y8, Y9, Y10, Y11, Y12, Y13)
    EXTRACT_LOWER(BX, Y8, Y9, Y10, Y11, Y12)
    ADDQ $192, SI
    ADDQ $192, DI
    SUBQ $192, CX
    JMP finalize

between_64_and_192:
    VMOVDQA Y0, Y4
    VMOVDQA Y1, Y5
    VMOVDQA Y2, Y6
    VMOVDQA Y3, Y7

    MOVQ DX, R9
chacha_loop_128:
    CHACHA_QROUND(Y4, Y5, Y6, Y7, Y13, Y14, Y15)
    CHACHA_SHUFFLE(Y5, Y6, Y7)
    CHACHA_QROUND(Y4, Y5, Y6, Y7, Y13, Y14, Y15)
    CHACHA_SHUFFLE(Y7, Y6, Y5)
    SUBQ $2, R9
    JA chacha_loop_128

    VPADDD Y0, Y4, Y4
    VPADDD Y1, Y5, Y5
    VPADDD Y2, Y6, Y6
    VPADDD Y3, Y7, Y7
    VPADDQ TWO, Y3, Y3
    
    CMPQ CX, $128
    JB less_than_128
    
    XOR_AVX2(DI, SI, 0, Y4, Y5, Y6, Y7, Y12, Y13)
    SUBQ $128, CX
    TESTQ CX, CX
    JE done

    ADDQ $128, SI
    ADDQ $128, DI
    JMP between_0_and_64
    
less_than_128:
    XOR_UPPER_AVX2(DI, SI, 0, Y4, Y5, Y6, Y7, Y12, Y13)
    EXTRACT_LOWER(BX, Y4, Y5, Y6, Y7, Y13)
    ADDQ $64, SI
    ADDQ $64, DI
    SUBQ $64, CX
    JMP finalize

between_0_and_64:
    VMOVDQA X0, X4
    VMOVDQA X1, X5
    VMOVDQA X2, X6
    VMOVDQA X3, X7

    MOVQ DX, R9
chacha_loop_64:
    CHACHA_QROUND(X4, X5, X6, X7, X13, X14, X15)
    CHACHA_SHUFFLE(X5, X6, X7)
    CHACHA_QROUND(X4, X5, X6, X7, X13, X14, X15)
    CHACHA_SHUFFLE(X7, X6, X5)
    SUBQ $2, R9
    JA chacha_loop_64

    VPADDD X0, X4, X4
    VPADDD X1, X5, X5
    VPADDD X2, X6, X6
    VPADDD X3, X7, X7
    VMOVDQU ·one_AVX<>(SB), X0
    VPADDQ X0, X3, X3

    CMPQ CX, $64
    JB less_than_64

    XOR_AVX(DI, SI, 0, X4, X5, X6, X7, X13)
    SUBQ $64, CX
    JMP done

less_than_64:
    VMOVDQU X4, 0(BX)
    VMOVDQU X5, 16(BX)
    VMOVDQU X6, 32(BX)
    VMOVDQU X7, 48(BX)
    
finalize:
    XORQ R11, R11
    XORQ R12, R12
    MOVQ CX, BP
xor_loop:
    MOVB 0(SI), R11
    MOVB 0(BX), R12
    XORQ R11, R12
    MOVB R12, 0(DI)
    INCQ SI
    INCQ BX
    INCQ DI
    DECQ BP
    JA xor_loop

done:
    VMOVDQU X3, 48(AX)
    VZEROUPPER
    MOVQ R8, SP
    MOVQ CX, ret+72(FP)
    RET

// func hChaCha20AVX(out *[32]byte, nonce *[16]byte, key *[32]byte)
TEXT ·hChaCha20AVX(SB), 4, $0-24
    MOVQ out+0(FP), DI
    MOVQ nonce+8(FP), AX
    MOVQ key+16(FP), BX

    VMOVDQU ·sigma_AVX<>(SB), X0
    VMOVDQU 0(BX), X1
    VMOVDQU 16(BX), X2
    VMOVDQU 0(AX), X3
    VMOVDQU ·rol16_AVX2<>(SB), X5
    VMOVDQU ·rol8_AVX2<>(SB), X6

    MOVQ $20, CX
chacha_loop:
    CHACHA_QROUND(X0, X1, X2, X3, X4, X5, X6)
    CHACHA_SHUFFLE(X1, X2, X3)
    CHACHA_QROUND(X0, X1, X2, X3, X4, X5, X6)
    CHACHA_SHUFFLE(X3, X2, X1)
    SUBQ $2, CX
    JNZ chacha_loop

    VMOVDQU X0, 0(DI)
    VMOVDQU X3, 16(DI)
    VZEROUPPER
    RET

// func supportsAVX2() bool
TEXT ·supportsAVX2(SB), 4, $0-1
	//MOVQ runtime·support_avx(SB), AX
    MOVQ runtime·support_avx2(SB), BX
    //ORQ AX, BX
	MOVB BX, ret+0(FP)
    RET
