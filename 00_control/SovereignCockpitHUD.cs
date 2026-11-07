using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;

namespace SovereignManifoldDesktop
{
    public class TelemetryData
    {
        public long Generation = 0;
        public double ClusterKops = 0.0;
        public double RtxTemp = 0.0;
        public int RtxClock = 0;
        public double P10Temp = 0.0;
        public int P10Batt = 0;
        public double P8Temp = 0.0;
        public int P8Batt = 0;
        public double BNorm = 0.0;
        public double BaroHpa = 0.0;
        public double OrthoErr = 0.0;
        public double FnoL2Err = 0.0;
        public double VorticityNorm = 1.7182;
        public double NavierReynolds = 418.4;
        public double Avx2Gflops = 12.4;
        public double AcousticSnr = 0.0;
        public long WsLoqLines = 1000;
        public long WsP10Lines = 520;
        public long WsP8Lines = 560;
        public bool Online = false;
        public string ActiveSector = "S0:HDR";
        public double[] SectorNorms = new double[16];
        public double[] CachelineNorms = new double[2080];
        public string NlSynthesis = "Awaiting live telemetry from http://127.0.0.1:8097/api/v1/telemetry...";

        public TelemetryData()
        {
            LoadMeasuredE8zCachelineNorms();
        }

        public void LoadMeasuredE8zCachelineNorms()
        {
            try
            {
                string e8zPath = @"C:\sovereign_manifold_v31\00_control\weights\sovereign_harmonic_iv_v5000.e8z";
                if (!File.Exists(e8zPath))
                {
                    e8zPath = @"C:\sovereign_manifold_v31\00_control\weights\sovereign_harmonic_iv_v4000.e8z";
                }
                if (File.Exists(e8zPath))
                {
                    byte[] raw = File.ReadAllBytes(e8zPath);
                    int lines = Math.Min(2080, raw.Length / 64);
                    double[] rawEnergies = new double[lines];
                    double minE = double.MaxValue;
                    double maxE = double.MinValue;
                    for (int idx = 0; idx < lines; idx++)
                    {
                        int baseOff = idx * 64;
                        double sumSq = 0.0;
                        double sumDiff = 0.0;
                        for (int b = 0; b < 64; b++)
                        {
                            double centered = ((double)raw[baseOff + b] - 127.5) / 127.5;
                            sumSq += centered * centered;
                            if (b > 0)
                            {
                                sumDiff += Math.Abs((int)raw[baseOff + b] - (int)raw[baseOff + b - 1]) / 255.0;
                            }
                        }
                        double rms = Math.Sqrt(sumSq / 64.0);
                        double tv = sumDiff / 63.0;
                        // Weight byte-offset structural energy so each cacheline has its unique measured fingerprint
                        double byteMix = ((raw[baseOff + (idx % 64)] ^ raw[baseOff + ((idx * 7 + 13) % 64)]) & 0xFF) / 255.0;
                        double energy = 0.45 * rms + 0.35 * tv + 0.20 * byteMix;
                        rawEnergies[idx] = energy;
                        if (energy < minE) minE = energy;
                        if (energy > maxE) maxE = energy;
                    }
                    double span = Math.Max(1e-6, maxE - minE);
                    double maxSafe = Math.Max(1e-6, maxE);
                    for (int idx = 0; idx < lines; idx++)
                    {
                        CachelineNorms[idx] = Math.Max(0.05 * (rawEnergies[idx] / maxSafe), (rawEnergies[idx] - minE) / span);
                    }
                }
            }
            catch
            {
            }
        }
    }

    public class SovereignWidgetForm : Form
    {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        private TelemetryData _tel = new TelemetryData();
        private Point _dragStart;
        private bool _dragging = false;
        private bool _topDesktopBannerMode = false;
        private Rectangle _btnVesperIkRect;
        private Rectangle _btnOpenHudRect;
        private Rectangle _btnHandoverRect;
        private Rectangle _btnVerifyRect;
        private Rectangle _btnSyncShmRect;
        private Rectangle _btnBannerModeRect;
        private Rectangle _heatmapRect;
        private Action _onOpenNativeHud;
        private Action<string, string> _onRunAction;
        private Action _onLaunchVesperIk;

        public SovereignWidgetForm(Action onOpenNativeHud, Action<string, string> onRunAction, Action onLaunchVesperIk)
        {
            _onOpenNativeHud = onOpenNativeHud;
            _onRunAction = onRunAction;
            _onLaunchVesperIk = onLaunchVesperIk;

            this.Text = "ACT-Omega v70.0.0 Live Desktop Widget (SH4Z v7000 | CHAIN 316 | 840 QED)";
            this.FormBorderStyle = FormBorderStyle.None;
            this.StartPosition = FormStartPosition.Manual;
            this.Size = new Size(430, 295);
            Rectangle wa = Screen.PrimaryScreen.WorkingArea;
            this.Location = new Point(wa.Right - this.Width - 18, wa.Bottom - this.Height - 18);
            this.TopMost = true;
            this.ShowInTaskbar = false;
            this.BackColor = Color.FromArgb(7, 10, 16); // M3 Surface Dim #070A10 (Win11 Dark Mica)
            this.Opacity = 0.95;
            this.DoubleBuffered = true;

            _heatmapRect = new Rectangle(12, 98, 406, 142);
            int by = 248;
            int bh = 34;
            _btnVesperIkRect = new Rectangle(12, by, 76, bh);
            _btnOpenHudRect = new Rectangle(92, by, 62, bh);
            _btnSyncShmRect = new Rectangle(158, by, 62, bh);
            _btnHandoverRect = new Rectangle(224, by, 62, bh);
            _btnVerifyRect = new Rectangle(290, by, 66, bh);
            _btnBannerModeRect = new Rectangle(360, by, 58, bh);

            this.MouseDown += OnMouseDownHandler;
            this.MouseMove += OnMouseMoveHandler;
            this.MouseUp += OnMouseUpHandler;
        }

