	.def	@feat.00;
	.scl	3;
	.type	0;
	.endef
	.globl	@feat.00
@feat.00 = 0
	.intel_syntax noprefix
	.file	"sovereign_e8_avx2"
	.def	sovereign_e8_avx2.sovereign_zig_e8_norm_sq8;
	.scl	3;
	.type	32;
	.endef
	.text
	.p2align	4
sovereign_e8_avx2.sovereign_zig_e8_norm_sq8:
.Lfunc_begin0:
	.cv_func_id 0
	.cv_file	1 "C:\\sovereign_manifold_v31\\00_control\\zig_simd\\sovereign_e8_avx2.zig"
	.cv_loc	0 1 37 0
.seh_proc sovereign_e8_avx2.sovereign_zig_e8_norm_sq8
	push	rbp
	.seh_pushreg rbp
	mov	rbp, rsp
	.seh_setframe rbp, 0
	.seh_endprologue
.Ltmp0:
	.cv_loc	0 1 38 29
	vmovups	ymm0, ymmword ptr [rcx]
.Ltmp1:
	.cv_loc	0 1 39 29
	vmovups	ymm1, ymmword ptr [rdx]
.Ltmp2:
	.cv_loc	0 1 40 29
	vsubps	ymm2, ymm0, ymm1
.Ltmp3:
	.cv_loc	0 1 41 53
	vmulps	ymm2, ymm2, ymm2
.Ltmp4:
	vfmadd231ps	ymm2, ymm0, ymm1
.Ltmp5:
	.cv_loc	0 1 42 5
	vmovshdup	xmm0, xmm2
.Ltmp6:
	vaddss	xmm0, xmm2, xmm0
	vshufpd	xmm1, xmm2, xmm2, 1
.Ltmp7:
	vaddss	xmm0, xmm1, xmm0
	vshufps	xmm1, xmm2, xmm2, 255
	vaddss	xmm0, xmm1, xmm0
	vextractf128	xmm1, ymm2, 1
	vaddss	xmm0, xmm1, xmm0
	vmovshdup	xmm2, xmm1
.Ltmp8:
	vaddss	xmm0, xmm2, xmm0
	vshufpd	xmm2, xmm1, xmm1, 1
	vaddss	xmm0, xmm2, xmm0
	vshufps	xmm1, xmm1, xmm1, 255
	vaddss	xmm0, xmm1, xmm0
	.seh_startepilogue
	pop	rbp
	.seh_endepilogue
	vzeroupper
	ret
.Ltmp9:
.Lfunc_end0:
	.seh_endproc

	.def	sovereign_e8_avx2.sovereign_zig_e8_cacheline_dot64;
	.scl	3;
	.type	32;
	.endef
	.p2align	4
sovereign_e8_avx2.sovereign_zig_e8_cacheline_dot64:
.Lfunc_begin1:
	.cv_func_id 1
	.cv_loc	1 1 14 0
.seh_proc sovereign_e8_avx2.sovereign_zig_e8_cacheline_dot64
	push	rbp
	.seh_pushreg rbp
	mov	rbp, rsp
	.seh_setframe rbp, 0
	.seh_endprologue
.Ltmp10:
	.cv_loc	1 1 15 33
	vpmovsxbw	ymm0, xmmword ptr [rcx]
	vpmovsxbw	ymm1, xmmword ptr [rcx + 16]
.Ltmp11:
	.cv_loc	1 1 16 33
	vpmovsxbw	ymm2, xmmword ptr [rcx + 32]
	vpmovsxbw	ymm3, xmmword ptr [rcx + 48]
.Ltmp12:
	.cv_loc	1 1 17 33
	vpmovsxbw	ymm4, xmmword ptr [rdx]
	.cv_loc	1 1 25 38
	vpmullw	ymm0, ymm4, ymm0
	.cv_loc	1 1 17 33
	vpmovsxbw	ymm4, xmmword ptr [rdx + 16]
.Ltmp13:
	.cv_loc	1 1 25 38
	vpmullw	ymm1, ymm4, ymm1
	.cv_loc	1 1 28 5
	vpaddw	ymm0, ymm0, ymm1
	.cv_loc	1 1 18 33
	vpmovsxbw	ymm1, xmmword ptr [rdx + 32]
	vpmovsxbw	ymm4, xmmword ptr [rdx + 48]
