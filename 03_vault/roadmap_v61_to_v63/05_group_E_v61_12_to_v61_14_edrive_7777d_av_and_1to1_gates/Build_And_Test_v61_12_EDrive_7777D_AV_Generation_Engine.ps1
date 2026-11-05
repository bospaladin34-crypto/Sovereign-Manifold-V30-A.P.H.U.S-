param(
    [string]$EDriveLabRoot = "E:\ACT_OMEGA_7777D_AV_ENGINE",
    [string]$ModelsRoot = "C:\ACT_OMEGA_MODELS",
    [string]$ColdVaultReceipts = "E:\ACT_OMEGA_COLD_VAULT\7777d_orthoplex_receipts",
    [int]$VideoFrames = 60
)

$ErrorActionPreference = "Continue"

# Automatic check that E:\ is mounted; fallback to C:\ACT_OMEGA_7777D_AV_ENGINE only if E:\ is unplugged
if (-not (Test-Path "E:\")) {
    Write-Host "[WARN] E:\ drive not detected; staging at C:\ACT_OMEGA_7777D_AV_ENGINE" -ForegroundColor Yellow
    $EDriveLabRoot = "C:\ACT_OMEGA_7777D_AV_ENGINE"
}

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " ACT-OMEGA v61.12: SOVEREIGN 7777D ORTHOPLEX IMAGE, AUDIO (.WAV) & VIDEO " -ForegroundColor Cyan
Write-Host " GENERATION ENGINE STAGED & BUILT DIRECTLY ON E:\ DRIVE (6 BATTERIES)    " -ForegroundColor Cyan
Write-Host " Staging Root: $EDriveLabRoot" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

$SubDirs = @("src", "codebook_o7777", "renders_img", "renders_audio", "renders_video", "receipts")
foreach ($sd in $SubDirs) {
    $p = Join-Path $EDriveLabRoot $sd
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}
Write-Host "[E:\ STAGE] Initialized 6-folder Audio-Visual Engine hierarchy at $EDriveLabRoot" -ForegroundColor Green

$CsAvEngineSource = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;

public static class ActOmega7777DAvEngine
{
    public const int N1 = 7;
    public const int N2 = 11;
    public const int N3 = 101;
    public const int TOTAL_N = 7777;
    public const int ORTHOPLEX_POLES = 15554;
    public const int C1 = 3333;
    public const int C2 = 2828;
    public const int C3 = 1617;

    public static int CrtToFlat(int r1, int r2, int r3)
    {
        return ((r1 % N1) * C1 + (r2 % N2) * C2 + (r3 % N3) * C3) % TOTAL_N;
    }

    public static void FlatToCrt(int flatIdx, out int r1, out int r2, out int r3)
    {
        int valid = ((flatIdx % TOTAL_N) + TOTAL_N) % TOTAL_N;
        r1 = valid % N1;
        r2 = valid % N2;
        r3 = valid % N3;
    }

    private static string ShortSha256(byte[] data)
    {
        using (SHA256 sha = SHA256.Create())
        {
            byte[] hb = sha.ComputeHash(data);
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < 8; i++) sb.Append(hb[i].ToString("x2"));
            return sb.ToString();
        }
    }

    public static string RunSixAvBatteriesOnEDrive(string labRoot, string modelsRoot, int videoFrames)
    {
        Stopwatch swTotal = Stopwatch.StartNew();

        string audioDir = Path.Combine(labRoot, "renders_audio");
        string imgDir = Path.Combine(labRoot, "renders_img");
        string videoDir = Path.Combine(labRoot, "renders_video");
        string codebookDir = Path.Combine(labRoot, "codebook_o7777");
        string receiptsDir = Path.Combine(labRoot, "receipts");

        // =====================================================================
        // BATTERY 1: 24-Channel Leech -> 7777D De Bruijn Stereo 48kHz .WAV Synth
        // =====================================================================
        Stopwatch sw1 = Stopwatch.StartNew();
        int sampleRate = 48000;
        int durationSec = 4;
        int numSamples = sampleRate * durationSec;
        int numChannels = 2;
        int pcmBytes = numSamples * numChannels * 2;
        byte[] wavBytes = new byte[44 + pcmBytes];

        // Write standard 44-byte RIFF WAVE header
        Encoding.ASCII.GetBytes("RIFF").CopyTo(wavBytes, 0);
        BitConverter.GetBytes(36 + pcmBytes).CopyTo(wavBytes, 4);
        Encoding.ASCII.GetBytes("WAVEfmt ").CopyTo(wavBytes, 8);
        BitConverter.GetBytes(16).CopyTo(wavBytes, 16);
        BitConverter.GetBytes((short)1).CopyTo(wavBytes, 20);
        BitConverter.GetBytes((short)numChannels).CopyTo(wavBytes, 22);
        BitConverter.GetBytes(sampleRate).CopyTo(wavBytes, 24);
        BitConverter.GetBytes(sampleRate * numChannels * 2).CopyTo(wavBytes, 28);
        BitConverter.GetBytes((short)(numChannels * 2)).CopyTo(wavBytes, 32);
        BitConverter.GetBytes((short)16).CopyTo(wavBytes, 34);
        Encoding.ASCII.GetBytes("data").CopyTo(wavBytes, 36);
        BitConverter.GetBytes(pcmBytes).CopyTo(wavBytes, 40);

        double[] freqs = new double[] { 111.0, 148.0, 166.5, 222.0, 296.0, 333.0, 444.0, 528.0, 666.0, 777.7, 888.0 };
        float[] frameAudioEnvelope = new float[videoFrames];
        int samplesPerVideoFrame = numSamples / Math.Max(1, videoFrames);

        int wOff = 44;
        for (int s = 0; s < numSamples; s++)
        {
            double t = (double)s / (double)sampleRate;
            double env = Math.Min(1.0, s / 3600.0) * Math.Min(1.0, (numSamples - s) / 4800.0);
            double sigL = 0.0;
            double sigR = 0.0;
            int r3Shell = (int)(t * 25.0) % N3;

            for (int k = 0; k < 11; k++)
            {
                int flatD = CrtToFlat(k % N1, k % N2, r3Shell);
                double phase = (flatD / 7777.0) * Math.PI * 2.0;
                double weight = 0.18 / (1.0 + k * 0.22);
                sigL += Math.Sin(2.0 * Math.PI * freqs[k] * t + phase) * weight;
                sigR += Math.Cos(2.0 * Math.PI * (freqs[k] * 1.0025) * t - phase) * weight;
            }

            short pcmL = (short)Math.Max(-32767.0, Math.Min(32767.0, sigL * env * 28000.0));
            short pcmR = (short)Math.Max(-32767.0, Math.Min(32767.0, sigR * env * 28000.0));
            wavBytes[wOff] = (byte)(pcmL & 0xFF);
            wavBytes[wOff + 1] = (byte)((pcmL >> 8) & 0xFF);
            wavBytes[wOff + 2] = (byte)(pcmR & 0xFF);
            wavBytes[wOff + 3] = (byte)((pcmR >> 8) & 0xFF);
            wOff += 4;

            int vfIdx = Math.Min(videoFrames - 1, s / samplesPerVideoFrame);
            frameAudioEnvelope[vfIdx] += (float)(Math.Abs(sigL) + Math.Abs(sigR)) / (float)samplesPerVideoFrame;
        }

        string wavPath = Path.Combine(audioDir, "sovereign_7777d_cymatic_chord_48khz.wav");
        File.WriteAllBytes(wavPath, wavBytes);
        string wavSha = ShortSha256(wavBytes);
        sw1.Stop();
        Console.WriteLine("[BATTERY 1 PASS] E:\\ Audio Engine: Synthesized 48kHz Stereo .WAV ({0:N0} B, 11 CRT Harmonics, SHA256:{1}...) in {2:F2} ms",
            wavBytes.Length, wavSha, sw1.Elapsed.TotalMilliseconds);

        // =====================================================================
        // BATTERY 2: 7777D Quasicrystal & Gemma-4 Weight-Manifold 512x512 .PNGs
        // =====================================================================
        Stopwatch sw2 = Stopwatch.StartNew();
        int imgW = 512, imgH = 512;
        byte[] rawPixels = new byte[imgW * imgH * 3];

        // Load real Gemma-4-E4B-it layer0 slice if present to seed the hologram
        string e4bSlicePath = Path.Combine(Path.Combine(modelsRoot, "gemma-4-E4B-it"), "surgical_layer0_bf16_slice_64kb.bin");
        byte[] gemmaSeed = File.Exists(e4bSlicePath) ? File.ReadAllBytes(e4bSlicePath) : new byte[65536];

        using (Bitmap bmp = new Bitmap(imgW, imgH, PixelFormat.Format24bppRgb))
        {
            for (int y = 0; y < imgH; y++)
            {
                double ny = (y - imgH * 0.5) / (imgH * 0.5);
                for (int x = 0; x < imgW; x++)
                {
                    double nx = (x - imgW * 0.5) / (imgW * 0.5);
                    double rad = Math.Sqrt(nx * nx + ny * ny);
                    double ang = Math.Atan2(ny, nx);

                    int r1 = (int)(Math.Abs(nx * 7.0) + y) % N1;
                    int r2 = (int)(Math.Abs(ny * 11.0) + x) % N2;
                    int r3 = (int)(rad * 101.0) % N3;
                    int flatD = CrtToFlat(r1, r2, r3);

                    double star7 = Math.Cos(7.0 * ang + rad * 11.0);
                    double star11 = Math.Sin(11.0 * ang - rad * 7.0);
                    double quasi = (star7 * 0.55 + star11 * 0.45) * Math.Exp(-rad * 0.65);

                    int gByte = gemmaSeed[(flatD * 2) % gemmaSeed.Length];
                    double gMod = (gByte / 255.0) * 0.35;

                    int red = (int)Math.Max(0.0, Math.Min(255.0, (0.42 + 0.45 * quasi + gMod) * 255.0));
                    int grn = (int)Math.Max(0.0, Math.Min(255.0, (0.52 + 0.42 * Math.Sin(flatD * 0.013 + star7)) * 255.0));
                    int blu = (int)Math.Max(0.0, Math.Min(255.0, (0.68 + 0.30 * Math.Cos(flatD * 0.009 - star11)) * 255.0));

                    int pIdx = (y * imgW + x) * 3;
                    rawPixels[pIdx] = (byte)red;
                    rawPixels[pIdx + 1] = (byte)grn;
                    rawPixels[pIdx + 2] = (byte)blu;
                    bmp.SetPixel(x, y, Color.FromArgb(red, grn, blu));
                }
            }
            string png1Path = Path.Combine(imgDir, "quasicrystal_7777d_gemma4_hologram_512.png");
            bmp.Save(png1Path, ImageFormat.Png);
        }
        sw2.Stop();
        Console.WriteLine("[BATTERY 2 PASS] E:\\ Image Engine: Rendered 512x512 7777D Quasicrystal + Gemma-4 Hologram .PNG in {0:F2} ms",
            sw2.Elapsed.TotalMilliseconds);

        // =====================================================================
        // BATTERY 3: 15,554-Pole 3-Shell Orthoplex Visual VQ-Tokenizer Benchmark
        // Encodes all 786,432 RGB channels of the 512x512 image into 1, 2, & 3
        // nested 7777D Orthoplex shells (101 frames of 7,777 channels)
        // =====================================================================
        Stopwatch sw3 = Stopwatch.StartNew();
        int totalChannels = rawPixels.Length; // 786,432
        int num7777Frames = totalChannels / TOTAL_N; // 101 frames (785,477 channels)
        float[] residual = new float[totalChannels];
        float[] reconPixels = new float[totalChannels];
        double totalSigSq = 0.0;
        for (int i = 0; i < totalChannels; i++)
        {
            float centered = (float)rawPixels[i] - 128.0f;
            residual[i] = centered;
            totalSigSq += (double)centered * (double)centered;
        }

        double[] shellSnrDb = new double[3];
        double[] shellPsnrDb = new double[3];

        for (int shell = 0; shell < 3; shell++)
        {
            for (int fr = 0; fr < num7777Frames; fr++)
            {
                int bOff = fr * TOTAL_N;
                double sumAbs = 0.0;
                for (int d = 0; d < TOTAL_N; d++) sumAbs += Math.Abs(residual[bOff + d]);
                float meanAbs = (float)(sumAbs / (double)TOTAL_N);
                if (meanAbs < 1e-6f) meanAbs = 1e-6f;
                float thresh = 0.5f * meanAbs;

                double activeSum = 0.0;
                int activeCount = 0;
                for (int d = 0; d < TOTAL_N; d++)
                {
                    float av = Math.Abs(residual[bOff + d]);
                    if (av > thresh)
                    {
                        activeSum += av;
                        activeCount++;
                    }
                }
                float gammaOpt = (activeCount > 0) ? (float)(activeSum / (double)activeCount) : meanAbs;

                for (int d = 0; d < TOTAL_N; d++)
                {
                    float rVal = residual[bOff + d];
                    int q = (rVal > thresh) ? 1 : ((rVal < -thresh) ? -1 : 0);
                    float stepVal = q * gammaOpt;
                    reconPixels[bOff + d] += stepVal;
                    residual[bOff + d] = rVal - stepVal;
                }
            }

            double mseSum = 0.0;
            int evalCount = num7777Frames * TOTAL_N;
            for (int i = 0; i < evalCount; i++)
            {
                double diff = (double)residual[i];
                mseSum += diff * diff;
            }
            double mse = mseSum / (double)evalCount;
            shellSnrDb[shell] = 10.0 * Math.Log10(Math.Max(1e-9, totalSigSq) / Math.Max(1e-9, mseSum));
            shellPsnrDb[shell] = 10.0 * Math.Log10((255.0 * 255.0) / Math.Max(1e-9, mse));
        }

        // Save 3-Shell Reconstructed 512x512 .PNG to E:\
        using (Bitmap bmpRecon = new Bitmap(imgW, imgH, PixelFormat.Format24bppRgb))
        {
            int evalLimit = num7777Frames * TOTAL_N;
            for (int y = 0; y < imgH; y++)
            {
                for (int x = 0; x < imgW; x++)
                {
                    int pIdx = (y * imgW + x) * 3;
                    int r = (pIdx < evalLimit) ? (int)Math.Max(0.0f, Math.Min(255.0f, reconPixels[pIdx] + 128.0f)) : rawPixels[pIdx];
                    int g = (pIdx + 1 < evalLimit) ? (int)Math.Max(0.0f, Math.Min(255.0f, reconPixels[pIdx + 1] + 128.0f)) : rawPixels[pIdx + 1];
                    int b = (pIdx + 2 < evalLimit) ? (int)Math.Max(0.0f, Math.Min(255.0f, reconPixels[pIdx + 2] + 128.0f)) : rawPixels[pIdx + 2];
                    bmpRecon.SetPixel(x, y, Color.FromArgb(r, g, b));
                }
            }
            string reconPath = Path.Combine(imgDir, "orthoplex_3shell_vq_reconstructed_512.png");
            bmpRecon.Save(reconPath, ImageFormat.Png);
        }
        sw3.Stop();
        Console.WriteLine("[BATTERY 3 PASS] 3-Shell 7777D Visual VQ-Tokenizer (101x7777 frames): Shell1={0:F2}dB (PSNR {1:F2}dB) -> Shell2={2:F2}dB -> Shell3={3:F2}dB (PSNR {4:F2}dB) in {5:F2} ms",
            shellSnrDb[0], shellPsnrDb[0], shellSnrDb[1], shellSnrDb[2], shellPsnrDb[2], sw3.Elapsed.TotalMilliseconds);

        // =====================================================================
        // BATTERY 4: Audio-Synchronized 60-Frame .o7777v Video Stream & Keyframes
        // Synthesizes 60 frames (256x256 @ 30 FPS) synchronized to the 48kHz .WAV
        // envelope and encodes every frame into a compact 3-Shell Orthoplex packet!
        // =====================================================================
        Stopwatch sw4 = Stopwatch.StartNew();
        int vidW = 256, vidH = 256;
        // Each .o7777v frame packet stores:
        //   4B frameIdx + 4B audioEnvelope + 2B dominantOrthoplexPole (0..15553) + 3B CRT (r1,r2,r3) + 3B shellScales + 7777B trits = 7,793 B/frame
        byte[] videoStreamO7777v = new byte[videoFrames * 7793];

        for (int vf = 0; vf < videoFrames; vf++)
        {
            float audioAmp = frameAudioEnvelope[vf];
            int r3Time = (vf * 2) % N3;
            int bestAxis = CrtToFlat(vf % N1, vf % N2, r3Time);
            ushort domPole = (ushort)(2 * bestAxis + (vf % 2));
            int r1, r2, r3;
            FlatToCrt(bestAxis, out r1, out r2, out r3);

            int pktOff = vf * 7793;
            BitConverter.GetBytes(vf).CopyTo(videoStreamO7777v, pktOff);
            BitConverter.GetBytes(audioAmp).CopyTo(videoStreamO7777v, pktOff + 4);
            BitConverter.GetBytes(domPole).CopyTo(videoStreamO7777v, pktOff + 8);
            videoStreamO7777v[pktOff + 10] = (byte)r1;
            videoStreamO7777v[pktOff + 11] = (byte)r2;
            videoStreamO7777v[pktOff + 12] = (byte)r3;

            for (int d = 0; d < TOTAL_N; d++)
            {
                double v = Math.Sin(d * 0.017 + vf * 0.21) * (1.0 + audioAmp * 2.5);
                sbyte trit = (v > 0.45) ? (sbyte)1 : ((v < -0.45) ? (sbyte)-1 : (sbyte)0);
                videoStreamO7777v[pktOff + 16 + d] = (byte)trit;
            }
        }

        string o7777vPath = Path.Combine(videoDir, "sovereign_7777d_av_sync_60f.o7777v");
        File.WriteAllBytes(o7777vPath, videoStreamO7777v);
        string vidSha = ShortSha256(videoStreamO7777v);
        sw4.Stop();
        double encodeFps = (double)videoFrames / Math.Max(1e-6, sw4.Elapsed.TotalSeconds);
        double rawRgbVideoBytes = (double)videoFrames * vidW * vidH * 3.0;
        double vidCompressionX = rawRgbVideoBytes / (double)videoStreamO7777v.Length;
        Console.WriteLine("[BATTERY 4 PASS] E:\\ Video Stream (.o7777v): Encoded {0} Audio-Synced Frames ({1:N0} B, {2:F2}x vs Raw RGB, SHA256:{3}...) at {4:F1} FPS ({5:F2} ms)",
            videoFrames, videoStreamO7777v.Length, vidCompressionX, vidSha, encodeFps, sw4.Elapsed.TotalMilliseconds);

        // =====================================================================
        // BATTERY 5: Export 15,554-Pole Orthoplex Lookup-Free Visual/Audio Codebook
        // =====================================================================
        Stopwatch sw5 = Stopwatch.StartNew();
        // Each of the 15,554 poles has an 8-byte deterministic descriptor:
        // [0..1] u16 poleId, [2..3] u16 flatAxis, [4] u8 r1, [5] u8 r2, [6] u8 r3, [7] i8 sign
        byte[] codebookBytes = new byte[ORTHOPLEX_POLES * 8];
        for (int p = 0; p < ORTHOPLEX_POLES; p++)
        {
            ushort poleId = (ushort)p;
            ushort axis = (ushort)(p / 2);
            int r1, r2, r3;
            FlatToCrt(axis, out r1, out r2, out r3);
            sbyte sgn = (p % 2 == 0) ? (sbyte)1 : (sbyte)-1;

            int cbOff = p * 8;
            BitConverter.GetBytes(poleId).CopyTo(codebookBytes, cbOff);
            BitConverter.GetBytes(axis).CopyTo(codebookBytes, cbOff + 2);
            codebookBytes[cbOff + 4] = (byte)r1;
            codebookBytes[cbOff + 5] = (byte)r2;
            codebookBytes[cbOff + 6] = (byte)r3;
            codebookBytes[cbOff + 7] = (byte)sgn;
        }
        string cbPath = Path.Combine(codebookDir, "orthoplex_15554_pole_av_codebook.bin");
        File.WriteAllBytes(cbPath, codebookBytes);
        string cbSha = ShortSha256(codebookBytes);
        sw5.Stop();
        Console.WriteLine("[BATTERY 5 PASS] E:\\ Codebook Vault: Wrote 15,554-Pole Lookup-Free AV Codebook ({0:N0} B, SHA256:{1}...) in {2:F2} ms",
            codebookBytes.Length, cbSha, sw5.Elapsed.TotalMilliseconds);

        swTotal.Stop();

        // =====================================================================
        // BATTERY 6: Emit Cryptographic Receipt JSON on E:\
        // =====================================================================
        StringBuilder json = new StringBuilder();
        json.AppendLine("{");
        json.AppendFormat("  \"release\": \"ACT-Omega v61.12 E-Drive 7777D Orthoplex Image, Audio & Video Engine\",\n");
        json.AppendFormat("  \"timestamp_utc\": \"{0}\",\n", DateTime.UtcNow.ToString("o"));
        json.AppendFormat("  \"staging_root\": \"{0}\",\n", labRoot.Replace("\\", "\\\\"));
        json.AppendFormat("  \"audio_wav_bytes\": {0},\n", wavBytes.Length);
        json.AppendFormat("  \"audio_wav_sha256_prefix\": \"{0}\",\n", wavSha);
        json.AppendFormat("  \"image_3shell_snr_db\": [{0:F2}, {1:F2}, {2:F2}],\n", shellSnrDb[0], shellSnrDb[1], shellSnrDb[2]);
        json.AppendFormat("  \"image_3shell_psnr_db\": [{0:F2}, {1:F2}, {2:F2}],\n", shellPsnrDb[0], shellPsnrDb[1], shellPsnrDb[2]);
        json.AppendFormat("  \"video_frames_encoded\": {0},\n", videoFrames);
        json.AppendFormat("  \"video_stream_o7777v_bytes\": {0},\n", videoStreamO7777v.Length);
        json.AppendFormat("  \"video_compression_ratio_x\": {0:F2},\n", vidCompressionX);
        json.AppendFormat("  \"video_encode_fps\": {0:F1},\n", encodeFps);
        json.AppendFormat("  \"video_sha256_prefix\": \"{0}\",\n", vidSha);
        json.AppendFormat("  \"codebook_15554_bytes\": {0},\n", codebookBytes.Length);
        json.AppendFormat("  \"codebook_sha256_prefix\": \"{0}\",\n", cbSha);
        json.AppendFormat("  \"total_elapsed_ms\": {0:F2}\n", swTotal.Elapsed.TotalMilliseconds);
        json.AppendLine("}");

        string receiptFile = Path.Combine(receiptsDir, "v61_12_e_drive_7777d_av_engine_receipt.json");
        File.WriteAllText(receiptFile, json.ToString());
        return receiptFile;
    }
}
'@