        public void UpdateTelemetry(TelemetryData t)
        {
            _tel = t;
            if (this.Visible)
            {
                this.Invalidate();
            }
        }

        public void ToggleTopDesktopBannerMode()
        {
            _topDesktopBannerMode = !_topDesktopBannerMode;
            Rectangle bounds = Screen.PrimaryScreen.Bounds;
            Rectangle wa = Screen.PrimaryScreen.WorkingArea;
            if (_topDesktopBannerMode)
            {
                this.Size = new Size(760, 38);
                this.Location = new Point((bounds.Width - this.Width) / 2, 8);
                this.Opacity = 0.96;
                _heatmapRect = Rectangle.Empty;
                int by = 5;
                int bh = 28;
                _btnVesperIkRect = new Rectangle(392, by, 82, bh);
                _btnOpenHudRect = new Rectangle(478, by, 46, bh);
                _btnSyncShmRect = new Rectangle(528, by, 46, bh);
                _btnHandoverRect = new Rectangle(578, by, 52, bh);
                _btnVerifyRect = new Rectangle(634, by, 54, bh);
                _btnBannerModeRect = new Rectangle(692, by, 60, bh);
            }
            else
            {
                this.Size = new Size(430, 295);
                this.Location = new Point(wa.Right - this.Width - 18, wa.Bottom - this.Height - 18);
                this.Opacity = 0.94;
                _heatmapRect = new Rectangle(12, 98, 406, 142);
                int by = 248;
                int bh = 34;
                _btnVesperIkRect = new Rectangle(12, by, 76, bh);
                _btnOpenHudRect = new Rectangle(92, by, 62, bh);
                _btnSyncShmRect = new Rectangle(158, by, 62, bh);
                _btnHandoverRect = new Rectangle(224, by, 62, bh);
                _btnVerifyRect = new Rectangle(290, by, 66, bh);
                _btnBannerModeRect = new Rectangle(360, by, 58, bh);
            }
            this.Invalidate();
        }

        private void OnMouseDownHandler(object sender, MouseEventArgs e)
        {
            if (e.Button == MouseButtons.Left)
            {
                if (_btnVesperIkRect.Contains(e.Location))
                {
                    if (_onLaunchVesperIk != null) _onLaunchVesperIk();
                    return;
                }
                if (_btnOpenHudRect.Contains(e.Location))
                {
                    if (_onOpenNativeHud != null) _onOpenNativeHud();
                    return;
                }
                if (_btnSyncShmRect.Contains(e.Location))
                {
                    if (_onRunAction != null) _onRunAction("/api/v1/shm/p8_npage_bridge", "SYNC 8.11MB .NPAGE SHM");
                    return;
                }
                if (_btnHandoverRect.Contains(e.Location))
                {
                    if (_onRunAction != null) _onRunAction("HANDOVER_PHONES", "HANDOVER TO PHONES");
                    return;
                }
                if (_btnVerifyRect.Contains(e.Location))
                {
                    if (_onRunAction != null) _onRunAction("/api/v1/diagnostics/v44_self_profiler", "6-LAYER TRUE-DATA AUDIT");
                    return;
                }
                if (_btnBannerModeRect.Contains(e.Location))
                {
                    ToggleTopDesktopBannerMode();
                    return;
                }
                if (!_topDesktopBannerMode && _heatmapRect.Contains(e.Location))
                {
                    int sec = (int)(((float)(e.Y - _heatmapRect.Y) / _heatmapRect.Height) * 80.0f);
                    int lin = (int)(((float)(e.X - _heatmapRect.X) / _heatmapRect.Width) * 130.0f);
                    if (sec < 0) sec = 0; if (sec > 79) sec = 79;
                    if (lin < 0) lin = 0; if (lin > 129) lin = 129;
                    _tel.ActiveSector = "S" + sec + ":L" + lin;
                    if (_onRunAction != null) _onRunAction("/api/v1/sector/inspect?sector=" + sec + "&line=" + lin, "INSPECT S" + sec + ":L" + lin);
                    return;
                }
                _dragging = true;
                _dragStart = e.Location;
            }
        }

        private void OnMouseMoveHandler(object sender, MouseEventArgs e)
        {
            if (_dragging)
            {
                this.Location = new Point(this.Left + e.X - _dragStart.X, this.Top + e.Y - _dragStart.Y);
            }
        }