.Ltmp14:
	.cv_loc	1 1 26 38
	vpmullw	ymm1, ymm1, ymm2
	vpmullw	ymm2, ymm4, ymm3
.Ltmp15:
	.cv_loc	1 1 29 5
	vpaddw	ymm1, ymm1, ymm2
	.cv_loc	1 1 28 5
	vextracti128	xmm2, ymm0, 1
	vpaddw	xmm0, xmm0, xmm2
	vpshufd	xmm2, xmm0, 238
	vpaddw	xmm0, xmm0, xmm2
	vpshufd	xmm2, xmm0, 85
	vpaddw	xmm0, xmm0, xmm2
	vpsrld	xmm2, xmm0, 16
	vpaddw	xmm0, xmm0, xmm2
	vmovd	eax, xmm0
	.cv_loc	1 1 28 25
	movsx	ecx, ax
.Ltmp16:
	.cv_loc	1 1 29 5
	vextracti128	xmm0, ymm1, 1
	vpaddw	xmm0, xmm1, xmm0
	vpshufd	xmm1, xmm0, 238
	vpaddw	xmm0, xmm0, xmm1
	vpshufd	xmm1, xmm0, 85
	vpaddw	xmm0, xmm0, xmm1
	vpsrld	xmm1, xmm0, 16
	vpaddw	xmm0, xmm0, xmm1
	vmovd	eax, xmm0
	.cv_loc	1 1 29 25
	cwde
.Ltmp17:
	.cv_loc	1 1 30 19
	add	eax, ecx
.Ltmp18:
	.cv_loc	1 1 30 5
	.seh_startepilogue
	pop	rbp
	.seh_endepilogue
	vzeroupper
	ret
.Ltmp19:
.Lfunc_end1:
	.seh_endproc

	.globl	sovereign_zig_e8_norm_sq8
	.def	sovereign_zig_e8_norm_sq8;
	.scl	2;
	.type	32;
	.endef
sovereign_zig_e8_norm_sq8 = sovereign_e8_avx2.sovereign_zig_e8_norm_sq8
	.globl	sovereign_zig_e8_cacheline_dot64
	.def	sovereign_zig_e8_cacheline_dot64;
	.scl	2;
	.type	32;
	.endef
sovereign_zig_e8_cacheline_dot64 = sovereign_e8_avx2.sovereign_zig_e8_cacheline_dot64
	.section	.debug$S,"dr"
	.p2align	2, 0x0
	.long	4
	.long	241
	.long	.Ltmp21-.Ltmp20
.Ltmp20:
	.short	.Ltmp23-.Ltmp22
.Ltmp22:
	.short	4353
	.long	0
	.byte	0
	.p2align	2, 0x0
.Ltmp23:
	.short	.Ltmp25-.Ltmp24
.Ltmp24:
	.short	4412
	.long	0
	.short	208
	.short	0
	.short	17
	.short	0
	.short	0
	.short	22018
	.short	0
	.short	0
	.short	0
	.asciz	"zig 0.17.0"
	.p2align	2, 0x0
.Ltmp25:
.Ltmp21:
	.p2align	2, 0x0
	.long	241
	.long	.Ltmp27-.Ltmp26
.Ltmp26:
	.short	.Ltmp29-.Ltmp28
.Ltmp28:
	.short	4422
	.long	0
	.long	0
	.long	0
	.long	.Lfunc_end0-sovereign_e8_avx2.sovereign_zig_e8_norm_sq8
	.long	0
	.long	0
	.long	4098
	.secrel32	sovereign_e8_avx2.sovereign_zig_e8_norm_sq8
	.secidx	sovereign_e8_avx2.sovereign_zig_e8_norm_sq8
	.byte	129
	.asciz	"sovereign_zig_e8_norm_sq8"
	.p2align	2, 0x0
.Ltmp29:
	.short	.Ltmp31-.Ltmp30
.Ltmp30:
	.short	4114
	.long	8
	.long	0
	.long	0
	.long	0
	.long	0
	.short	0
	.long	1220608
	.p2align	2, 0x0
.Ltmp31:
	.short	.Ltmp33-.Ltmp32
.Ltmp32:
	.short	4414
	.long	1600
	.short	1
	.asciz	"vec_a"
	.p2align	2, 0x0
.Ltmp33:
	.cv_def_range	 .Lfunc_begin0 .Lfunc_end0, reg, 330
	.short	.Ltmp35-.Ltmp34
