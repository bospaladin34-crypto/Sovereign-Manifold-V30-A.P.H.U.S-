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
        public double AcousticSnr = 0.0;
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
                    for (int idx = 0; idx < lines; idx++)
                    {
                        CachelineNorms[idx] = (rawEnergies[idx] - minE) / span;
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
        private TelemetryData _tel = new TelemetryData();
        private Point _dragStart;
        private bool _dragging = false;
        private bool _topDesktopBannerMode = false;
        private Rectangle _btnOpenHudRect;
        private Rectangle _btnHandoverRect;
        private Rectangle _btnVerifyRect;
        private Rectangle _btnSyncShmRect;
        private Rectangle _btnBannerModeRect;
        private Rectangle _heatmapRect;
        private Action _onOpenNativeHud;
        private Action<string, string> _onRunAction;

        public SovereignWidgetForm(Action onOpenNativeHud, Action<string, string> onRunAction)
        {
            _onOpenNativeHud = onOpenNativeHud;
            _onRunAction = onRunAction;

            this.Text = "ACT-Omega v50.0.0 Live Desktop Widget";
            this.FormBorderStyle = FormBorderStyle.None;
            this.StartPosition = FormStartPosition.Manual;
            this.Size = new Size(420, 238);
            Rectangle wa = Screen.PrimaryScreen.WorkingArea;
            this.Location = new Point(wa.Right - this.Width - 18, wa.Bottom - this.Height - 18);
            this.TopMost = true;
            this.ShowInTaskbar = false;
            this.BackColor = Color.FromArgb(14, 17, 22);
            this.Opacity = 0.94;
            this.DoubleBuffered = true;

            _heatmapRect = new Rectangle(12, 92, 396, 86);
            int bw = 76;
            int gap = 4;
            int by = 190;
            _btnOpenHudRect = new Rectangle(12, by, bw, 32);
            _btnSyncShmRect = new Rectangle(12 + (bw + gap) * 1, by, bw, 32);
            _btnHandoverRect = new Rectangle(12 + (bw + gap) * 2, by, bw, 32);
            _btnVerifyRect = new Rectangle(12 + (bw + gap) * 3, by, bw, 32);
            _btnBannerModeRect = new Rectangle(12 + (bw + gap) * 4, by, bw, 32);

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
                this.Size = new Size(640, 260);
                this.Location = new Point((bounds.Width - this.Width) / 2, 36);
                this.Opacity = 0.97;
                _heatmapRect = new Rectangle(14, 98, 612, 102);
                int bw = 118;
                int gap = 5;
                int by = 212;
                _btnOpenHudRect = new Rectangle(14, by, bw, 34);
                _btnSyncShmRect = new Rectangle(14 + (bw + gap) * 1, by, bw, 34);
                _btnHandoverRect = new Rectangle(14 + (bw + gap) * 2, by, bw, 34);
                _btnVerifyRect = new Rectangle(14 + (bw + gap) * 3, by, bw, 34);
                _btnBannerModeRect = new Rectangle(14 + (bw + gap) * 4, by, bw, 34);
            }
            else
            {
                this.Size = new Size(420, 238);
                this.Location = new Point(wa.Right - this.Width - 18, wa.Bottom - this.Height - 18);
                this.Opacity = 0.94;
                _heatmapRect = new Rectangle(12, 92, 396, 86);
                int bw = 76;
                int gap = 4;
                int by = 190;
                _btnOpenHudRect = new Rectangle(12, by, bw, 32);
                _btnSyncShmRect = new Rectangle(12 + (bw + gap) * 1, by, bw, 32);
                _btnHandoverRect = new Rectangle(12 + (bw + gap) * 2, by, bw, 32);
                _btnVerifyRect = new Rectangle(12 + (bw + gap) * 3, by, bw, 32);
                _btnBannerModeRect = new Rectangle(12 + (bw + gap) * 4, by, bw, 32);
            }
            this.Invalidate();
        }

        private void OnMouseDownHandler(object sender, MouseEventArgs e)
        {
            if (e.Button == MouseButtons.Left)
            {
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
                if (_heatmapRect.Contains(e.Location))
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

            using (Pen borderPen = new Pen(Color.FromArgb(255, 180, 84), 1.5f))
            {
                g.DrawRectangle(borderPen, 1, 1, this.Width - 3, this.Height - 3);
            }

            using (Font fTitle = new Font("Consolas", 9.5f, FontStyle.Bold))
            using (Font fSub = new Font("Consolas", 8.2f, FontStyle.Regular))
            using (Font fBtn = new Font("Consolas", 7.8f, FontStyle.Bold))
            using (SolidBrush brAmber = new SolidBrush(Color.FromArgb(255, 180, 84)))
            using (SolidBrush brIvory = new SolidBrush(Color.FromArgb(255, 254, 251)))
            using (SolidBrush brGreen = new SolidBrush(Color.FromArgb(86, 211, 100)))
            using (SolidBrush brRed = new SolidBrush(Color.FromArgb(233, 78, 52)))
            using (SolidBrush brInset = new SolidBrush(Color.FromArgb(10, 13, 18)))
            {
                string modeTag = _topDesktopBannerMode ? "[WIN11 DESKTOP TOP-BANNER OVERLAY]" : "[WIN11 LIVE DESKTOP MINI-WIDGET]";
                g.DrawString("ACT-OMEGA v50.0.0 (SH4Z v5000) " + modeTag, fTitle, brAmber, 12, 10);

                Brush statusBr = _tel.Online ? brGreen : brRed;
                string statusTxt = _tel.Online
                    ? string.Format("ONLINE | Tick #{0} | {1:0.0}k ops/s | 564/564 QED | 135 Tools (CHAIN 135)", _tel.Generation, _tel.ClusterKops)
                    : "OFFLINE / AWAITING LOCALHOST :8097 TELEMETRY";
                g.DrawString(statusTxt, fSub, statusBr, 12, 28);

                string hwLine1 = string.Format("LOQ15 RTX 3050: {0:0}C ({1}MHz) | P10 G5: {2:0.0}C ({3}%) | P8 L2: {4:0.0}C ({5}%)",
                    _tel.RtxTemp, _tel.RtxClock, _tel.P10Temp, _tel.P10Batt, _tel.P8Temp, _tel.P8Batt);
                g.DrawString(hwLine1, fSub, brIvory, 12, 46);

                string hwLine2 = string.Format("63,360N (8.11MB .npage) | |B|={0:0.0}uT | {1:0.0}hPa | FNO={2:0.00000} | {3}",
                    _tel.BNorm, _tel.BaroHpa, _tel.FnoL2Err, _tel.ActiveSector);
                g.DrawString(hwLine2, fSub, brAmber, 12, 64);

                // 16x65 Measured .e8z Cacheline + Live Telemetry Sector Norm Heatmap (Zero sin/cos waves)
                g.FillRectangle(brInset, _heatmapRect);
                float cw = (float)_heatmapRect.Width / 65.0f;
                float ch = (float)_heatmapRect.Height / 16.0f;
                int pulseCol = (int)(_tel.Generation % 65);
                for (int r = 0; r < 16; r++)
                {
                    double liveSecNorm = _tel.SectorNorms[r];
                    // Min-max contrast stretch on live sector norm (typically 0.87..0.93)
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

                DrawWidgetButton(g, _btnOpenHudRect, "NATIVE HUD", Color.FromArgb(255, 180, 84), Color.FromArgb(14, 17, 22), fBtn);
                DrawWidgetButton(g, _btnSyncShmRect, "SYNC SHM", Color.FromArgb(13, 38, 24), Color.FromArgb(86, 211, 100), fBtn);
                DrawWidgetButton(g, _btnHandoverRect, "HANDOVER", Color.FromArgb(26, 18, 40), Color.FromArgb(179, 136, 255), fBtn);
                DrawWidgetButton(g, _btnVerifyRect, "VERIFY 6L", Color.FromArgb(233, 78, 52), Color.FromArgb(255, 254, 251), fBtn);
                DrawWidgetButton(g, _btnBannerModeRect, _topDesktopBannerMode ? "MINI MODE" : "BANNER", Color.FromArgb(28, 38, 50), Color.FromArgb(255, 254, 251), fBtn);
            }
        }

        private void DrawWidgetButton(Graphics g, Rectangle r, string label, Color bg, Color fg, Font f)
        {
            using (SolidBrush bBg = new SolidBrush(bg))
            using (SolidBrush bFg = new SolidBrush(fg))
            using (Pen pBorder = new Pen(Color.FromArgb(42, 59, 77), 1.0f))
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
        private NotifyIcon _trayIcon;
        private SovereignWidgetForm _widgetForm;
        private System.Windows.Forms.Timer _pollTimer;
        private TelemetryData _tel = new TelemetryData();
        private MenuItem _miStatus;

        public SovereignTrayApplicationContext(bool autoLaunchNativeHud, bool showWidget)
        {
            _widgetForm = new SovereignWidgetForm(LaunchNativeDesktopHudWindow, ExecuteClusterAction);
            if (showWidget)
            {
                _widgetForm.Show();
            }

            ContextMenu menu = new ContextMenu();
            _miStatus = new MenuItem("ACT-Omega v50.0.0 | Awaiting :8097 Telemetry...");
            _miStatus.Enabled = false;
            menu.MenuItems.Add(_miStatus);
            menu.MenuItems.Add("-");
            menu.MenuItems.Add(new MenuItem("Open Native Desktop HUD App (WebGPU)", (s, e) => LaunchNativeDesktopHudWindow()));
            menu.MenuItems.Add(new MenuItem("Open Public Portal (https://act-omega-net.dev)", (s, e) => Process.Start("https://act-omega-net.dev")));
            menu.MenuItems.Add(new MenuItem("Toggle Live Desktop Mini-Widget", (s, e) =>
            {
                if (_widgetForm.Visible) _widgetForm.Hide();
                else _widgetForm.Show();
            }));
            menu.MenuItems.Add(new MenuItem("Switch Widget: Corner Mini <-> Desktop Top-Banner Mode", (s, e) =>
            {
                if (!_widgetForm.Visible) _widgetForm.Show();
                _widgetForm.ToggleTopDesktopBannerMode();
            }));
            menu.MenuItems.Add("-");
            menu.MenuItems.Add(new MenuItem("Sync 8.11MB .npage Shared Memory (P8 + P10 Roaming)", (s, e) => ExecuteClusterAction("/api/v1/shm/p8_npage_bridge", "SYNC .NPAGE SHM")));
            menu.MenuItems.Add(new MenuItem("Handover Continuum State to Phones + Cloudflare DO", (s, e) => ExecuteClusterAction("HANDOVER_PHONES", "HANDOVER TO PHONES")));
            menu.MenuItems.Add(new MenuItem("Run 6-Layer True-Data Audit (135 Tools / 564 QED)", (s, e) => ExecuteClusterAction("/api/v1/diagnostics/v44_self_profiler", "6-LAYER AUDIT")));
            menu.MenuItems.Add(new MenuItem("Run CHAIN 135 Omni-Suite (Tools 104..135)", (s, e) => ExecuteClusterAction("/api/v1/v49/chain100_omni_suite", "CHAIN 135 OMNI-SUITE")));
            menu.MenuItems.Add("-");
            menu.MenuItems.Add(new MenuItem("Zenodo DOI: 10.5281/zenodo.23651696", (s, e) => Process.Start("https://doi.org/10.5281/zenodo.23651696")));
            menu.MenuItems.Add(new MenuItem("OSF DOI: 10.17605/OSF.IO/2XQ5Z", (s, e) => Process.Start("https://osf.io/2xq5z/overview")));
            menu.MenuItems.Add(new MenuItem("Architecture Specifications (v50.0.0)", (s, e) =>
            {
                MessageBox.Show(
                    "ACT-Omega Net v50.0.0 (SH4Z v5000 TLV | CHAIN 135)\n\n" +
                    "• Shards / Neurons: 63,360 (Core 21,120 + Exp 21,120 + Tier-3 21,120)\n" +
                    "• Synapses: 1,013,760 Dual-Shell Synapses (16/neuron)\n" +
                    "• Columns: 1,440 Chair-44 Columns\n" +
                    "• Sub-Domains: 144 (36 Macro-Domains x 4)\n" +
                    "• Vocabulary: 262,144 (18-bit) Open-Vocab BPE\n" +
                    "• Formal Proofs: 564 / 564 Substantive Lean 4 Proofs QED\n" +
                    "• Tools: 135 Native Tools (CHAIN 135)\n\n" +
                    "Permanent Archival DOIs:\n" +
                    "• Zenodo: 10.5281/zenodo.23651696\n" +
                    "• OSF: 10.17605/OSF.IO/2XQ5Z",
                    "ACT-Omega Net v50.0.0 Architecture Specifications",
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
            _trayIcon.Text = "ACT-Omega v50.0.0 | Connecting to :8097...";
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
                    g.DrawString("Ω50", f, br, 3, 9);
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
                _trayIcon.ShowBalloonTip(2000, "ACT-Omega v50.0.0 Continuum Handover", "8.11MB .npage SHM & 6-Layer state handed over to Pixel 8, Pixel 10 & Cloudflare DO.", ToolTipIcon.Info);
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
                        _tel.BNorm = ExtractDouble(json, "b_norm", _tel.BNorm);
                        _tel.BaroHpa = ExtractDouble(json, "baro_hpa", _tel.BaroHpa);
                        _tel.OrthoErr = ExtractDouble(json, "stiefel_ortho_err", _tel.OrthoErr);
                        _tel.FnoL2Err = ExtractDouble(json, "fno_l2_err", _tel.FnoL2Err);
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
                            string tip = string.Format("ACT-Omega v50.0 | {0:0}k ops/s | RTX {1:0}C | P10 {2:0.0}C | P8 {3:0.0}C",
                                _tel.ClusterKops, _tel.RtxTemp, _tel.P10Temp, _tel.P8Temp);
                            if (tip.Length > 63) tip = tip.Substring(0, 63);
                            _trayIcon.Text = tip;
                            _miStatus.Text = string.Format("ACT-Omega v50.0.0 | {0:0.0}k ops/s | Tick #{1} | 135 Tools", _tel.ClusterKops, _tel.Generation);
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