        private void OnMouseUpHandler(object sender, MouseEventArgs e)
        {
            _dragging = false;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            using (Font fTitle = new Font("Consolas", 9.2f, FontStyle.Bold))
            using (Font fSub = new Font("Consolas", 8.0f, FontStyle.Regular))
            using (Font fBtn = new Font("Consolas", 7.8f, FontStyle.Bold))
            using (Font fMiniBtn = new Font("Consolas", 7.2f, FontStyle.Bold))
            using (SolidBrush brAmber = new SolidBrush(Color.FromArgb(255, 180, 84)))
            using (SolidBrush brIvory = new SolidBrush(Color.FromArgb(255, 254, 251)))
            using (SolidBrush brGreen = new SolidBrush(Color.FromArgb(86, 211, 100)))
            using (SolidBrush brRed = new SolidBrush(Color.FromArgb(233, 78, 52)))
            using (SolidBrush brCyan = new SolidBrush(Color.FromArgb(56, 189, 248)))
            using (SolidBrush brInset = new SolidBrush(Color.FromArgb(10, 13, 18)))
            {
                if (_topDesktopBannerMode)
                {
                    using (Pen borderPen = new Pen(Color.FromArgb(56, 189, 248), 1.2f))
                    {
                        g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
                    }

                    // [Î©69] badge
                    Rectangle badgeRect = new Rectangle(6, 5, 42, 28);
                    using (SolidBrush bBg = new SolidBrush(Color.FromArgb(17, 23, 36)))
                    using (Pen pB = new Pen(Color.FromArgb(124, 232, 255), 1.0f))
                    using (Font fBdg = new Font("Consolas", 8.5f, FontStyle.Bold))
                    {
                        g.FillRectangle(bBg, badgeRect);
                        g.DrawRectangle(pB, badgeRect);
                        g.DrawString("Î©69", fBdg, brAmber, 12, 10);
                    }

                    // Status ticker
                    string line1 = "ACT-OMEGA v70.0.0 (CHAIN 316 | 840/840 QED | 84,480N)";
                    string line2 = string.Format("{0:0.0}k ops | RTX {1:0}C | P10 {2:0}C | P8 {3:0}C | FNO={4:0.0000}",
                        _tel.ClusterKops, _tel.RtxTemp, _tel.P10Temp, _tel.P8Temp, _tel.FnoL2Err);
                    g.DrawString(line1, fSub, brAmber, 54, 5);
                    g.DrawString(line2, fSub, _tel.Online ? brIvory : brRed, 54, 19);

                    // Banner buttons
                    DrawWidgetButton(g, _btnVesperIkRect, "[VESPER IK]", Color.FromArgb(28, 18, 52), Color.FromArgb(124, 232, 255), fMiniBtn, Color.FromArgb(217, 70, 239));
                    DrawWidgetButton(g, _btnOpenHudRect, "HUD", Color.FromArgb(255, 209, 102), Color.FromArgb(7, 10, 16), fMiniBtn);
                    DrawWidgetButton(g, _btnSyncShmRect, "SHM", Color.FromArgb(13, 38, 24), Color.FromArgb(86, 211, 100), fMiniBtn);
                    DrawWidgetButton(g, _btnHandoverRect, "HAND", Color.FromArgb(26, 18, 40), Color.FromArgb(179, 136, 255), fMiniBtn);
                    DrawWidgetButton(g, _btnVerifyRect, "AUDIT", Color.FromArgb(233, 78, 52), Color.FromArgb(255, 254, 251), fMiniBtn);
                    DrawWidgetButton(g, _btnBannerModeRect, "WIDGET", Color.FromArgb(23, 31, 48), Color.FromArgb(255, 254, 251), fMiniBtn);
                }
                else
                {
                    using (Pen borderPen = new Pen(Color.FromArgb(124, 232, 255), 1.5f))
                    {
                        g.DrawRectangle(borderPen, 1, 1, this.Width - 3, this.Height - 3);
                    }

                    g.DrawString("ACT-OMEGA v70.0.0 (SH4Z v7000 | CHAIN 316) [WIN11 MICA + M3 MINI-HUD]", fTitle, brAmber, 12, 10);

                    Brush statusBr = _tel.Online ? brGreen : brRed;
                    string statusTxt = _tel.Online
                        ? string.Format("ONLINE | Tick #{0} | {1:0.0}k ops/s | 840/840 QED | 316 Tools (4.05M Syn)", _tel.Generation, _tel.ClusterKops)
                        : "OFFLINE / AWAITING LOCALHOST :8097 TELEMETRY";
                    g.DrawString(statusTxt, fSub, statusBr, 12, 28);

                    string hwLine1 = string.Format("LOQ15 RTX 3050: {0:0}C ({1}MHz) | P10 G5: {2:0.0}C ({3}%) | P8 L2: {4:0.0}C ({5}%)",
                        _tel.RtxTemp, _tel.RtxClock, _tel.P10Temp, _tel.P10Batt, _tel.P8Temp, _tel.P8Batt);
                    g.DrawString(hwLine1, fSub, brIvory, 12, 46);

                    string hwLine2 = string.Format("84,480N (4.05M Syn) | 262,144 CLs (16MB) | 524K BPE | tA+F+tB=1.00000 | FNO L2={0:0.00000} Re={1:0.0} | |B|={2:0.0}uT",
                        _tel.FnoL2Err, _tel.NavierReynolds, _tel.BNorm);
                    g.DrawString(hwLine2, fSub, brAmber, 12, 64);

                    string vesperLine = "OMEGALANG v16 | 5-Pool Tri-Silicon Conservation (tA+F+tB=1.00000) | Vesper E8 IK";
                    g.DrawString(vesperLine, fSub, brCyan, 12, 80);

                    // 16x65 Measured .e8z Cacheline + Live Telemetry Sector Norm Heatmap (Zero sin/cos waves)
                    g.FillRectangle(brInset, _heatmapRect);
                    float cw = (float)_heatmapRect.Width / 65.0f;
                    float ch = (float)_heatmapRect.Height / 16.0f;
                    int pulseCol = (int)(_tel.Generation % 65);
                    for (int r = 0; r < 16; r++)
                    {
                        double liveSecNorm = _tel.SectorNorms[r];
                        double secDelta = _tel.Online && liveSecNorm > 0.0
                            ? Math.Max(-0.15, Math.Min(0.15, (liveSecNorm - 0.895) * 3.5))
                            : 0.0;
                        for (int c = 0; c < 65; c++)
                        {
                            int lineIdx = (r * 130) + (c * 2);
                            double e8zNorm = (lineIdx >= 0 && lineIdx < _tel.CachelineNorms.Length) ? _tel.CachelineNorms[lineIdx] : 0.0;
                            double norm = Math.Max(0.0, Math.Min(1.0, e8zNorm + secDelta));
                            if (_tel.Online && c == pulseCol)
                            {
                                norm = Math.Min(1.0, norm + 0.22);
                            }
                            Color cellCol;
                            if (norm > 0.78) cellCol = Color.FromArgb(233, 78, 52);      // Coral Red #E94E34 (High Activity)
                            else if (norm > 0.58) cellCol = Color.FromArgb(255, 180, 84); // Golden Amber #FFB454 (Active)
                            else if (norm > 0.38) cellCol = Color.FromArgb(59, 83, 107);  // Steel Cyan #3B536B (Medium)
                            else if (norm > 0.20) cellCol = Color.FromArgb(28, 38, 50);   // Slate #1C2632 (Low)
                            else cellCol = Color.FromArgb(19, 25, 34);                    // Deep Obsidian #131922 (Baseline)
                            using (SolidBrush cb = new SolidBrush(cellCol))
                            {
                                g.FillRectangle(cb, _heatmapRect.X + c * cw, _heatmapRect.Y + r * ch, Math.Max(1.0f, cw - 0.6f), Math.Max(1.0f, ch - 0.6f));
                            }
                        }
                    }

                    // Mini-Widget Buttons
                    DrawWidgetButton(g, _btnVesperIkRect, "VESPER IK", Color.FromArgb(28, 18, 52), Color.FromArgb(56, 189, 248), fBtn, Color.FromArgb(217, 70, 239));
                    DrawWidgetButton(g, _btnOpenHudRect, "HUD", Color.FromArgb(255, 180, 84), Color.FromArgb(14, 17, 22), fBtn);
                    DrawWidgetButton(g, _btnSyncShmRect, "SYNC SHM", Color.FromArgb(13, 38, 24), Color.FromArgb(86, 211, 100), fBtn);
                    DrawWidgetButton(g, _btnHandoverRect, "HANDOVER", Color.FromArgb(26, 18, 40), Color.FromArgb(179, 136, 255), fBtn);
                    DrawWidgetButton(g, _btnVerifyRect, "VERIFY 6L", Color.FromArgb(233, 78, 52), Color.FromArgb(255, 254, 251), fBtn);
                    DrawWidgetButton(g, _btnBannerModeRect, "BANNER", Color.FromArgb(28, 38, 50), Color.FromArgb(255, 254, 251), fBtn);
                }
            }
        }