.Ltmp34:
	.short	4414
	.long	1600
	.short	1
	.asciz	"vec_b"
	.p2align	2, 0x0
.Ltmp35:
	.cv_def_range	 .Lfunc_begin0 .Lfunc_end0, reg, 331
	.short	.Ltmp37-.Ltmp36
.Ltmp36:
	.short	4414
	.long	4099
	.short	0
	.asciz	"a"
	.p2align	2, 0x0
.Ltmp37:
	.cv_def_range	 .Ltmp1 .Ltmp6, reg, 368
	.short	.Ltmp39-.Ltmp38
.Ltmp38:
	.short	4414
	.long	4099
	.short	0
	.asciz	"b"
	.p2align	2, 0x0
.Ltmp39:
	.cv_def_range	 .Ltmp2 .Ltmp7, reg, 369
	.short	.Ltmp41-.Ltmp40
.Ltmp40:
	.short	4414
	.long	4099
	.short	0
	.asciz	"diff"
	.p2align	2, 0x0
.Ltmp41:
	.cv_def_range	 .Ltmp3 .Ltmp4, reg, 370
	.short	.Ltmp43-.Ltmp42
.Ltmp42:
	.short	4414
	.long	4099
	.short	0
	.asciz	"sq"
	.p2align	2, 0x0
.Ltmp43:
	.cv_def_range	 .Ltmp5 .Ltmp8, reg, 370
	.short	2
	.short	4431
.Ltmp27:
	.p2align	2, 0x0
	.cv_linetable	0, sovereign_e8_avx2.sovereign_zig_e8_norm_sq8, .Lfunc_end0
	.long	241
	.long	.Ltmp45-.Ltmp44
.Ltmp44:
	.short	.Ltmp47-.Ltmp46
.Ltmp46:
	.short	4422
	.long	0
	.long	0
	.long	0
	.long	.Lfunc_end1-sovereign_e8_avx2.sovereign_zig_e8_cacheline_dot64
	.long	0
	.long	0
	.long	4102
	.secrel32	sovereign_e8_avx2.sovereign_zig_e8_cacheline_dot64
	.secidx	sovereign_e8_avx2.sovereign_zig_e8_cacheline_dot64
	.byte	129
	.asciz	"sovereign_zig_e8_cacheline_dot64"
	.p2align	2, 0x0
.Ltmp47:
	.short	.Ltmp49-.Ltmp48
.Ltmp48:
	.short	4114
	.long	8
	.long	0
	.long	0
	.long	0
	.long	0
	.short	0
	.long	1220608
	.p2align	2, 0x0
.Ltmp49:
	.short	.Ltmp51-.Ltmp50
.Ltmp50:
	.short	4414
	.long	1552
	.short	1
	.asciz	"line_a"
	.p2align	2, 0x0
.Ltmp51:
	.cv_def_range	 .Lfunc_begin1 .Ltmp16, reg, 330
	.short	.Ltmp53-.Ltmp52
.Ltmp52:
	.short	4414
	.long	1552
	.short	1
	.asciz	"line_b"
	.p2align	2, 0x0
.Ltmp53:
	.cv_def_range	 .Lfunc_begin1 .Lfunc_end1, reg, 331
	.short	.Ltmp55-.Ltmp54
.Ltmp54:
	.short	4414
	.long	4103
	.short	256
	.asciz	"a_lo"
	.p2align	2, 0x0
.Ltmp55:
	.short	.Ltmp57-.Ltmp56
.Ltmp56:
	.short	4414
	.long	4103
	.short	256
	.asciz	"a_hi"
	.p2align	2, 0x0
.Ltmp57:
	.short	.Ltmp59-.Ltmp58
.Ltmp58:
	.short	4414
	.long	4103
	.short	256
	.asciz	"b_lo"
	.p2align	2, 0x0
.Ltmp59:
	.short	.Ltmp61-.Ltmp60
.Ltmp60:
	.short	4414
	.long	4103
	.short	256
	.asciz	"b_hi"
	.p2align	2, 0x0
.Ltmp61:
	.short	.Ltmp63-.Ltmp62
.Ltmp62:
	.short	4414
	.long	4104
	.short	256
	.asciz	"a_lo16"
	.p2align	2, 0x0
.Ltmp63:
	.short	.Ltmp65-.Ltmp64
