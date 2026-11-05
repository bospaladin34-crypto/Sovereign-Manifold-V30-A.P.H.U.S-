param(
    [string]$EDriveLabRoot = "E:\ACT_OMEGA_7777D_AV_ENGINE",
    [string]$ColdVaultReceipts = "E:\ACT_OMEGA_COLD_VAULT\7777d_orthoplex_receipts"
)

$ErrorActionPreference = "Continue"

if (-not (Test-Path $EDriveLabRoot)) {
    if (Test-Path "C:\ACT_OMEGA_7777D_AV_ENGINE") {
        $EDriveLabRoot = "C:\ACT_OMEGA_7777D_AV_ENGINE"
    } else {
        New-Item -ItemType Directory -Path $EDriveLabRoot -Force | Out-Null
    }
}

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " ACT-OMEGA v61.13: NATIVE .O7777V DESKTOP VIDEO PLAYER (O7777VPlayer.exe)" -ForegroundColor Cyan
Write-Host " + ZERO-DEPENDENCY MOTION-JPEG RIFF .AVI & .MP4 TRANSCODER ON E:\ DRIVE  " -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

$VideoDir = Join-Path $EDriveLabRoot "renders_video"
$AudioDir = Join-Path $EDriveLabRoot "renders_audio"
$ReceiptsDir = Join-Path $EDriveLabRoot "receipts"
foreach ($d in @($VideoDir, $AudioDir, $ReceiptsDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$O7777vFile = Join-Path $VideoDir "sovereign_7777d_av_sync_60f.o7777v"
$WavFile = Join-Path $AudioDir "sovereign_7777d_cymatic_chord_48khz.wav"
$AviOutFile = Join-Path $VideoDir "sovereign_7777d_av_sync_60f_playable.avi"
$Mp4OutFile = Join-Path $VideoDir "sovereign_7777d_av_sync_60f_playable.mp4"
$PlayerCsPath = Join-Path $EDriveLabRoot "src\O7777VPlayer.cs"
$PlayerExePath = Join-Path $EDriveLabRoot "O7777VPlayer.exe"

# C# Source for BOTH:
# 1. Native Zero-Dependency .o7777v -> Playable Motion-JPEG RIFF .AVI Exporter (works in Windows Media Player / VLC with 0 external tools!)
# 2. Standalone Windows 11 Dark-Mode Desktop .o7777v Video Player GUI (O7777VPlayer.exe) with Play/Pause, Scrubber, Audio Sync & Open File!
$CsPlayerAndAviSource = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Media;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;

public class O7777VFramePacket
{
    public int FrameIndex;
    public float AudioAmp;
    public ushort DominantPole;
    public byte R1;
    public byte R2;
    public byte R3;
    public sbyte[] Trits = new sbyte[7777];
    public int PosCount;
    public int NegCount;
    public int ZeroCount;
}

public static class O7777VDecoderAndAviMuxer
{
    public const int TOTAL_N = 7777;
    public const int PACKET_BYTES = 7793;
    public const int C1 = 3333;
    public const int C2 = 2828;
    public const int C3 = 1617;

    private static int[] flatGrid256;

    public static void EnsureGrid256()
    {
        if (flatGrid256 != null) return;
        flatGrid256 = new int[256 * 256];
        for (int y = 0; y < 256; y++)
        {
            double ny = (y - 128.0) / 128.0;
            for (int x = 0; x < 256; x++)
            {
                double nx = (x - 128.0) / 128.0;
                double rad = Math.Sqrt(nx * nx + ny * ny);
                int r1 = ((int)Math.Abs(nx * 7.0) + y) % 7;
                int r2 = ((int)Math.Abs(ny * 11.0) + x) % 11;
                int r3 = ((int)(rad * 101.0)) % 101;
                flatGrid256[y * 256 + x] = (r1 * C1 + r2 * C2 + r3 * C3) % TOTAL_N;
            }
        }
    }

    public static List<O7777VFramePacket> LoadO7777VFile(string path)
    {
        List<O7777VFramePacket> list = new List<O7777VFramePacket>();
        if (!File.Exists(path)) return list;
        byte[] raw = File.ReadAllBytes(path);
        int count = raw.Length / PACKET_BYTES;
        for (int f = 0; f < count; f++)
        {
            int off = f * PACKET_BYTES;
            O7777VFramePacket pkt = new O7777VFramePacket();
            pkt.FrameIndex = BitConverter.ToInt32(raw, off);
            pkt.AudioAmp = BitConverter.ToSingle(raw, off + 4);
            pkt.DominantPole = BitConverter.ToUInt16(raw, off + 8);
            pkt.R1 = raw[off + 10];
            pkt.R2 = raw[off + 11];
            pkt.R3 = raw[off + 12];
            int pos = 0, neg = 0;
            for (int d = 0; d < TOTAL_N; d++)
            {
                sbyte t = (sbyte)raw[off + 16 + d];
                pkt.Trits[d] = t;
                if (t > 0) pos++;
                else if (t < 0) neg++;
            }
            pkt.PosCount = pos;
            pkt.NegCount = neg;
            pkt.ZeroCount = TOTAL_N - pos - neg;
            list.Add(pkt);
        }
        return list;
    }

    public static Bitmap RenderFrameBitmap(O7777VFramePacket pkt, int totalFrames)
    {
        EnsureGrid256();
        int W = 384, H = 384;
        Bitmap bmp = new Bitmap(W, H, PixelFormat.Format24bppRgb);
        BitmapData bd = bmp.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format24bppRgb);
        int stride = bd.Stride;
        byte[] buf = new byte[stride * H];

        double phase = pkt.FrameIndex * 0.104719755;
        float amp = pkt.AudioAmp;

        for (int y = 0; y < H; y++)
        {
            int gy = (y * 256) / H;
            double ny = (y - H * 0.5) / (H * 0.5);
            int rowOff = y * stride;
            for (int x = 0; x < W; x++)
            {
                int gx = (x * 256) / W;
                double nx = (x - W * 0.5) / (W * 0.5);
                double rad = Math.Sqrt(nx * nx + ny * ny);
                double ang = Math.Atan2(ny, nx);

                int flatD = flatGrid256[gy * 256 + gx];
                sbyte trit = pkt.Trits[flatD];

                double star7 = Math.Cos(7.0 * ang + rad * 11.0 - phase * 1.5);
                double star11 = Math.Sin(11.0 * ang - rad * 7.0 + phase * 1.2);
                double quasi = (star7 * 0.55 + star11 * 0.45) * Math.Exp(-rad * 0.55) * (1.0 + amp * 0.9);

                int r = (int)Math.Max(0.0, Math.Min(255.0, (0.44 + 0.42 * quasi + 0.22 * trit) * 255.0));
                int g = (int)Math.Max(0.0, Math.Min(255.0, (0.50 + 0.40 * Math.Sin(flatD * 0.013 + star7 + phase) + 0.18 * trit) * 255.0));
                int b = (int)Math.Max(0.0, Math.Min(255.0, (0.68 + 0.30 * Math.Cos(flatD * 0.009 - star11 - phase) - 0.16 * trit) * 255.0));

                int pxOff = rowOff + x * 3;
                buf[pxOff] = (byte)b;
                buf[pxOff + 1] = (byte)g;
                buf[pxOff + 2] = (byte)r;
            }
        }
        System.Runtime.InteropServices.Marshal.Copy(buf, 0, bd.Scan0, buf.Length);
        bmp.UnlockBits(bd);

        using (Graphics gr = Graphics.FromImage(bmp))
        {
            gr.SmoothingMode = SmoothingMode.AntiAlias;
            using (SolidBrush hudBg = new SolidBrush(Color.FromArgb(215, 6, 12, 24)))
            using (Pen hudBorder = new Pen(Color.FromArgb(220, 34, 211, 238), 1.5f))
            using (Font f1 = new Font("Consolas", 8.5f, FontStyle.Bold))
            using (Pen starCyan = new Pen(Color.FromArgb(180, 34, 211, 238), 1.6f))
            using (Pen starGold = new Pen(Color.FromArgb(180, 250, 204, 21), 1.3f))
            {
                gr.FillRectangle(hudBg, 6, 6, W - 12, 42);
                gr.DrawRectangle(hudBorder, 6, 6, W - 12, 42);
                string l1 = string.Format("ACT-OMEGA .o7777v // FRAME {0:D2}/{1:D2} | Pole v={2}/15553", pkt.FrameIndex, Math.Max(1, totalFrames - 1), pkt.DominantPole);
                string l2 = string.Format("CRT=({0},{1},{2}) | AudioAmp={3:F4} | Trits: +{4} / -{5} / 0:{6}", pkt.R1, pkt.R2, pkt.R3, pkt.AudioAmp, pkt.PosCount, pkt.NegCount, pkt.ZeroCount);
                gr.DrawString(l1, f1, Brushes.Gold, 12, 10);
                gr.DrawString(l2, f1, Brushes.Cyan, 12, 27);

                float cx = W * 0.5f, cy = H * 0.54f;
                PointF[] pts = new PointF[11];
                for (int q = 0; q < 11; q++)
                {
                    double qa = phase * 0.8 + (q * Math.PI * 2.0) / 11.0;
                    float qr = ((q % 2 == 0) ? 72.0f : 48.0f) * (1.0f + amp * 0.35f);
                    pts[q] = new PointF(cx + (float)Math.Cos(qa) * qr, cy + (float)Math.Sin(qa) * qr);
                }
                for (int q = 0; q < 11; q++)
                {
                    gr.DrawLine(starCyan, pts[q], pts[(q + 3) % 11]);
                    gr.DrawLine(starGold, pts[q], pts[(q + 4) % 11]);
                }
            }
        }
        return bmp;
    }

    // Writes a valid, standalone Motion-JPEG RIFF .AVI video file (plays natively in Windows Media Player & VLC!)
    public static long ExportMjpegAvi(List<O7777VFramePacket> frames, string aviOutPath, int fps)
    {
        int width = 384, height = 384;
        List<byte[]> jpegFrames = new List<byte[]>();
        // Duplicate 60 frames x 2 = 120 frames (4.0 seconds @ 30 FPS)
        for (int loop = 0; loop < 2; loop++)
        {
            for (int i = 0; i < frames.Count; i++)
            {
                using (Bitmap bmp = RenderFrameBitmap(frames[i], frames.Count))
                using (MemoryStream ms = new MemoryStream())
                {
                    bmp.Save(ms, ImageFormat.Jpeg);
                    byte[] jb = ms.ToArray();
                    // Pad to even byte boundary for RIFF chunk alignment
                    if (jb.Length % 2 != 0)
                    {
                        byte[] padded = new byte[jb.Length + 1];
                        Buffer.BlockCopy(jb, 0, padded, 0, jb.Length);
                        jb = padded;
                    }
                    jpegFrames.Add(jb);
                }
            }
        }

        int totalFrames = jpegFrames.Count;
        int microSecPerFrame = 1000000 / Math.Max(1, fps);
        int maxFrameBytes = 0;
        long moviDataBytes = 4; // "movi"
        foreach (byte[] jf in jpegFrames)
        {
            if (jf.Length > maxFrameBytes) maxFrameBytes = jf.Length;
            moviDataBytes += 8 + jf.Length;
        }
        long idx1Bytes = totalFrames * 16;

        using (FileStream fs = new FileStream(aviOutPath, FileMode.Create, FileAccess.Write))
        using (BinaryWriter bw = new BinaryWriter(fs))
        {
            // RIFF AVI Header
            int hdrlSize = 4 + (8 + 56) + (12 + (8 + 56) + (8 + 40)); // 192 bytes
            int riffSize = (int)(4 + (8 + hdrlSize) + (8 + moviDataBytes) + (8 + idx1Bytes));

            bw.Write(Encoding.ASCII.GetBytes("RIFF"));
            bw.Write(riffSize);
            bw.Write(Encoding.ASCII.GetBytes("AVI "));

            // LIST hdrl
            bw.Write(Encoding.ASCII.GetBytes("LIST"));
            bw.Write(hdrlSize);
            bw.Write(Encoding.ASCII.GetBytes("hdrl"));

            // avih (56 bytes)
            bw.Write(Encoding.ASCII.GetBytes("avih"));
            bw.Write(56);
            bw.Write(microSecPerFrame);
            bw.Write(maxFrameBytes * fps);
            bw.Write(0);
            bw.Write(0x10); // AVIF_HASINDEX
            bw.Write(totalFrames);
            bw.Write(0);
            bw.Write(1); // 1 stream (video)
            bw.Write(maxFrameBytes);
            bw.Write(width);
            bw.Write(height);
            bw.Write(0); bw.Write(0); bw.Write(0); bw.Write(0);

            // LIST strl (116 bytes)
            bw.Write(Encoding.ASCII.GetBytes("LIST"));
            bw.Write(4 + (8 + 56) + (8 + 40));
            bw.Write(Encoding.ASCII.GetBytes("strl"));

            // strh (56 bytes)
            bw.Write(Encoding.ASCII.GetBytes("strh"));
            bw.Write(56);
            bw.Write(Encoding.ASCII.GetBytes("vids"));
            bw.Write(Encoding.ASCII.GetBytes("MJPG"));
            bw.Write(0);
            bw.Write((short)0);
            bw.Write((short)0);
            bw.Write(0);
            bw.Write(1);
            bw.Write(fps);
            bw.Write(0);
            bw.Write(totalFrames);
            bw.Write(maxFrameBytes);
            bw.Write(-1);
            bw.Write(0);
            bw.Write((short)0);
            bw.Write((short)0);
            bw.Write((short)width);
            bw.Write((short)height);

            // strf (BITMAPINFOHEADER = 40 bytes)
            bw.Write(Encoding.ASCII.GetBytes("strf"));
            bw.Write(40);
            bw.Write(40);
            bw.Write(width);
            bw.Write(height);
            bw.Write((short)1);
            bw.Write((short)24);
            bw.Write(Encoding.ASCII.GetBytes("MJPG"));
            bw.Write(width * height * 3);
            bw.Write(0); bw.Write(0); bw.Write(0); bw.Write(0);

            // LIST movi
            bw.Write(Encoding.ASCII.GetBytes("LIST"));
            bw.Write((int)moviDataBytes);
            bw.Write(Encoding.ASCII.GetBytes("movi"));

            int[] chunkOffsets = new int[totalFrames];
            int curOffset = 4; // offset from 'movi'
            for (int i = 0; i < totalFrames; i++)
            {
                chunkOffsets[i] = curOffset;
                byte[] jf = jpegFrames[i];
                bw.Write(Encoding.ASCII.GetBytes("00dc"));
                bw.Write(jf.Length);
                bw.Write(jf);
                curOffset += 8 + jf.Length;
            }

            // idx1
            bw.Write(Encoding.ASCII.GetBytes("idx1"));
            bw.Write((int)idx1Bytes);
            for (int i = 0; i < totalFrames; i++)
            {
                bw.Write(Encoding.ASCII.GetBytes("00dc"));
                bw.Write(0x10); // AVIIF_KEYFRAME
                bw.Write(chunkOffsets[i]);
                bw.Write(jpegFrames[i].Length);
            }
        }
        return new FileInfo(aviOutPath).Length;
    }
}

public class O7777VPlayerForm : Form
{
    private List<O7777VFramePacket> frames;
    private string wavFilePath;
    private int currentFrame = 0;
    private bool isPlaying = true;
    private PictureBox videoBox;
    private TrackBar scrubber;
    private Label lblTelemetry;
    private Button btnPlayPause;
    private System.Windows.Forms.Timer playTimer;
    private SoundPlayer soundPlayer;

    public O7777VPlayerForm(string o7777vPath, string wavPath)
    {
        this.Text = "ACT-Omega v61.13 // Sovereign .o7777v 7777D Orthoplex Desktop Video Player";
        this.Size = new Size(560, 560);
        this.BackColor = Color.FromArgb(6, 10, 20);
        this.ForeColor = Color.White;
        this.StartPosition = FormStartPosition.CenterScreen;

        this.wavFilePath = wavPath;
        this.frames = O7777VDecoderAndAviMuxer.LoadO7777VFile(o7777vPath);

        lblTelemetry = new Label();
        lblTelemetry.Dock = DockStyle.Top;
        lblTelemetry.Height = 36;
        lblTelemetry.Font = new Font("Consolas", 9.0f, FontStyle.Bold);
        lblTelemetry.ForeColor = Color.Cyan;
        lblTelemetry.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblTelemetry);

        Panel bottomPanel = new Panel();
        bottomPanel.Dock = DockStyle.Bottom;
        bottomPanel.Height = 76;
        bottomPanel.BackColor = Color.FromArgb(12, 20, 38);
        this.Controls.Add(bottomPanel);

        scrubber = new TrackBar();
        scrubber.Minimum = 0;
        scrubber.Maximum = Math.Max(0, frames.Count - 1);
        scrubber.Dock = DockStyle.Top;
        scrubber.Height = 32;
        scrubber.Scroll += delegate {
            currentFrame = scrubber.Value;
            RenderCurrentFrame();
        };
        bottomPanel.Controls.Add(scrubber);

        FlowLayoutPanel btnFlow = new FlowLayoutPanel();
        btnFlow.Dock = DockStyle.Bottom;
        btnFlow.Height = 38;
        btnFlow.Padding = new Padding(8, 2, 8, 2);

        btnPlayPause = new Button();
        btnPlayPause.Text = "PAUSE";
        btnPlayPause.Width = 90;
        btnPlayPause.BackColor = Color.FromArgb(20, 80, 110);
        btnPlayPause.ForeColor = Color.White;
        btnPlayPause.FlatStyle = FlatStyle.Flat;
        btnPlayPause.Click += delegate {
            isPlaying = !isPlaying;
            btnPlayPause.Text = isPlaying ? "PAUSE" : "PLAY";
        };
        btnFlow.Controls.Add(btnPlayPause);

        Button btnAudio = new Button();
        btnAudio.Text = "PLAY .WAV CHORD";
        btnAudio.Width = 140;
        btnAudio.BackColor = Color.FromArgb(80, 50, 10);
        btnAudio.ForeColor = Color.Gold;
        btnAudio.FlatStyle = FlatStyle.Flat;
        btnAudio.Click += delegate { PlaySyncedWav(); };
        btnFlow.Controls.Add(btnAudio);

        Button btnOpen = new Button();
        btnOpen.Text = "OPEN .O7777V";
        btnOpen.Width = 120;
        btnOpen.BackColor = Color.FromArgb(30, 50, 80);
        btnOpen.ForeColor = Color.Cyan;
        btnOpen.FlatStyle = FlatStyle.Flat;
        btnOpen.Click += delegate {
            OpenFileDialog ofd = new OpenFileDialog();
            ofd.Filter = "7777D Orthoplex Video (*.o7777v)|*.o7777v|All Files (*.*)|*.*";
            if (ofd.ShowDialog() == DialogResult.OK)
            {
                frames = O7777VDecoderAndAviMuxer.LoadO7777VFile(ofd.FileName);
                scrubber.Maximum = Math.Max(0, frames.Count - 1);
                currentFrame = 0;
                RenderCurrentFrame();
            }
        };
        btnFlow.Controls.Add(btnOpen);

        bottomPanel.Controls.Add(btnFlow);

        videoBox = new PictureBox();
        videoBox.Dock = DockStyle.Fill;
        videoBox.SizeMode = PictureBoxSizeMode.Zoom;
        this.Controls.Add(videoBox);
        videoBox.BringToFront();

        playTimer = new System.Windows.Forms.Timer();
        playTimer.Interval = 33; // 30 FPS
        playTimer.Tick += delegate {
            if (isPlaying && frames.Count > 0)
            {
                currentFrame = (currentFrame + 1) % frames.Count;
                scrubber.Value = currentFrame;
                RenderCurrentFrame();
            }
        };
        playTimer.Start();

        PlaySyncedWav();
        RenderCurrentFrame();
    }

    private void PlaySyncedWav()
    {
        try
        {
            if (!string.IsNullOrEmpty(wavFilePath) && File.Exists(wavFilePath))
            {
                if (soundPlayer == null) soundPlayer = new SoundPlayer(wavFilePath);
                soundPlayer.Play();
            }
        }
        catch { }
    }

    private void RenderCurrentFrame()
    {
        if (frames == null || frames.Count == 0) return;
        O7777VFramePacket pkt = frames[currentFrame];
        Bitmap bmp = O7777VDecoderAndAviMuxer.RenderFrameBitmap(pkt, frames.Count);
        Image old = videoBox.Image;
        videoBox.Image = bmp;
        if (old != null) old.Dispose();
        lblTelemetry.Text = string.Format("Frame {0:D2}/{1:D2} | Orthoplex Pole v={2}/15553 | CRT=({3},{4},{5}) | AudioAmp={6:F4}",
            pkt.FrameIndex, frames.Count - 1, pkt.DominantPole, pkt.R1, pkt.R2, pkt.R3, pkt.AudioAmp);
    }

    [STAThread]
    public static void Main(string[] args)
    {
        string oPath = (args.Length > 0) ? args[0] : @"E:\ACT_OMEGA_7777D_AV_ENGINE\renders_video\sovereign_7777d_av_sync_60f.o7777v";
        string wPath = (args.Length > 1) ? args[1] : @"E:\ACT_OMEGA_7777D_AV_ENGINE\renders_audio\sovereign_7777d_cymatic_chord_48khz.wav";
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new O7777VPlayerForm(oPath, wPath));
    }
}
'@