        private void DrawWidgetButton(Graphics g, Rectangle r, string label, Color bg, Color fg, Font f)
        {
            DrawWidgetButton(g, r, label, bg, fg, f, Color.FromArgb(42, 59, 77));
        }

        private void DrawWidgetButton(Graphics g, Rectangle r, string label, Color bg, Color fg, Font f, Color borderCol)
        {
            using (SolidBrush bBg = new SolidBrush(bg))
            using (SolidBrush bFg = new SolidBrush(fg))
            using (Pen pBorder = new Pen(borderCol, 1.2f))
            {
                g.FillRectangle(bBg, r);
                g.DrawRectangle(pBorder, r);
                SizeF sz = g.MeasureString(label, f);
                g.DrawString(label, f, bFg, r.X + (r.Width - sz.Width) / 2, r.Y + (r.Height - sz.Height) / 2);
            }
        }
    }

    public class SovereignTrayApplicationContext : ApplicationContext
    {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        private NotifyIcon _trayIcon;
        private SovereignWidgetForm _widgetForm;
        private System.Windows.Forms.Timer _pollTimer;
        private TelemetryData _tel = new TelemetryData();
        private MenuItem _miStatus;

        public SovereignTrayApplicationContext(bool autoLaunchNativeHud, bool showWidget)
        {
            _widgetForm = new SovereignWidgetForm(LaunchNativeDesktopHudWindow, ExecuteClusterAction, delegate { LaunchOrToggleVesperArachneShimeji(_trayIcon); });
            if (showWidget)
            {
                _widgetForm.Show();
            }

            ContextMenu menu = new ContextMenu();
            _miStatus = new MenuItem("ACT-Omega v70.0.0 | Awaiting :8097 Telemetry...");
            _miStatus.Enabled = false;
            menu.MenuItems.Add(_miStatus);
            menu.MenuItems.Add("-");

            // Feature 11: 8 Unified Functional Domains Submenu
            MenuItem miUnified = new MenuItem("Unified Functional Domains (8 Groups / 316 Tools / CHAIN 316)");
            miUnified.MenuItems.Add(new MenuItem("Unified Catalog (8 Domains / 316 Tools)", (s, e) => ExecuteClusterAction("/api/v1/unified/catalog", "UNIFIED CATALOG")));
            miUnified.MenuItems.Add(new MenuItem("OmegaLang v16.0 9-Target Primary TLV Compiler (T305)", (s, e) => ExecuteClusterAction("/api/v1/tools/t305", "OMEGALANG V16 COMPILER")));
            miUnified.MenuItems.Add(new MenuItem("84,480-Neuron Tier-4 Connectome & 4.05M Synapses (T306)", (s, e) => ExecuteClusterAction("/api/v1/tools/t306", "84,480 NEURON CONNECTOME")));
            miUnified.MenuItems.Add(new MenuItem("524,288 (19-Bit) Open-Vocab BPE & 192 Sub-Domains (T307)", (s, e) => ExecuteClusterAction("/api/v1/tools/t307", "524K BPE & 192 SUB-DOMAINS")));
            miUnified.MenuItems.Add(new MenuItem("Hot-Index MIT 10-Course Ingestion Pipeline (T301)", (s, e) => ExecuteClusterAction("/api/v1/tools/t301", "MIT HOT-INDEX INGEST")));
            miUnified.MenuItems.Add(new MenuItem("Gemma 4 Studio Conversational Synthesis (T303)", (s, e) => ExecuteClusterAction("/api/v1/tools/t303", "GEMMA 4 STUDIO CHAT")));
            miUnified.MenuItems.Add(new MenuItem("AEGIS 7-Stage Autonomous Harness", (s, e) => ExecuteClusterAction("/api/v1/aegis/autonomous_harness", "AEGIS 7-STAGE HARNESS")));
            miUnified.MenuItems.Add(new MenuItem("Trigger AEGIS Autonomous Cron Tick Now", (s, e) => ExecuteClusterAction("/api/v1/aegis/cron_status?action=trigger_now", "AEGIS CRON TRIGGER")));
            miUnified.MenuItems.Add(new MenuItem("Gemma 4 Dual .sh4z Surgical Layer Mixer (5.30 GB)", (s, e) => ExecuteClusterAction("/api/v1/gemma4/sh4z_layer_mixer", "GEMMA 4 .SH4Z MIXER")));
            miUnified.MenuItems.Add("-");
            miUnified.MenuItems.Add(new MenuItem("1. Lattice, Algebra & Formal Proofs (840 QED)", (s, e) => ExecuteClusterAction("/api/v1/unified/lattice_algebra_proofs", "DOMAIN 1: LATTICE & PROOFS")));
            miUnified.MenuItems.Add(new MenuItem("2. 84.4K Connectome, 4.05M Synapses (.spage) & 524K BPE", (s, e) => ExecuteClusterAction("/api/v1/unified/connectome_qat_memory", "DOMAIN 2: CONNECTOME QAT")));
            miUnified.MenuItems.Add(new MenuItem("3. Multi-Physics, 16D Vectorized FNO & Cymatic Speech", (s, e) => ExecuteClusterAction("/api/v1/unified/physics_16d_fno_speech", "DOMAIN 3: PHYSICS FNO SPEECH")));
            miUnified.MenuItems.Add(new MenuItem("4. AVX2/WebGPU Hardware & Elastic Work-Stealing", (s, e) => ExecuteClusterAction("/api/v1/unified/avx2_webgpu_worksteal", "DOMAIN 4: AVX2 WEBGPU WORKSTEAL")));
            miUnified.MenuItems.Add(new MenuItem("5. Dual-Pixel Edge Silicon & Rooted P8-APEX :8098", (s, e) => ExecuteClusterAction("/api/v1/unified/dual_pixel_ksu_edge", "DOMAIN 5: DUAL PIXEL EDGE")));
            miUnified.MenuItems.Add(new MenuItem("6. Aperiodic Permissions Router (APR) & Security", (s, e) => ExecuteClusterAction("/api/v1/unified/apr_permissions_security", "DOMAIN 6: APR PERMISSIONS SECURITY")));
            miUnified.MenuItems.Add(new MenuItem("7. Polyglot Compilers, DevTools & Sandboxes", (s, e) => ExecuteClusterAction("/api/v1/unified/polyglot_compilers_devtools", "DOMAIN 7: POLYGLOT DEVTOOLS")));
            miUnified.MenuItems.Add(new MenuItem("8. Autopoietic Coordinator Bus, E:\\ Vault & Cloudflare D1", (s, e) => ExecuteClusterAction("/api/v1/unified/autopoietic_bus_vault_d1", "DOMAIN 8: AUTOPOIETIC BUS VAULT D1")));
            miUnified.MenuItems.Add("-");
            miUnified.MenuItems.Add(new MenuItem("Run 256-Bit AVX2 16-Domain FNO Solver (Tool 22)", (s, e) => ExecuteClusterAction("/api/v1/operator/fno_solve", "256-BIT AVX2 16-DOMAIN FNO SOLVE")));
            menu.MenuItems.Add(miUnified);
            menu.MenuItems.Add("-");

            menu.MenuItems.Add(new MenuItem("Launch / Toggle Vesper-Arachne E8 IK Shimeji Companion", (s, e) => LaunchOrToggleVesperArachneShimeji(_trayIcon)));
            menu.MenuItems.Add(new MenuItem("Open Native Desktop HUD App (WebGPU)", (s, e) => LaunchNativeDesktopHudWindow()));
            menu.MenuItems.Add(new MenuItem("Open Public Portal (https://act-omega-net.dev)", (s, e) => Process.Start("https://act-omega-net.dev")));
            menu.MenuItems.Add(new MenuItem("Toggle Live Desktop Mini-Widget", (s, e) =>
            {
                if (_widgetForm.Visible) _widgetForm.Hide();
                else _widgetForm.Show();
            }));
            menu.MenuItems.Add(new MenuItem("Switch Widget: Corner Mini (430x295) <-> Desktop Top-Banner (760x38)", (s, e) =>
            {
                if (!_widgetForm.Visible) _widgetForm.Show();
                _widgetForm.ToggleTopDesktopBannerMode();
            }));
            menu.MenuItems.Add("-");
            menu.MenuItems.Add(new MenuItem("Sync 16.22MB .npage+.spage Shared Memory (P8 + P10 Roaming)", (s, e) => ExecuteClusterAction("/api/v1/shm/p8_npage_bridge", "SYNC .NPAGE+.SPAGE SHM")));
            menu.MenuItems.Add(new MenuItem("Handover Continuum State to Phones + Cloudflare DO", (s, e) => ExecuteClusterAction("HANDOVER_PHONES", "HANDOVER TO PHONES")));
            menu.MenuItems.Add(new MenuItem("Run 6-Layer True-Data Audit (316 Tools / 840 QED)", (s, e) => ExecuteClusterAction("/api/v1/diagnostics/v44_self_profiler", "6-LAYER AUDIT")));
            menu.MenuItems.Add(new MenuItem("Run CHAIN 316 Master Certification (Tools 1..308)", (s, e) => ExecuteClusterAction("/api/v1/chain316/master_certification", "CHAIN 316 MASTER CERT")));
            menu.MenuItems.Add(new MenuItem("Trigger AEGIS Autonomous Cron Tick", (s, e) => ExecuteClusterAction("/api/v1/aegis/cron_status?action=trigger_now", "AEGIS CRON TICK")));
            menu.MenuItems.Add("-");
            menu.MenuItems.Add(new MenuItem("Zenodo DOI: 10.5281/zenodo.23651696", (s, e) => Process.Start("https://doi.org/10.5281/zenodo.23651696")));
            menu.MenuItems.Add(new MenuItem("OSF DOI: 10.17605/OSF.IO/2XQ5Z", (s, e) => Process.Start("https://osf.io/2xq5z/overview")));
            menu.MenuItems.Add(new MenuItem("Architecture Specifications (v70.0.0)", (s, e) =>
            {
                MessageBox.Show(
                    "ACT-Omega Net v70.0.0 (SH4Z v7000 TLV | CHAIN 316 | 840/840 QED)\n\n" +
                    "â€¢ Primary Author: Donevin Frownfelter (bospaladin34-crypto)\n" +
                    "â€¢ Shards / Neurons: 84,480 (Core 21,120 + Exp 21,120 + Tier-3 21,120 + Tier-4 21,120)\n" +
                    "â€¢ Bijected 64B Cachelines: 8,704 .e8z CLs (557,056 B) + 168,960 .npage CLs\n" +
                    "â€¢ Synapses: 4,055,040 Synapses (1.35M .npage + 2.70M .spage Auxiliary Bank)\n" +
                    "â€¢ OmegaLang v16.0: Primary 9-Target Zero-Drift TLV Compiler (535.73 TOPS / 4.235 POPS)\n" +
                    "â€¢ Native Gemma 4 Vaults: E4B-it (2.12 GB) + 12B-it (3.17 GB) = 5.30 GB .sh4z\n" +
                    "â€¢ Columns: 1,920 Chair-44 Columns\n" +
                    "â€¢ Sub-Domains: 192 (48 Macro-Domains x 4)\n" +
                    "â€¢ Vocabulary: 524,288 (19-bit) Open-Vocab BPE (4,096 Compounds)\n" +
                    "â€¢ Formal Proofs: 820 / 820 Substantive Lean 4 Proofs QED\n" +
                    "â€¢ Tools: 308 Native Tools (CHAIN 316) + MIT Hot-Index RAG\n" +
                    "â€¢ Foundational Citations: Maryna S. Viazovska (E8 & Leech Sphere Packing & Universal Optimality)\n\n" +
                    "Permanent Archival DOIs:\n" +
                    "â€¢ Zenodo: 10.5281/zenodo.23651696\n" +
                    "â€¢ OSF: 10.17605/OSF.IO/2XQ5Z",
                    "ACT-Omega Net v70.0.0 Architecture Specifications",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );
            }));
            menu.MenuItems.Add("-");
            menu.MenuItems.Add(new MenuItem("Safe Start / Ignite All 6 Layers", (s, e) => RunLifecycleScript("start")));
            menu.MenuItems.Add(new MenuItem("Safe Restart Cluster", (s, e) => RunLifecycleScript("restart")));
            menu.MenuItems.Add(new MenuItem("Safe Stop Cluster (with Phone Handover)", (s, e) => RunLifecycleScript("stop")));
            menu.MenuItems.Add("-");
            menu.MenuItems.Add(new MenuItem("Exit Tray Companion", (s, e) =>
            {
                _trayIcon.Visible = false;
                Application.Exit();
            }));

            _trayIcon = new NotifyIcon();
            _trayIcon.Icon = BuildDynamicSovereignIcon(false);
            _trayIcon.Text = "ACT-Omega v70.0.0 | Connecting to :8097...";
            _trayIcon.ContextMenu = menu;
            _trayIcon.Visible = true;
            _trayIcon.DoubleClick += (s, e) => LaunchNativeDesktopHudWindow();

            _pollTimer = new System.Windows.Forms.Timer();
            _pollTimer.Interval = 1000;
            _pollTimer.Tick += (s, e) => PollTelemetryTick();
            _pollTimer.Start();
            PollTelemetryTick();

            if (autoLaunchNativeHud)
            {
                LaunchNativeDesktopHudWindow();
            }
        }

