// ACT-Omega Net v50.0.0 (SH4Z v5000 TLV | CHAIN 145)
// Windows SDK 10.0.26100.0 DXC 1.8 (cs_6_6) DirectX 12 DP4A Compute Shader
// Evaluates 64-byte .e8z Tri-Bank Harmonic Cachelines (16 x packed int8x4 words per 64B cacheline)
// using hardware dot4add_i8packed (DP4A) on NVIDIA RTX 3050 (Ampere GA107, 6144 MiB).

ByteAddressBuffer E8zTriBankVault : register(t0);
RWStructuredBuffer<int> CachelineNormOut : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 dtid : SV_DispatchThreadID)
{
    uint cacheline_idx = dtid.x;
    if (cacheline_idx >= 6240u)
    {
        return;
    }

    uint byte_offset = cacheline_idx * 64u;
    int acc = 0;

    // Sweep all 16 x 32-bit words (64 bytes = 100% cacheline byte coverage) via hardware DP4A
    [unroll]
    for (uint w = 0u; w < 16u; ++w)
    {
        uint packed_i8x4 = E8zTriBankVault.Load(byte_offset + (w * 4u));
        acc = dot4add_i8packed(packed_i8x4, packed_i8x4, acc);
    }

    CachelineNormOut[cacheline_idx] = acc;
}