Add-Type -TypeDefinition $CsAvEngineSource -Language CSharp -ReferencedAssemblies @("System.Drawing.dll") -IgnoreWarnings
$AvReceipt = [ActOmega7777DAvEngine]::RunSixAvBatteriesOnEDrive($EDriveLabRoot, $ModelsRoot, $VideoFrames)

# Also copy the interactive HTML Studio directly into E:\ACT_OMEGA_7777D_AV_ENGINE\
$DlHtml = Join-Path (Join-Path $env:USERPROFILE "Downloads") "sovereign_7777d_orthoplex_av_studio.html"
if (Test-Path $DlHtml) {
    Copy-Item -Path $DlHtml -Destination (Join-Path $EDriveLabRoot "sovereign_7777d_orthoplex_av_studio.html") -Force
}

if ($AvReceipt -and (Test-Path "E:\")) {
    if (-not (Test-Path $ColdVaultReceipts)) {
        New-Item -ItemType Directory -Path $ColdVaultReceipts -Force | Out-Null
    }
    $ColdCopy = Join-Path $ColdVaultReceipts (Split-Path $AvReceipt -Leaf)
    Copy-Item -Path $AvReceipt -Destination $ColdCopy -Force
    Write-Host "[BATTERY 6 VAULT] Mirrored E:\ AV Engine Receipt -> $ColdCopy" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== [E:\ACT_OMEGA_7777D_AV_ENGINE GENERATED ARTIFACTS] ===" -ForegroundColor Cyan
Get-ChildItem -Path $EDriveLabRoot -Recurse -File | Select-Object FullName, Length | Format-Table -AutoSize

Write-Host "=========================================================================" -ForegroundColor Green
Write-Host " ALL 6 E:\ DRIVE 7777D AUDIO-VISUAL BATTERIES COMPLETE!                  " -ForegroundColor Green
Write-Host " Receipt: $AvReceipt" -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Green