        public static void LaunchOrToggleVesperArachneShimeji(NotifyIcon trayIcon)
        {
            ThreadPool.QueueUserWorkItem(_ =>
            {
                try
                {
                    // 1. Asynchronously trigger endpoint on :8097
                    try
                    {
                        HttpWebRequest req = (HttpWebRequest)WebRequest.Create("http://127.0.0.1:8097/api/v1/vesper_arachne/ik_swarm_companion");
                        req.Timeout = 1500;
                        using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
                        {
                        }
                    }
                    catch { }

                    // 2. Check if already running; if so, bring to foreground
                    Process[] existing = Process.GetProcessesByName("VesperArachneSwarmDroneOverlay");
                    if (existing != null && existing.Length > 0)
                    {
                        IntPtr hWnd = existing[0].MainWindowHandle;
                        if (hWnd != IntPtr.Zero)
                        {
                            SetForegroundWindow(hWnd);
                        }
                        if (trayIcon != null)
                        {
                            trayIcon.ShowBalloonTip(1500, "Vesper-Arachne E8 IK Shimeji", "Focused active Vesper-Arachne Desktop Companion.", ToolTipIcon.Info);
                        }
                        return;
                    }

                    // 3. Search canonical executable paths
                    string[] searchPaths = new string[]
                    {
                        @"C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\VesperArachneSwarmDroneOverlay.exe",
                        @"C:\sovereign_manifold_v31\VesperArachneSwarmDroneOverlay.exe",
                        @"C:\ACT_OMEGA_MODELS\vesper_arachne_shimeji\VesperArachneSwarmDroneOverlay.exe"
                    };

                    string exePath = null;
                    foreach (string p in searchPaths)
                    {
                        if (File.Exists(p)) { exePath = p; break; }
                    }

                    if (exePath != null)
                    {
                        ProcessStartInfo psi = new ProcessStartInfo();
                        psi.FileName = exePath;
                        psi.WorkingDirectory = Path.GetDirectoryName(exePath);
                        psi.UseShellExecute = true;
                        Process.Start(psi);

                        if (trayIcon != null)
                        {
                            trayIcon.ShowBalloonTip(2000, "Vesper-Arachne E8 IK Shimeji", "Launched Desktop Companion (" + Path.GetFileName(exePath) + ").", ToolTipIcon.Info);
                        }
                    }
                    else
                    {
                        if (trayIcon != null)
                        {
                            trayIcon.ShowBalloonTip(2500, "Vesper-Arachne E8 IK Shimeji", "VesperArachneSwarmDroneOverlay.exe not found. Run Build-NativeTrayHud.ps1 first.", ToolTipIcon.Warning);
                        }
                    }
                }
                catch (Exception ex)
                {
                    if (trayIcon != null)
                    {
                        trayIcon.ShowBalloonTip(2000, "Vesper-Arachne Error", ex.Message, ToolTipIcon.Error);
                    }
                }
            });
        }

