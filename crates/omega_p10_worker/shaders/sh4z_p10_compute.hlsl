// =============================================================================
// ACT-Omega Pixel 10 (PowerVR DXT-48-1536 MC1, Vulkan 1.4.344, SubgroupSize=128)
// & Lenovo LOQ 15 (NVIDIA RTX 3050, SubgroupSize=32x4=128) 6-Kernel Compute Suite
// Strict Hardware Rule: ShaderFloat64 = No | LocalSize = (128, 1, 1) | PushConstants = 8B
// Bindings: Set 0 Binding 0 = SrcA, Binding 1 = SrcB, Binding 2 = DstOut
// =============================================================================
// K1 (SPIRV_K1_SH4Z_TERNARY)    : 16-Lane SH4Z 1.58-Bit Ternary {-1,0,+1} x INT8 Dot-Product
// K2 (SPIRV_K2_E8_QUANTIZE)     : Quarter-Integer 4*E8 Conway-Sloane 240-Root 8D Quantizer + H^1=0
// K3 (SPIRV_K3_GOLAY24_SYNDROME): Voyager [24,12,8] Extended Binary Golay + OpBitCount Syndrome
// K4 (SPIRV_K4_24CELL_CIPHER)   : SH4Z-SEC1 4-Round 4D Self-Dual 24-Cell Hurwitz Polytope Cipher
// K5 (SPIRV_K5_SHEAF_LAPLACIAN) : Cellular Sheaf Stalk Braid Transport & Hodge Energy ||d(phi)||^2
// K6 (SPIRV_K6_SUBGROUP_REDUCE) : SPIR-V 1.3 OpGroupNonUniformIAdd 128-Lane Wave Reduction
// =============================================================================

StructuredBuffer<uint> SrcA   : register(t0);
StructuredBuffer<uint> SrcB   : register(t1);
RWStructuredBuffer<uint> Dst  : register(u0);
cbuffer PushParams : register(b0) { uint Param0; uint Param1; };

[numthreads(128, 1, 1)]
void CSMain_K1_SH4Z(uint3 gid : SV_DispatchThreadID)
{
    uint i = gid.x;
    uint va = SrcA[i], vb = SrcB[i];
    uint aw0 = vb;
    uint aw1 = ((vb >> 7) | (vb << 25)) ^ Param0;
    uint aw2 = vb + 0x9E3779B9u;
    uint aw3 = vb ^ (i + Param0);
    uint aws[4] = { aw0, aw1, aw2, aw3 };
    uint acc = Param1;
    [unroll] for (uint k = 0; k < 16; ++k) {
        uint slot = (va >> (2 * k)) & 3u;
        uint trit = (slot & 1u) - ((slot >> 1) & 1u);
        uint act_s = ((aws[k >> 2] >> (8 * (k & 3))) & 0xFFu) - 128u;
        acc += trit * act_s;
    }
    Dst[i] = acc;
}