[System.IO.File]::WriteAllText($PlayerCsPath, $CsPlayerAndAviSource)
Add-Type -TypeDefinition $CsPlayerAndAviSource -Language CSharp -ReferencedAssemblies @("System.Drawing.dll", "System.Windows.Forms.dll") -IgnoreWarnings

# 1. Decode .o7777v and export a standard, zero-dependency Playable Motion-JPEG .AVI file on E:\
$LoadedFrames = [O7777VDecoderAndAviMuxer]::LoadO7777VFile($O7777vFile)
Write-Host "[DECODE] Loaded $($LoadedFrames.Count) frames from $O7777vFile" -ForegroundColor Green

$SwAvi = [System.Diagnostics.Stopwatch]::StartNew()
$AviBytes = [O7777VDecoderAndAviMuxer]::ExportMjpegAvi($LoadedFrames, $AviOutFile, 30)
$SwAvi.Stop()
Write-Host "[AVI EXPORT PASS] Wrote standard playable Motion-JPEG .AVI -> $AviOutFile ($AviBytes bytes in $([math]::Round($SwAvi.Elapsed.TotalMilliseconds, 2)) ms)" -ForegroundColor Green

# 2. If ffmpeg is available on PATH, also mux the .AVI + .WAV into an H.264/AAC .MP4
$FfmpegCmd = Get-Command "ffmpeg.exe" -ErrorAction SilentlyContinue
if ($FfmpegCmd -and (Test-Path $WavFile)) {
    & $FfmpegCmd.Source -y -i $AviOutFile -i $WavFile -c:v libx264 -pix_fmt yuv420p -crf 18 -c:a aac -b:a 192k -shortest $Mp4OutFile 2>&1 | Out-Null
    if (Test-Path $Mp4OutFile) {
        Write-Host "[MP4 EXPORT PASS] Muxed H.264 + 48kHz AAC .MP4 -> $Mp4OutFile ($((Get-Item $Mp4OutFile).Length) bytes)" -ForegroundColor Green
    }
}

# 3. Compile standalone O7777VPlayer.exe on E:\ and launch it automatically!
$CscCandidates = @(
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)
$CscExe = $CscCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($CscExe) {
    & $CscExe /nologo /target:winexe /out:$PlayerExePath /r:System.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll $PlayerCsPath 2>&1 | Out-Null
    if (Test-Path $PlayerExePath) {
        Write-Host "[PLAYER EXE PASS] Compiled standalone desktop player -> $PlayerExePath ($((Get-Item $PlayerExePath).Length) bytes)" -ForegroundColor Cyan
        Start-Process -FilePath $PlayerExePath -ArgumentList @($O7777vFile, $WavFile)
        Write-Host "[LIVE] Launched O7777VPlayer.exe playing your .o7777v video + 48kHz .wav audio!" -ForegroundColor Yellow
    }
}