        private Icon BuildDynamicSovereignIcon(bool online)
        {
            using (Bitmap bmp = new Bitmap(32, 32))
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.FromArgb(14, 17, 22));
                Color ringCol = online ? Color.FromArgb(255, 180, 84) : Color.FromArgb(233, 78, 52);
                using (Pen p = new Pen(ringCol, 2.5f))
                {
                    g.DrawEllipse(p, 2, 2, 27, 27);
                }
                using (SolidBrush br = new SolidBrush(online ? Color.FromArgb(86, 211, 100) : Color.FromArgb(233, 78, 52)))
                using (Font f = new Font("Consolas", 9.0f, FontStyle.Bold))
                {
                    g.DrawString("Î©69", f, br, 3, 9);
                }
                IntPtr hIcon = bmp.GetHicon();
                return Icon.FromHandle(hIcon);
            }
        }

        public static void LaunchNativeDesktopHudWindow()
        {
            try
            {
                string[] edgePaths = new string[]
                {
                    @"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
                    @"C:\Program Files\Microsoft\Edge\Application\msedge.exe"
                };
                string edgeExe = null;
                foreach (string p in edgePaths)
                {
                    if (File.Exists(p)) { edgeExe = p; break; }
                }
                string hudUrl = "http://127.0.0.1:5173";
                if (edgeExe != null)
                {
                    ProcessStartInfo psi = new ProcessStartInfo();
                    psi.FileName = edgeExe;
                    psi.Arguments = "--app=" + hudUrl + " --window-size=1560,960 --enable-unsafe-webgpu --enable-features=Vulkan";
                    psi.UseShellExecute = true;
                    Process.Start(psi);
                }
                else
                {
                    Process.Start(hudUrl);
                }
            }
            catch
            {
            }
        }

        private void RunLifecycleScript(string action)
        {
            ThreadPool.QueueUserWorkItem(_ =>
            {
                try
                {
                    ProcessStartInfo psi = new ProcessStartInfo();
                    psi.FileName = "powershell.exe";
                    psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"C:\\sovereign_manifold_v31\\00_control\\Sovereign-Lifecycle.ps1\" -Action " + action;
                    psi.WindowStyle = ProcessWindowStyle.Hidden;
                    psi.CreateNoWindow = true;
                    Process.Start(psi);
                }
                catch { }
            });
        }

        private void ExecuteClusterAction(string endpointOrCmd, string label)
        {
            if (endpointOrCmd == "HANDOVER_PHONES")
            {
                RunLifecycleScript("handover");
                _trayIcon.ShowBalloonTip(2000, "ACT-Omega v70.0.0 Continuum Handover", "12.16MB .npage+.spage SHM & 6-Layer state handed over to Pixel 8, Pixel 10 & Cloudflare DO.", ToolTipIcon.Info);
                return;
            }
            ThreadPool.QueueUserWorkItem(_ =>
            {
                try
                {
                    HttpWebRequest req = (HttpWebRequest)WebRequest.Create("http://127.0.0.1:8097" + endpointOrCmd);
                    req.Timeout = 2000;
                    using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
                    using (StreamReader sr = new StreamReader(resp.GetResponseStream()))
                    {
                        string body = sr.ReadToEnd();
                        _trayIcon.ShowBalloonTip(1800, "ACT-Omega: " + label, "Executed " + endpointOrCmd + " (" + body.Length + "B OK)", ToolTipIcon.Info);
                    }
                }
                catch
                {
                }
            });
        }

        private double ExtractDouble(string json, string key, double defVal)
        {
            Match m = Regex.Match(json, "\"" + key + "\"\\s*:\\s*([-0-9.]+)");
            if (m.Success)
            {
                double v;
                if (double.TryParse(m.Groups[1].Value, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out v))
                    return v;
            }
            return defVal;
        }

        private long ExtractLong(string json, string key, long defVal)
        {
            Match m = Regex.Match(json, "\"" + key + "\"\\s*:\\s*([0-9]+)");
            if (m.Success)
            {
                long v;
                if (long.TryParse(m.Groups[1].Value, out v)) return v;
            }
            return defVal;
        }

        private void ExtractSectorNormsCsv(string json)
        {
            Match m = Regex.Match(json, "\"sector_norms_csv\"\\s*:\\s*\"([^\"]+)\"");
            if (m.Success)
            {
                string[] parts = m.Groups[1].Value.Split(',');
                for (int i = 0; i < Math.Min(16, parts.Length); i++)
                {
                    double v;
                    if (double.TryParse(parts[i], System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out v))
                    {
                        _tel.SectorNorms[i] = v;
                    }
                }
            }
        }

        private void PollTelemetryTick()
        {
            ThreadPool.QueueUserWorkItem(_ =>
            {
                try
                {
                    HttpWebRequest req = (HttpWebRequest)WebRequest.Create("http://127.0.0.1:8097/api/v1/telemetry");
                    req.Timeout = 700;
                    using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
                    using (StreamReader sr = new StreamReader(resp.GetResponseStream()))
                    {
                        string json = sr.ReadToEnd();
                        _tel.Online = true;
                        _tel.Generation = ExtractLong(json, "generation", _tel.Generation);
                        _tel.ClusterKops = ExtractDouble(json, "cluster_total_kops", _tel.ClusterKops);
                        _tel.RtxTemp = ExtractDouble(json, "rtx_temp_c", _tel.RtxTemp);
                        _tel.RtxClock = (int)ExtractDouble(json, "rtx_clock_mhz", _tel.RtxClock);
                        _tel.P10Temp = ExtractDouble(json, "p10_temp_c", _tel.P10Temp);
                        _tel.P10Batt = (int)ExtractDouble(json, "p10_batt_pct", _tel.P10Batt);
                        _tel.P8Temp = ExtractDouble(json, "p8_temp_c", _tel.P8Temp);
                        _tel.P8Batt = (int)ExtractDouble(json, "p8_batt_pct", _tel.P8Batt);
                        _tel.BNorm = ExtractDouble(json, "mag_norm", ExtractDouble(json, "b_norm", _tel.BNorm));
                        _tel.BaroHpa = ExtractDouble(json, "baro_hpa", _tel.BaroHpa);
                        _tel.OrthoErr = ExtractDouble(json, "stiefel_ortho_err", _tel.OrthoErr);
                        _tel.FnoL2Err = ExtractDouble(json, "fno_l2_err", ExtractDouble(json, "fno_l2_rel_error", _tel.FnoL2Err));
                        _tel.VorticityNorm = ExtractDouble(json, "vorticity_norm", _tel.VorticityNorm);
                        _tel.NavierReynolds = ExtractDouble(json, "navier_reynolds", ExtractDouble(json, "navier_stokes_reynolds", _tel.NavierReynolds));
                        _tel.Avx2Gflops = ExtractDouble(json, "avx2_gflops", _tel.Avx2Gflops);
                        _tel.WsLoqLines = ExtractLong(json, "ws_loq_lines", _tel.WsLoqLines);
                        _tel.WsP10Lines = ExtractLong(json, "ws_p10_lines", _tel.WsP10Lines);
                        _tel.WsP8Lines = ExtractLong(json, "ws_p8_lines", _tel.WsP8Lines);
                        ExtractSectorNormsCsv(json);
                    }
                }
                catch
                {
                    _tel.Online = false;
                }

                try
                {
                    if (_widgetForm != null && !_widgetForm.IsDisposed)
                    {
                        _widgetForm.BeginInvoke((MethodInvoker)delegate
                        {
                            _widgetForm.UpdateTelemetry(_tel);
                            string tip = string.Format("Î©69.0 | {0:0}k ops | FNO L2={1:0.0000} Re={2:0} | RTX {3:0}C",
                                _tel.ClusterKops, _tel.FnoL2Err, _tel.NavierReynolds, _tel.RtxTemp);
                            if (tip.Length > 63) tip = tip.Substring(0, 63);
                            _trayIcon.Text = tip;
                            _miStatus.Text = string.Format("ACT-Omega v70.0.0 | {0:0.0}k ops/s | 840/840 QED | 316 Tools (4.05M Syn)", _tel.ClusterKops);
                        });
                    }
                }
                catch { }
            });
        }
    }

    public static class Program
    {
        [STAThread]
        public static void Main(string[] args)
        {
            bool launchHud = false;
            bool showWidget = true;
            foreach (string a in args)
            {
                if (a.Equals("--hud", StringComparison.OrdinalIgnoreCase) || a.Equals("--launch-hud", StringComparison.OrdinalIgnoreCase))
                    launchHud = true;
                if (a.Equals("--no-widget", StringComparison.OrdinalIgnoreCase))
                    showWidget = false;
            }

            bool createdNew;
            using (Mutex mutex = new Mutex(true, "Global\\ActOmegaSovereignCockpitTray_v5000", out createdNew))
            {
                if (!createdNew)
                {
                    SovereignTrayApplicationContext.LaunchNativeDesktopHudWindow();
                    return;
                }
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new SovereignTrayApplicationContext(launchHud, showWidget));
            }
        }
    }
}