.Ltmp64:
	.short	4414
	.long	4104
	.short	256
	.asciz	"a_hi16"
	.p2align	2, 0x0
.Ltmp65:
	.short	.Ltmp67-.Ltmp66
.Ltmp66:
	.short	4414
	.long	4104
	.short	256
	.asciz	"b_lo16"
	.p2align	2, 0x0
.Ltmp67:
	.short	.Ltmp69-.Ltmp68
.Ltmp68:
	.short	4414
	.long	4104
	.short	256
	.asciz	"b_hi16"
	.p2align	2, 0x0
.Ltmp69:
	.short	.Ltmp71-.Ltmp70
.Ltmp70:
	.short	4414
	.long	4104
	.short	256
	.asciz	"prod_lo"
	.p2align	2, 0x0
.Ltmp71:
	.short	.Ltmp73-.Ltmp72
.Ltmp72:
	.short	4414
	.long	4104
	.short	256
	.asciz	"prod_hi"
	.p2align	2, 0x0
.Ltmp73:
	.short	.Ltmp75-.Ltmp74
.Ltmp74:
	.short	4414
	.long	116
	.short	0
	.asciz	"sum_lo"
	.p2align	2, 0x0
.Ltmp75:
	.cv_def_range	 .Ltmp16 .Lfunc_end1, reg, 18
	.short	.Ltmp77-.Ltmp76
.Ltmp76:
	.short	4414
	.long	116
	.short	0
	.asciz	"sum_hi"
	.p2align	2, 0x0
.Ltmp77:
	.cv_def_range	 .Ltmp17 .Ltmp18, reg, 17
	.short	2
	.short	4431
.Ltmp45:
	.p2align	2, 0x0
	.cv_linetable	1, sovereign_e8_avx2.sovereign_zig_e8_cacheline_dot64, .Lfunc_end1
	.cv_filechecksums
	.cv_stringtable
	.long	241
	.long	.Ltmp79-.Ltmp78
.Ltmp78:
	.short	.Ltmp81-.Ltmp80
.Ltmp80:
	.short	4428
	.long	4108
	.p2align	2, 0x0
.Ltmp81:
.Ltmp79:
	.p2align	2, 0x0
	.section	.debug$T,"dr"
	.p2align	2, 0x0
	.long	4
	.short	0xe
	.short	0x1201
	.long	0x2
	.long	0x640
	.long	0x640
	.short	0xe
	.short	0x1008
	.long	0x40
	.byte	0x0
	.byte	0x0
	.short	0x2
	.long	0x1000
	.short	0x26
	.short	0x1601
	.long	0x0
	.long	0x1001
	.asciz	"sovereign_zig_e8_norm_sq8"
	.byte	242
	.byte	241
	.short	0x1e
	.short	0x1503
	.long	0x40
	.long	0x23
	.short	0x20
	.asciz	"@Vector(8, f32)"
	.byte	242
	.byte	241
	.short	0xe
	.short	0x1201
	.long	0x2
	.long	0x610
	.long	0x610
	.short	0xe
	.short	0x1008
	.long	0x74
	.byte	0x0
	.byte	0x0
	.short	0x2
	.long	0x1004
	.short	0x2e
	.short	0x1601
	.long	0x0
	.long	0x1005
	.asciz	"sovereign_zig_e8_cacheline_dot64"
	.byte	243
	.byte	242
	.byte	241
	.short	0x1e
	.short	0x1503
	.long	0x10
	.long	0x23
	.short	0x20
	.asciz	"@Vector(32, i8)"
	.byte	242
	.byte	241
	.short	0x1e
	.short	0x1503
	.long	0x11
	.long	0x23
	.short	0x40
	.asciz	"@Vector(32, i16)"
	.byte	241
	.short	0x36
	.short	0x1605
	.long	0x0
	.asciz	"C:\\sovereign_manifold_v31\\00_control\\zig_simd"
	.byte	242
	.byte	241
	.short	0x1a
	.short	0x1605
	.long	0x0
	.asciz	"sovereign_e8_avx2"
	.byte	242
	.byte	241
	.short	0xa
	.short	0x1605
	.long	0x0
	.byte	0
	.byte	243
	.byte	242
	.byte	241
	.short	0x1a
	.short	0x1603
	.short	0x5
	.long	0x1009
	.long	0x100b
	.long	0x100a
	.long	0x100b
	.long	0x100b
	.byte	242
	.byte	241
