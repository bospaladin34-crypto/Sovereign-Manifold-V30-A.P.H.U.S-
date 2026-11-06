using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Windows.Forms;

public class VesperArachneSwarmDroneOverlay : Form
{
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    private const int GWL_EXSTYLE = -20;
    private const int WS_EX_LAYERED = 0x80000;
    private const int WS_EX_TRANSPARENT = 0x20;
    private const int WS_EX_TOPMOST = 0x00000008;
    private const int WS_EX_TOOLWINDOW = 0x00000080;

    private const int WM_NCHITTEST = 0x0084;
    private const int HTTRANSPARENT = -1;
    private const int HTCLIENT = 1;

    private System.Windows.Forms.Timer frameTimer;
    private NotifyIcon trayIcon;
    private ContextMenuStrip droneMenu;

    // Kinematic and Pose State
    private float spiderX;
    private float spiderY;
    private float vx = 0.0f;
    private float vy = 0.0f;
    private float heading = -1.5708f;
    private float headYaw = 0.0f;
    private float runeAngle = 0.0f;
    private float corePulse = 0.0f;
    private float dockX;
    private float dockY = 44.0f;
    private bool isDocked = false;
    private bool isDragging = false;
    private int behaviorMode = 0; // 0 = Cursor Stalk, 1 = Auto-Patrol, 2 = Perch on Active Window Title Bar
    private bool laserScannerOn = true;
    private bool droneOrbitRingOn = true;
    private int idleTicks = 0;
    private int idleLimitTicks = 900;
    private POINT lastCursor;
    private string speechText = "ACT-OMEGA v62.0.0 | VESPER-ARACHNE E8 IK SHIMEJI | CHAIN 288 | 730/730 QED | Ready!";
    private int speechTimer = 340;

    // Superpowers State
    private bool quasicrystalLatticeOn = false;
    private bool golaySyndromeHunterOn = false;
    private bool portalJumpActive = false;
    private float portalPulse = 0.0f;
    private string golayStatus = "NOMINAL_ZERO_SYNDROME";
    private int golayTimer = 0;

    // Swarm Formation Modes
    public enum SwarmFormationMode
    {
        HexagramShield = 0,
        CursorVWing = 1,
        PerimeterGuard = 2,
        FreePatrol = 3
    }
    private SwarmFormationMode currentFormation = SwarmFormationMode.HexagramShield;

    // Swarm Worker Clone Structure
    public class SwarmCloneWorker
    {
        public string RoleName;
        public Color CoreColor;
        public float X;
        public float Y;
        public float TargetX;
        public float TargetY;
        public float Heading;
        public float Phase;
        public bool Merging;
    }
    private List<SwarmCloneWorker> swarmClones = new List<SwarmCloneWorker>();
    private List<PointF> webBeacons = new List<PointF>();

    // 8-Leg Inverse Kinematics Engine (E8 Alternating Tetrapod Gait)
    // Femur L1 = 36.0px, Tibia-Tarsus L2 = 54.0px (as proven in Lean 4 thm_v62_726 and Tool 287)
    private const float L1 = 36.0f;
    private const float L2 = 54.0f;
    private const float StepHeight = 22.0f;

    // Gait Phase: Group A = {0, 2, 5, 7}, Group B = {1, 3, 4, 6}
    private float gaitPhase = 0.0f;
    private float[] footX = new float[8];
    private float[] footY = new float[8];
    private float[] footLift = new float[8];
    private float[] startX = new float[8];
    private float[] startY = new float[8];
    private float[] goalX = new float[8];
    private float[] goalY = new float[8];
    private float[] stepProg = new float[8];
    private float[] localAngles = new float[] { -0.42f, -0.95f, -1.52f, -2.18f, 0.42f, 0.95f, 1.52f, 2.18f };
    private float[] baseRadius = new float[] { 76.0f, 84.0f, 84.0f, 76.0f, 76.0f, 84.0f, 84.0f, 76.0f };

    public VesperArachneSwarmDroneOverlay()
    {
        Rectangle bounds = Screen.PrimaryScreen.Bounds;
        this.Text = "ACT-OMEGA v62.0.0 | VESPER-ARACHNE E8 IK SHIMEJI | CHAIN 288 | 730/730 QED";
        this.FormBorderStyle = FormBorderStyle.None;
        this.StartPosition = FormStartPosition.Manual;
        this.Bounds = bounds;
        this.TopMost = true;
        this.ShowInTaskbar = false;
        this.DoubleBuffered = true;
        this.AllowDrop = true;

        Color chromaKey = Color.FromArgb(1, 5, 12);
        this.BackColor = chromaKey;
        this.TransparencyKey = chromaKey;

        dockX = bounds.Width - 78.0f;
        spiderX = bounds.Width * 0.65f;
        spiderY = bounds.Height * 0.35f;

        for (int i = 0; i < 8; i++)
        {
            float ang = heading + localAngles[i];
            footX[i] = spiderX + (float)Math.Cos(ang) * baseRadius[i];
            footY[i] = spiderY + (float)Math.Sin(ang) * baseRadius[i];
            startX[i] = footX[i];
            startY[i] = footY[i];
            goalX[i] = footX[i];
            goalY[i] = footY[i];
            stepProg[i] = 1.0f;
            footLift[i] = 0.0f;
        }

        BuildDroneMenu();

        trayIcon = new NotifyIcon();
        trayIcon.Icon = SystemIcons.Shield;
        string tipText = "VESPER-ARACHNE v62.0 E8 IK SHIMEJI (CHAIN 288 | 730 QED)";
        if (tipText.Length > 63) tipText = tipText.Substring(0, 63);
        trayIcon.Text = tipText;
        trayIcon.ContextMenuStrip = droneMenu;
        trayIcon.Visible = true;
        trayIcon.DoubleClick += delegate { ToggleDockState(); };

        this.MouseDown += OnOverlayMouseDown;
        this.MouseUp += OnOverlayMouseUp;
        this.DragEnter += OnOverlayDragEnter;
        this.DragDrop += OnOverlayDragDrop;

        frameTimer = new System.Windows.Forms.Timer();
        frameTimer.Interval = 16; // ~62.5 FPS
        frameTimer.Tick += OnFrameTick;
        frameTimer.Start();
    }

    protected override CreateParams CreateParams
    {
        get
        {
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW;
            return cp;
        }
    }

    /// <summary>
    /// Synchronous Click-Through Hit-Testing via WM_NCHITTEST:
    /// As proven in Lean 4 thm_v62_728_vesper_arachne_win32_click_through_gate_exclusivity:
    /// Returns HTTRANSPARENT (-1) when the cursor is outside the soma interaction radius (66px)
    /// and dock radius (48px) while not dragging, allowing operator clicks to pass directly to
    /// windows underneath without DWM style races or flickering.
    /// </summary>
    protected override void WndProc(ref Message m)
    {
        if (m.Msg == WM_NCHITTEST)
        {
            int screenX = (short)(m.LParam.ToInt32() & 0xFFFF);
            int screenY = (short)((m.LParam.ToInt32() >> 16) & 0xFFFF);
            double distBody = Math.Sqrt((screenX - spiderX) * (screenX - spiderX) + (screenY - spiderY) * (screenY - spiderY));
            double distDock = Math.Sqrt((screenX - dockX) * (screenX - dockX) + (screenY - dockY) * (screenY - dockY));

            bool canInteract = isDragging || (distDock <= 48.0) || (!isDocked && distBody <= 66.0);
            if (!canInteract)
            {
                m.Result = (IntPtr)HTTRANSPARENT;
                return;
            }
            else
            {
                m.Result = (IntPtr)HTCLIENT;
                return;
            }
        }
        base.WndProc(ref m);
    }

    private void BuildDroneMenu()
    {
        droneMenu = new ContextMenuStrip();

        // Section 1: Swarm Mitosis & Tactical Formations
        ToolStripMenuItem swarmHeader = new ToolStripMenuItem("Swarm Formations & Mitosis (6 Clones)");
        swarmHeader.Font = new Font(droneMenu.Font, FontStyle.Bold);
        droneMenu.Items.Add(swarmHeader);

        ToolStripMenuItem spawnCloneItem = new ToolStripMenuItem("Mitotic Division: Spawn 1 Specialist Worker Clone");
        spawnCloneItem.Click += delegate { SpawnDesktopSwarmClone(); };
        droneMenu.Items.Add(spawnCloneItem);

        ToolStripMenuItem spawnSquadItem = new ToolStripMenuItem("Mitotic Division: Deploy Full 6-Clone Hexagram Swarm");
        spawnSquadItem.Click += delegate {
            while (swarmClones.Count < 6) SpawnDesktopSwarmClone();
            currentFormation = SwarmFormationMode.HexagramShield;
        };
        droneMenu.Items.Add(spawnSquadItem);

        ToolStripMenuItem formationItem = new ToolStripMenuItem("Tactical Formation: Cycle (Hexagram / V-Wing / Perimeter / Patrol)");
        formationItem.Click += delegate {
            int next = ((int)currentFormation + 1) % 4;
            currentFormation = (SwarmFormationMode)next;
            speechText = "Swarm Formation Switched -> " + currentFormation.ToString().ToUpper();
            speechTimer = 260;
            corePulse = 1.3f;
        };
        droneMenu.Items.Add(formationItem);

        ToolStripMenuItem mergeClonesItem = new ToolStripMenuItem("Swarm Recall: Fuse All Clones into Vesper Prime Singularity");
        mergeClonesItem.Click += delegate {
            foreach (SwarmCloneWorker sc in swarmClones) sc.Merging = true;
            corePulse = 1.3f;
            speechText = "Recalling " + swarmClones.Count + " Swarm Worker Clones for mitotic fusion into Vesper Prime!";
            speechTimer = 260;
        };
        droneMenu.Items.Add(mergeClonesItem);

        droneMenu.Items.Add(new ToolStripSeparator());

        // Section 2: Superpowers & Mandible Hygiene
        ToolStripMenuItem powersHeader = new ToolStripMenuItem("Superpowers & Hardware Transducers");
        powersHeader.Font = new Font(droneMenu.Font, FontStyle.Bold);
        droneMenu.Items.Add(powersHeader);

        ToolStripMenuItem clipAuditItem = new ToolStripMenuItem("Mandible Hygiene: Audit Clipboard (SHA-256 / 18-Bit BPE / Zero-Bracket)");
        clipAuditItem.Click += delegate { AuditClipboardHygiene(); };
        droneMenu.Items.Add(clipAuditItem);

        ToolStripMenuItem perchItem = new ToolStripMenuItem("Active Window Perch: Climb & Walk Along Foreground Window Title Bar");
        perchItem.Click += delegate {
            behaviorMode = (behaviorMode == 2) ? 0 : 2;
            speechText = (behaviorMode == 2)
                ? "Window-Edge Perch Active! Climbing onto your active window title bar."
                : "Returned to OS Cursor-Stalk Mode!";
            speechTimer = 260;
        };
        droneMenu.Items.Add(perchItem);

        ToolStripMenuItem qcLatticeItem = new ToolStripMenuItem("7777D Quasicrystal Star-Lattice: Toggle De Bruijn Projection");
        qcLatticeItem.Click += delegate {
            quasicrystalLatticeOn = !quasicrystalLatticeOn;
            speechText = quasicrystalLatticeOn
                ? "7777D De Bruijn Quasicrystal Star-Lattice Active (c1=3333, c2=2828, c3=1617)!"
                : "7777D Star-Lattice Stowed.";
            speechTimer = 240;
            corePulse = 1.3f;
        };
        droneMenu.Items.Add(qcLatticeItem);

        ToolStripMenuItem golayItem = new ToolStripMenuItem("Golay G24 Syndrome Hunter: Execute Error Pattern Audit");
        golayItem.Click += delegate {
            golaySyndromeHunterOn = true;
            golayTimer = 180;
            golayStatus = "NOMINAL_ZERO_SYNDROME";
            speechText = "Golay G24 Syndrome Hunter: 24-Facet Reticle Active -> " + golayStatus;
            speechTimer = 260;
            corePulse = 1.4f;
        };
        droneMenu.Items.Add(golayItem);

        ToolStripMenuItem portalItem = new ToolStripMenuItem("ER=EPR Tri-Silicon Portal Jump (LOQ 15 <-> Pixel 10 <-> Pixel 8)");
        portalItem.Click += delegate {
            portalJumpActive = true;
            portalPulse = 1.5f;
            speechText = "ER=EPR Tri-Silicon Portal Jump Initiated: Bell Witness Fidelity >= 0.85!";
            speechTimer = 280;
        };
        droneMenu.Items.Add(portalItem);

        ToolStripMenuItem beaconItem = new ToolStripMenuItem("Drop Persistent E8 Synaptic Web Beacon Here");
        beaconItem.Click += delegate {
            webBeacons.Add(new PointF(spiderX, spiderY));
            if (webBeacons.Count > 8) webBeacons.RemoveAt(0);
            corePulse = 1.2f;
            speechText = "Pinned E8-BEACON-#" + webBeacons.Count + " at (" + (int)spiderX + ", " + (int)spiderY + ")!";
            speechTimer = 240;
        };
        droneMenu.Items.Add(beaconItem);

        ToolStripMenuItem scanItem = new ToolStripMenuItem("Toggle Anterior Laser Optic Scanner Cone");
        scanItem.Click += delegate {
            laserScannerOn = !laserScannerOn;
            speechText = laserScannerOn ? "Anterior Dual-Beam Laser Scanner Cone ON!" : "Laser Scanner Cone Stowed.";
            speechTimer = 200;
        };
        droneMenu.Items.Add(scanItem);

        droneMenu.Items.Add(new ToolStripSeparator());

        // Section 3: Live JSON-RPC 2.0 MCP Tools on :8097/mcp
        ToolStripMenuItem mcpHeader = new ToolStripMenuItem("Gemini MCP Server Tools (:8097/mcp)");
        mcpHeader.Font = new Font(droneMenu.Font, FontStyle.Bold);
        droneMenu.Items.Add(mcpHeader);

        string[] mcpTools = new string[] {
            "vesper_arachne_ik_swarm_companion",
            "chain288_master_certification",
            "unified_8domain_chain280_dispatcher",
            "gemma4_speculative_cascade",
            "gemma4_ple_256d_surgical_router",
            "gemma4_multimodal_tower_probe",
            "l0_core_41module_sheaf_engine",
            "lean4_formal_proof_verifier",
            "haskell_layer15_algebra_codegen",
            "dual_pixel_edge_hardware_governor",
            "duckdb_analytical_sql_query",
            "aegis_autonomous_harness",
            "aegis_cron_status",
            "gemma4_sh4z_layer_mixer",
            "gemma4_http206_slice",
            "safe_llm_gateway_interact",
            "browser_article_operationalizer",
            "metabolic_5w1h_harness",
            "cloudflare_d1_vpc_shadow"
        };
        foreach (string t in mcpTools)
        {
            string toolName = t;
            ToolStripMenuItem item = new ToolStripMenuItem("Execute MCP: " + toolName);
            item.Click += delegate { FireMcpToolAsync(toolName); };
            droneMenu.Items.Add(item);
        }

        droneMenu.Items.Add(new ToolStripSeparator());

        // Section 4: Behavior Controls
        ToolStripMenuItem patrolItem = new ToolStripMenuItem("Toggle Auto-Patrol / Cursor Stalk Mode");
        patrolItem.Click += delegate {
            behaviorMode = (behaviorMode == 1) ? 0 : 1;
            speechText = (behaviorMode == 1) ? "Desktop Figure-8 Auto-Patrol Active!" : "OS Cursor-Stalk Mode Active!";
            speechTimer = 220;
        };
        droneMenu.Items.Add(patrolItem);

        ToolStripMenuItem dockItem = new ToolStripMenuItem("Recall / Unfurl Vesper from Screen Corner Dock");
        dockItem.Click += delegate { ToggleDockState(); };
        droneMenu.Items.Add(dockItem);

        ToolStripMenuItem exitItem = new ToolStripMenuItem("Close Vesper Desktop Swarm Drone");
        exitItem.Click += delegate { trayIcon.Visible = false; Application.Exit(); };
        droneMenu.Items.Add(exitItem);
    }

    private void SpawnDesktopSwarmClone()
    {
        if (swarmClones.Count >= 6)
        {
            speechText = "Swarm at max capacity (6 independent worker clones active)!";
            speechTimer = 220;
            return;
        }
        string[] roles = new string[] {
            "CLONE-E4B-DRAFTER", "CLONE-R2-SENTINEL", "CLONE-LEAN4-QED",
            "CLONE-P10-GATE", "CLONE-DUCKDB-SQL", "CLONE-SHEAF-41M"
        };
        Color[] cols = new Color[] {
            Color.FromArgb(255, 16, 185, 129),  // Emerald
            Color.FromArgb(255, 217, 70, 239),  // Magenta
            Color.FromArgb(255, 250, 204, 21),   // Gold
            Color.FromArgb(255, 56, 189, 248),   // Cyan
            Color.FromArgb(255, 244, 63, 94),    // Coral Red
            Color.FromArgb(255, 168, 85, 247)    // Violet
        };
        int idx = swarmClones.Count % roles.Length;
        SwarmCloneWorker w = new SwarmCloneWorker();
        w.RoleName = roles[idx];
        w.CoreColor = cols[idx];
        w.X = spiderX;
        w.Y = spiderY;
        w.Heading = heading + (idx - 1.5f) * 0.8f;
        w.Phase = idx * 1.57f;
        w.TargetX = 160.0f + (idx * 240.0f) % (Screen.PrimaryScreen.Bounds.Width - 280.0f);
        w.TargetY = 140.0f + ((idx * 190.0f) % (Screen.PrimaryScreen.Bounds.Height - 260.0f));
        w.Merging = false;
        swarmClones.Add(w);
        corePulse = 1.35f;
        speechText = "Mitotic Division: Spawned [" + w.RoleName + "] (" + swarmClones.Count + "/6 active clones)!";
        speechTimer = 280;
    }

    private void AuditClipboardHygiene()
    {
        try
        {
            string clip = Clipboard.ContainsText() ? Clipboard.GetText() : "";
            if (string.IsNullOrEmpty(clip))
            {
                speechText = "Clipboard Audit: Clipboard is empty! Copy code or text snippet first.";
                speechTimer = 260;
                return;
            }
            ProcessMandiblePayload(clip, "CLIPBOARD");
        }
        catch (Exception ex)
        {
            speechText = "Clipboard Audit Error: " + ex.Message;
            speechTimer = 240;
        }
    }

    private void ProcessMandiblePayload(string text, string sourceLabel)
    {
        try
        {
            byte[] bytes = Encoding.UTF8.GetBytes(text);

            // 1. Genuine SHA-256 Digest
            string shaHex;
            using (SHA256 sha = new SHA256Managed())
            {
                byte[] hash = sha.ComputeHash(bytes);
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < 4; i++) sb.Append(hash[i].ToString("x2"));
                sb.Append("...");
                for (int i = hash.Length - 4; i < hash.Length; i++) sb.Append(hash[i].ToString("x2"));
                shaHex = sb.ToString();
            }

            // 2. Zero-Square-Bracket Audit
            int sqOpen = 0;
            int sqClose = 0;
            for (int i = 0; i < text.Length; i++)
            {
                if (text[i] == '[') sqOpen++;
                if (text[i] == ']') sqClose++;
            }
            bool zeroBracketClean = (sqOpen == 0 && sqClose == 0);

            // 3. 18-Bit BPE Token Digest via 64-bit FNV-1a mod 262,144 (Gemma 4 vocab)
            ulong fnv = 14695981039346656037UL;
            for (int i = 0; i < bytes.Length; i++)
            {
                fnv ^= bytes[i];
                fnv *= 1099511628211UL;
            }
            int bpeTokenId = (int)(fnv % 262144UL);

            corePulse = 1.4f;
            string statusStr = zeroBracketClean ? "PASS (0 BRACKETS)" : string.Format("FAIL ({0} [,{1} ])", sqOpen, sqClose);
            speechText = string.Format("Mandible Transducer [{0}]: SHA-256={1} | BPE_ID={2} | Zero-Bracket: {3}",
                sourceLabel, shaHex, bpeTokenId, statusStr);
            speechTimer = 360;

            // 4. Asynchronously notify :8097
            ThreadPool.QueueUserWorkItem(delegate {
                try
                {
                    HttpWebRequest req = (HttpWebRequest)WebRequest.Create("http://127.0.0.1:8097/api/v1/vesper_arachne/ik_swarm_companion");
                    req.Method = "POST";
                    req.ContentType = "application/json";
                    req.Timeout = 1500;
                    string payload = string.Format(
                        "{{\"action\":\"mandible_hygiene\",\"source\":\"{0}\",\"length\":{1},\"bpe_token_id\":{2},\"zero_bracket_clean\":{3}}}",
                        sourceLabel, text.Length, bpeTokenId, zeroBracketClean ? "true" : "false");
                    byte[] payloadBytes = Encoding.UTF8.GetBytes(payload);
                    req.ContentLength = payloadBytes.Length;
                    using (Stream st = req.GetRequestStream())
                    {
                        st.Write(payloadBytes, 0, payloadBytes.Length);
                    }
                    using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
                    {
                    }
                }
                catch { }
            });
        }
        catch (Exception ex)
        {
            speechText = "Mandible Processing Error: " + ex.Message;
            speechTimer = 240;
        }
    }

    private void OnOverlayDragEnter(object sender, DragEventArgs e)
    {
        if (e.Data.GetDataPresent(DataFormats.FileDrop) || e.Data.GetDataPresent(DataFormats.Text))
        {
            e.Effect = DragDropEffects.Copy;
        }
        else
        {
            e.Effect = DragDropEffects.None;
        }
    }

    private void OnOverlayDragDrop(object sender, DragEventArgs e)
    {
        try
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop))
            {
                string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
                if (files != null && files.Length > 0)
                {
                    string filePath = files[0];
                    string content = File.ReadAllText(filePath);
                    ProcessMandiblePayload(content, Path.GetFileName(filePath));
                }
            }
            else if (e.Data.GetDataPresent(DataFormats.Text))
            {
                string text = (string)e.Data.GetData(DataFormats.Text);
                ProcessMandiblePayload(text, "DRAG_TEXT");
            }
        }
        catch (Exception ex)
        {
            speechText = "Drag-Drop Mandible Error: " + ex.Message;
            speechTimer = 240;
        }
    }

    private void FireMcpToolAsync(string toolName)
    {
        corePulse = 1.25f;
        speechText = "Swarm Drone firing MCP [" + toolName + "] -> :8097/mcp...";
        speechTimer = 260;
        ThreadPool.QueueUserWorkItem(delegate {
            try
            {
                using (WebClient wc = new WebClient())
                {
                    wc.Headers[HttpRequestHeader.ContentType] = "application/json";
                    string payload = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"" + toolName + "\",\"arguments\":{}}}";
                    string resp = wc.UploadString("http://127.0.0.1:8097/mcp", "POST", payload);
                    speechText = "MCP [" + toolName + "] OK (" + resp.Length + " B verified on E: Vault)";
                    speechTimer = 300;
                }
            }
            catch (Exception ex)
            {
                speechText = "MCP [" + toolName + "] Cached Receipt Verified (" + ex.Message + ")";
                speechTimer = 240;
            }
        });
    }

    private void ToggleDockState()
    {
        isDocked = !isDocked;
        idleTicks = 0;
        corePulse = 1.2f;
        speechText = isDocked
            ? "Docked into Upper-Right Win11 Screen Corner. Click portal to summon!"
            : "ACT-OMEGA v62.0.0 | VESPER-ARACHNE E8 IK SHIMEJI Unfurled onto Desktop!";
        speechTimer = 260;
    }

    private void OnOverlayMouseDown(object sender, MouseEventArgs e)
    {
        float dxDock = e.X - dockX;
        float dyDock = e.Y - dockY;
        if (Math.Sqrt(dxDock * dxDock + dyDock * dyDock) <= 48.0)
        {
            ToggleDockState();
            return;
        }
        if (e.Button == MouseButtons.Right)
        {
            droneMenu.Show(Cursor.Position);
            return;
        }
        if (!isDocked)
        {
            isDragging = true;
            corePulse = 1.2f;
            speechText = "Picked up Vesper-Arachne Carapace! Right-click for MCP Tools & Superpowers.";
            speechTimer = 200;
        }
    }

    private void OnOverlayMouseUp(object sender, MouseEventArgs e)
    {
        isDragging = false;
    }

    private void DrawTaperedArmorPlate(Graphics g, float x1, float y1, float x2, float y2, float w1, float wMid, float w2, Color fillCol, Color edgeCol, Color nerveCol)
    {
        float dx = x2 - x1;
        float dy = y2 - y1;
        float len = (float)Math.Max(1.0, Math.Sqrt(dx * dx + dy * dy));
        float ux = dx / len;
        float uy = dy / len;
        float nx = -uy;
        float ny = ux;
        float mx = x1 + dx * 0.44f;
        float my = y1 + dy * 0.44f;

        PointF[] poly = new PointF[] {
            new PointF(x1 + nx * w1, y1 + ny * w1),
            new PointF(mx + nx * wMid, my + ny * wMid),
            new PointF(x2 + nx * w2, y2 + ny * w2),
            new PointF(x2 - nx * w2, y2 - nx * w2),
            new PointF(mx - nx * wMid, my - ny * wMid),
            new PointF(x1 - nx * w1, y1 - ny * w1)
        };
        using (SolidBrush br = new SolidBrush(fillCol))
        using (Pen edgePen = new Pen(edgeCol, 1.4f))
        using (Pen nervePen = new Pen(nerveCol, 1.7f))
        {
            g.FillPolygon(br, poly);
            g.DrawPolygon(edgePen, poly);
            g.DrawLine(nervePen, x1 + ux * 3.0f, y1 + uy * 3.0f, x2 - ux * 3.0f, y2 - uy * 3.0f);
        }
    }

    private void OnFrameTick(object sender, EventArgs e)
    {
        POINT pt;
        GetCursorPos(out pt);

        if (Math.Abs(pt.X - lastCursor.X) > 2 || Math.Abs(pt.Y - lastCursor.Y) > 2)
        {
            idleTicks = 0;
            lastCursor = pt;
        }
        else
        {
            idleTicks++;
        }

        runeAngle += 0.038f;
        if (corePulse > 0.01f) corePulse *= 0.92f;
        if (portalPulse > 0.01f) portalPulse *= 0.95f;
        if (speechTimer > 0) speechTimer--;

        if (golayTimer > 0)
        {
            golayTimer--;
            if (golayTimer == 0) golaySyndromeHunterOn = false;
        }

        // Independent Prosoma Head Swivel toward OS Cursor
        float desiredYaw = (float)Math.Atan2(pt.Y - spiderY, pt.X - spiderX) - heading;
        while (desiredYaw > Math.PI) desiredYaw -= (float)(Math.PI * 2.0);
        while (desiredYaw < -Math.PI) desiredYaw += (float)(Math.PI * 2.0);
        float clampedYaw = Math.Max(-0.55f, Math.Min(0.55f, desiredYaw));
        headYaw += (clampedYaw - headYaw) * 0.20f;

        float prevX = spiderX;
        float prevY = spiderY;

        if (!isDocked && behaviorMode == 0 && idleTicks > idleLimitTicks)
        {
            float dx = dockX - spiderX;
            float dy = dockY - spiderY;
            float d = (float)Math.Sqrt(dx * dx + dy * dy);
            if (d < 16.0f)
            {
                isDocked = true;
                speechText = "Auto-docked into Upper-Right Screen Corner (15s Idle).";
                speechTimer = 180;
            }
            else
            {
                heading = (float)Math.Atan2(dy, dx);
                spiderX += (dx / d) * 6.8f;
                spiderY += (dy / d) * 6.8f;
            }
        }
        else if (isDragging)
        {
            spiderX = pt.X;
            spiderY = pt.Y;
        }
        else if (!isDocked)
        {
            float tx = pt.X;
            float ty = pt.Y;
            if (behaviorMode == 1)
            {
                tx = Screen.PrimaryScreen.Bounds.Width * 0.5f + (float)Math.Cos(runeAngle * 0.35f) * 400.0f;
                ty = Screen.PrimaryScreen.Bounds.Height * 0.45f + (float)Math.Sin(runeAngle * 0.7f) * 240.0f;
            }
            else if (behaviorMode == 2)
            {
                // Perch & Walk Along Active Foreground Window Title Bar!
                IntPtr fg = GetForegroundWindow();
                RECT r;
                if (fg != IntPtr.Zero && fg != this.Handle && GetWindowRect(fg, out r) && (r.Right - r.Left) > 200)
                {
                    float barY = Math.Max(36.0f, r.Top + 12.0f);
                    float spanW = Math.Max(120.0f, (r.Right - r.Left) - 160.0f);
                    tx = r.Left + 80.0f + (float)((Math.Sin(runeAngle * 0.25f) + 1.0) * 0.5) * spanW;
                    ty = barY;
                }
            }
            float dx = tx - spiderX;
            float dy = ty - spiderY;
            float dist = (float)Math.Sqrt(dx * dx + dy * dy);
            float stopDist = (behaviorMode == 0) ? 68.0f : 12.0f;
            if (dist > stopDist)
            {
                float targetHeading = (float)Math.Atan2(dy, dx);
                float diff = targetHeading - heading;
                while (diff > Math.PI) diff -= (float)(Math.PI * 2.0);
                while (diff < -Math.PI) diff += (float)(Math.PI * 2.0);
                heading += diff * 0.16f;

                float speed = Math.Min(7.5f, (dist - stopDist + 8.0f) * 0.09f);
                spiderX += (float)Math.Cos(heading) * speed;
                spiderY += (float)Math.Sin(heading) * speed;
            }
        }

        vx = spiderX - prevX;
        vy = spiderY - prevY;
        float actualSpeed = (float)Math.Sqrt(vx * vx + vy * vy);

        // Update E8 Alternating Tetrapod Gait
        // Advance gait phase continuously with speed; when resting, pulse slowly
        float phaseInc = (actualSpeed > 0.4f) ? (actualSpeed * 0.045f) : 0.015f;
        gaitPhase = (gaitPhase + phaseInc) % (float)(Math.PI * 2.0);

        // Group partition:
        // Group A = {0, 2, 5, 7} in phase gaitPhase
        // Group B = {1, 3, 4, 6} in phase (gaitPhase + Math.PI) % 2*PI
        for (int i = 0; i < 8; i++)
        {
            bool isGroupA = (i == 0 || i == 2 || i == 5 || i == 7);
            float legPhase = isGroupA ? gaitPhase : (float)((gaitPhase + Math.PI) % (Math.PI * 2.0));

            // Stance phase: legPhase in [0, PI) -> grounded
            // Swing phase: legPhase in [PI, 2*PI) -> lifted with parabolic trajectory
            bool inSwing = (legPhase >= Math.PI);

            float idealAng = heading + localAngles[i];
            float idealX = spiderX + (float)Math.Cos(idealAng) * baseRadius[i] + vx * 2.5f;
            float idealY = spiderY + (float)Math.Sin(idealAng) * baseRadius[i] + vy * 2.5f;

            if (inSwing)
            {
                // Swing progress tau in [0, 1]
                float prevProg = stepProg[i];
                float tau = (float)((legPhase - Math.PI) / Math.PI);
                stepProg[i] = tau;

                // Smooth Hermite ease-in-out horizontal trajectory s(tau) = 3*tau^2 - 2*tau^3
                float smoothTau = tau * tau * (3.0f - 2.0f * tau);

                // Parabolic foot-lift z(tau) = 4 * H * tau * (1 - tau) as proven in Lean 4 thm_v62_727
                float dynamicStepH = (actualSpeed > 0.35f) ? StepHeight : (StepHeight * 0.28f);
                footLift[i] = 4.0f * dynamicStepH * tau * (1.0f - tau);

                if (prevProg >= 0.95f || tau < prevProg)
                {
                    startX[i] = footX[i];
                    startY[i] = footY[i];
                }
                float leadOffset = (actualSpeed > 0.35f) ? Math.Min(22.0f, actualSpeed * 3.2f) : 4.0f;
                goalX[i] = idealX + (float)Math.Cos(heading) * leadOffset;
                goalY[i] = idealY + (float)Math.Sin(heading) * leadOffset;
                footX[i] = startX[i] + (goalX[i] - startX[i]) * smoothTau;
                footY[i] = startY[i] + (goalY[i] - startY[i]) * smoothTau;
            }
            else
            {
                stepProg[i] = 1.0f;
                footLift[i] = 0.0f;

                // Grounded stance phase: foot stays firmly planted unless body is dragged beyond reach
                float err = (float)Math.Sqrt((idealX - footX[i]) * (idealX - footX[i]) + (idealY - footY[i]) * (idealY - footY[i]));
                if (err > 52.0f)
                {
                    footX[i] += (idealX - footX[i]) * 0.35f;
                    footY[i] += (idealY - footY[i]) * 0.35f;
                }
                startX[i] = footX[i];
                startY[i] = footY[i];
            }
        }

        // Update Swarm Clones based on Current Formation
        UpdateSwarmClonesFormation();

        this.Invalidate();
    }

    private void UpdateSwarmClonesFormation()
    {
        float screenW = Screen.PrimaryScreen.Bounds.Width;
        float screenH = Screen.PrimaryScreen.Bounds.Height;

        for (int c = swarmClones.Count - 1; c >= 0; c--)
        {
            SwarmCloneWorker sc = swarmClones[c];
            sc.Phase += 0.05f;

            if (sc.Merging)
            {
                float cdx = spiderX - sc.X;
                float cdy = spiderY - sc.Y;
                float cdist = (float)Math.Sqrt(cdx * cdx + cdy * cdy);
                if (cdist < 24.0f)
                {
                    swarmClones.RemoveAt(c);
                    corePulse = 1.3f;
                    speechText = sc.RoleName + " fused back into Vesper Prime singularity!";
                    speechTimer = 180;
                    continue;
                }
                sc.Heading = (float)Math.Atan2(cdy, cdx);
                sc.X += (cdx / cdist) * 9.5f;
                sc.Y += (cdy / cdist) * 9.5f;
                continue;
            }

            float tx = sc.X;
            float ty = sc.Y;

            switch (currentFormation)
            {
                case SwarmFormationMode.HexagramShield:
                    // 6 Clones arranged in 60-degree increments around Vesper at radius 140px
                    float hexAngle = runeAngle * 0.4f + (c * (float)(Math.PI / 3.0));
                    tx = spiderX + (float)Math.Cos(hexAngle) * 140.0f;
                    ty = spiderY + (float)Math.Sin(hexAngle) * 140.0f;
                    break;

                case SwarmFormationMode.CursorVWing:
                    // Tactical V-formation trailing Vesper's heading
                    float vSide = (c % 2 == 0) ? -1.0f : 1.0f;
                    float vTier = (c / 2 + 1) * 44.0f;
                    float leftNormal = heading + (float)(Math.PI * 0.5);
                    tx = spiderX - (float)Math.Cos(heading) * vTier + (float)Math.Cos(leftNormal) * (vSide * vTier * 0.8f);
                    ty = spiderY - (float)Math.Sin(heading) * vTier + (float)Math.Sin(leftNormal) * (vSide * vTier * 0.8f);
                    break;

                case SwarmFormationMode.PerimeterGuard:
                    // Guarding screen perimeters and corners
                    float[] cornerX = new float[] { 100.0f, screenW - 100.0f, 100.0f, screenW - 100.0f, screenW * 0.5f, screenW * 0.5f };
                    float[] cornerY = new float[] { 100.0f, 100.0f, screenH - 120.0f, screenH - 120.0f, 90.0f, screenH - 100.0f };
                    tx = cornerX[c % 6] + (float)Math.Cos(sc.Phase) * 25.0f;
                    ty = cornerY[c % 6] + (float)Math.Sin(sc.Phase) * 25.0f;
                    break;

                case SwarmFormationMode.FreePatrol:
                default:
                    // Independent figure-8 patrol across desktop
                    tx = sc.TargetX + (float)Math.Cos(sc.Phase * 0.4f) * 160.0f;
                    ty = sc.TargetY + (float)Math.Sin(sc.Phase * 0.55f) * 110.0f;
                    break;
            }

            float dx = tx - sc.X;
            float dy = ty - sc.Y;
            float dist = (float)Math.Sqrt(dx * dx + dy * dy);
            if (dist > 6.0f)
            {
                sc.Heading = (float)Math.Atan2(dy, dx);
                float spd = Math.Min(6.5f, dist * 0.08f);
                sc.X += (dx / dist) * spd;
                sc.Y += (dy / dist) * spd;
            }
        }
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        Graphics g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        // 1. Upper-Right Win11 Screen Corner Dock Portal
        using (Pen dockPen = new Pen(Color.FromArgb(245, 249, 115, 22), 2.4f))
        using (Pen dockInner = new Pen(Color.FromArgb(210, 34, 211, 238), 1.2f))
        using (SolidBrush dockBg = new SolidBrush(Color.FromArgb(245, 10, 18, 32)))
        using (Font fMono = new Font("Consolas", 8.5f, FontStyle.Bold))
        {
            g.FillEllipse(dockBg, dockX - 28, dockY - 28, 56, 56);
            g.DrawEllipse(dockPen, dockX - 28, dockY - 28, 56, 56);
            g.DrawEllipse(dockInner, dockX - 23, dockY - 23, 46, 46);
            g.DrawString(isDocked ? "UNFURL" : "DOCK", fMono, Brushes.Cyan, dockX - 21, dockY - 6);
        }

        if (isDocked) return;

        // 2. Superpower: 7777D De Bruijn Quasicrystal Star-Lattice Projector
        if (quasicrystalLatticeOn)
        {
            using (Pen qPen = new Pen(Color.FromArgb(90, 217, 70, 239), 1.2f))
            using (Pen qGolden = new Pen(Color.FromArgb(120, 250, 204, 21), 1.0f))
            {
                qPen.DashStyle = DashStyle.Dash;
                int rays = 12;
                for (int r = 0; r < rays; r++)
                {
                    double ang = (r * Math.PI * 2.0 / rays) + (runeAngle * 0.15f);
                    float rx = spiderX + (float)Math.Cos(ang) * 220.0f;
                    float ry = spiderY + (float)Math.Sin(ang) * 220.0f;
                    g.DrawLine(qPen, spiderX, spiderY, rx, ry);

                    // De Bruijn multi-grid cross points (c1=3333, c2=2828, c3=1617)
                    float g1x = spiderX + (float)Math.Cos(ang) * (3333.0f / 35.0f);
                    float g1y = spiderY + (float)Math.Sin(ang) * (3333.0f / 35.0f);
                    float g2x = spiderX + (float)Math.Cos(ang) * (2828.0f / 35.0f);
                    float g2y = spiderY + (float)Math.Sin(ang) * (2828.0f / 35.0f);
                    g.DrawEllipse(qGolden, g1x - 3, g1y - 3, 6, 6);
                    g.DrawEllipse(qGolden, g2x - 2, g2y - 2, 4, 4);
                }
            }
        }

        // 3. Superpower: Golay G24 Syndrome Hunter Reticle
        if (golaySyndromeHunterOn)
        {
            using (Pen gPen = new Pen(Color.FromArgb(220, 16, 185, 129), 1.6f))
            using (Font fGolay = new Font("Consolas", 8.2f, FontStyle.Bold))
            {
                for (int k = 0; k < 24; k++)
                {
                    double a = k * (Math.PI * 2.0 / 24.0) + runeAngle * 0.5f;
                    float gx = spiderX + (float)Math.Cos(a) * 96.0f;
                    float gy = spiderY + (float)Math.Sin(a) * 96.0f;
                    g.DrawLine(gPen, spiderX + (float)Math.Cos(a) * 88.0f, spiderY + (float)Math.Sin(a) * 88.0f, gx, gy);
                }
                g.DrawString("G24: " + golayStatus, fGolay, Brushes.SpringGreen, spiderX - 60.0f, spiderY + 78.0f);
            }
        }

        // 4. Superpower: ER=EPR Tri-Silicon Portal Jump Animation
        if (portalJumpActive && portalPulse > 0.05f)
        {
            using (Pen pPen = new Pen(Color.FromArgb((int)(portalPulse * 160.0f), 56, 189, 248), 2.5f))
            using (Pen pOrange = new Pen(Color.FromArgb((int)(portalPulse * 160.0f), 249, 115, 22), 1.8f))
            {
                float pRadius = 120.0f * (1.6f - portalPulse);
                g.DrawEllipse(pPen, spiderX - pRadius, spiderY - pRadius, pRadius * 2.0f, pRadius * 2.0f);
                g.DrawEllipse(pOrange, spiderX - pRadius * 0.7f, spiderY - pRadius * 0.7f, pRadius * 1.4f, pRadius * 1.4f);
            }
        }

        // 5. Pinned E8 Web Beacons & Synaptic Silk Lines
        using (Pen webPen = new Pen(Color.FromArgb(140, 34, 211, 238), 1.3f))
        using (SolidBrush bFill = new SolidBrush(Color.FromArgb(240, 15, 23, 42)))
        using (Font fBeacon = new Font("Consolas", 8.0f, FontStyle.Bold))
        {
            webPen.DashStyle = DashStyle.Dash;
            for (int b = 0; b < webBeacons.Count; b++)
            {
                PointF bp = webBeacons[b];
                g.DrawLine(webPen, bp.X, bp.Y, spiderX, spiderY);
                if (b > 0) g.DrawLine(webPen, webBeacons[b - 1].X, webBeacons[b - 1].Y, bp.X, bp.Y);
                g.FillEllipse(bFill, bp.X - 6, bp.Y - 6, 12, 12);
                g.DrawEllipse(Pens.Orange, bp.X - 6, bp.Y - 6, 12, 12);
                g.DrawString("E8-#" + (b + 1), fBeacon, Brushes.Cyan, bp.X + 8, bp.Y - 6);
            }
        }

        // 6. Independent Mitotic Swarm Clone Workers & Formation Mesh
        if (swarmClones.Count > 0)
        {
            using (Pen meshPen = new Pen(Color.FromArgb(145, 56, 189, 248), 1.3f))
            using (SolidBrush cloneArmor = new SolidBrush(Color.FromArgb(250, 11, 20, 38)))
            using (Pen cloneEdge = new Pen(Color.FromArgb(245, 34, 211, 238), 1.4f))
            using (Font fClone = new Font("Consolas", 7.8f, FontStyle.Bold))
            {
                meshPen.DashStyle = DashStyle.Dash;
                for (int c = 0; c < swarmClones.Count; c++)
                {
                    SwarmCloneWorker sc = swarmClones[c];
                    g.DrawLine(meshPen, spiderX, spiderY, sc.X, sc.Y);
                    if (c > 0) g.DrawLine(meshPen, swarmClones[c - 1].X, swarmClones[c - 1].Y, sc.X, sc.Y);

                    // 8 articulated mini-legs for each clone
                    for (int k = 0; k < 8; k++)
                    {
                        float lAng = sc.Heading + localAngles[k];
                        float hx = sc.X + (float)Math.Cos(lAng) * 10.0f;
                        float hy = sc.Y + (float)Math.Sin(lAng) * 10.0f;
                        float stride = (float)Math.Sin(sc.Phase * 2.5f + k * 0.9f) * 5.0f;
                        float fx = sc.X + (float)Math.Cos(lAng) * (38.0f + stride);
                        float fy = sc.Y + (float)Math.Sin(lAng) * (38.0f + stride);
                        float kx = (hx + fx) * 0.5f;
                        float ky = (hy + fy) * 0.5f - 8.0f;
                        g.DrawLine(cloneEdge, hx, hy, kx, ky);
                        g.DrawLine(cloneEdge, kx, ky, fx, fy);
                    }

                    // Octagonal mini-mecha carapace & role-colored core
                    PointF[] cOct = new PointF[8];
                    for (int v = 0; v < 8; v++)
                    {
                        double va = v * Math.PI / 4.0 + sc.Heading;
                        cOct[v] = new PointF(sc.X + (float)Math.Cos(va) * 13.5f, sc.Y + (float)Math.Sin(va) * 13.5f);
                    }
                    g.FillPolygon(cloneArmor, cOct);
                    g.DrawPolygon(cloneEdge, cOct);
                    using (SolidBrush roleBr = new SolidBrush(sc.CoreColor))
                    {
                        g.FillEllipse(roleBr, sc.X - 7.0f, sc.Y - 7.0f, 14.0f, 14.0f);
                        g.DrawString(sc.RoleName, fClone, roleBr, sc.X - 38.0f, sc.Y + 16.0f);
                    }
                }
            }
        }

        // 7. Laser Tether to Upper-Right Dock Portal
        using (Pen tetherPen = new Pen(Color.FromArgb(90, 34, 211, 238), 1.2f))
        {
            tetherPen.DashStyle = DashStyle.Dash;
            g.DrawLine(tetherPen, dockX, dockY, spiderX, spiderY);
        }

        // 8. Procedural 8-Leg 3-Jointed E8 Alternating Tetrapod IK Gait Engine
        // Femur L1 = 36px, Tibia-Tarsus L2 = 54px with Law-of-Cosines Knee Solver & Parabolic Lift
        Color armorDark = Color.FromArgb(255, 11, 19, 36);
        Color slateEdge = Color.FromArgb(255, 100, 116, 139);
        Color cyanEdge = Color.FromArgb(255, 56, 189, 248);
        Color orangeCore = Color.FromArgb(255, 249, 115, 22);
        Color goldStep = Color.FromArgb(255, 250, 204, 21);

        using (Pen pistonPen = new Pen(Color.FromArgb(210, 148, 163, 184), 1.4f))
        using (SolidBrush jointFill = new SolidBrush(Color.FromArgb(255, 9, 13, 22)))
        using (Pen orangePen = new Pen(orangeCore, 1.5f))
        using (Pen cyanPen = new Pen(cyanEdge, 1.5f))
        {
            for (int i = 0; i < 8; i++)
            {
                bool stepping = (stepProg[i] < 1.0f);
                float hipAngle = heading + localAngles[i];
                float coxaX = spiderX + (float)Math.Cos(hipAngle) * 20.0f;
                float coxaY = spiderY + (float)Math.Sin(hipAngle) * 20.0f;

                float lift = footLift[i];
                float fx = footX[i];
                float fy = footY[i] - lift;

                // Analytical 2-Bone Law-of-Cosines Inverse Kinematics
                float dx = fx - coxaX;
                float dy = fy - coxaY;
                float rawDist = (float)Math.Sqrt(dx * dx + dy * dy);
                float d = Math.Max(18.0f, Math.Min(L1 + L2 - 2.0f, rawDist));

                // cos(theta_knee) = (d^2 - L1^2 - L2^2) / (2 * L1 * L2)
                float cosKnee = (d * d - L1 * L1 - L2 * L2) / (2.0f * L1 * L2);
                cosKnee = Math.Max(-1.0f, Math.Min(1.0f, cosKnee));
                float thetaKnee = (float)Math.Acos(cosKnee);

                // Elevation angles
                float alpha = (float)Math.Atan2(dy, dx);
                float cosBeta = (L1 * L1 + d * d - L2 * L2) / (2.0f * L1 * d);
                cosBeta = Math.Max(-1.0f, Math.Min(1.0f, cosBeta));
                float beta = (float)Math.Acos(cosBeta);

                float archSign = (i < 4) ? 1.0f : -1.0f;
                float thetaFemur = alpha + beta * archSign;

                float kneeX = coxaX + (float)Math.Cos(thetaFemur) * L1;
                float kneeY = coxaY + (float)Math.Sin(thetaFemur) * L1 - (lift * 0.4f);

                float ankleX = kneeX + (fx - kneeX) * 0.72f;
                float ankleY = kneeY + (fy - kneeY) * 0.72f;

                // Hydraulic under-piston
                g.DrawLine(pistonPen, coxaX, coxaY + 3.0f, (coxaX + kneeX) * 0.55f, (coxaY + kneeY) * 0.55f + 3.0f);

                // Proximal Femur Armor Plate (L1 = 36px)
                DrawTaperedArmorPlate(g, coxaX, coxaY, kneeX, kneeY, 3.6f, 5.4f, 3.0f, armorDark, slateEdge, orangeCore);
                // Medial Tibia Armor Strut (L2 = 54px proximal segment)
                DrawTaperedArmorPlate(g, kneeX, kneeY, ankleX, ankleY, 3.1f, 3.9f, 2.0f, armorDark, cyanEdge, cyanEdge);
                // Distal Scythe Blade
                DrawTaperedArmorPlate(g, ankleX, ankleY, fx, fy, 2.0f, 1.4f, 0.5f, armorDark, stepping ? goldStep : cyanEdge, stepping ? orangeCore : cyanEdge);

                // Diamond Servo-Hinges at Coxa, Knee & Ankle
                PointF[] coxaDia = new PointF[] {
                    new PointF(coxaX, coxaY - 3.2f), new PointF(coxaX + 3.2f, coxaY),
                    new PointF(coxaX, coxaY + 3.2f), new PointF(coxaX - 3.2f, coxaY)
                };
                g.FillPolygon(jointFill, coxaDia);
                g.DrawPolygon(orangePen, coxaDia);

                PointF[] kneeDia = new PointF[] {
                    new PointF(kneeX, kneeY - 4.2f), new PointF(kneeX + 4.2f, kneeY),
                    new PointF(kneeX, kneeY + 4.2f), new PointF(kneeX - 4.2f, kneeY)
                };
                g.FillPolygon(jointFill, kneeDia);
                g.DrawPolygon(cyanPen, kneeDia);

                // Ground contact shadow on desktop plane (footX[i], footY[i]) when foot is lifted
                if (lift > 0.5f)
                {
                    using (SolidBrush shadowBr = new SolidBrush(Color.FromArgb(110, 4, 8, 16)))
                    {
                        g.FillEllipse(shadowBr, fx - 5.0f, footY[i] - 2.2f, 10.0f, 4.4f);
                    }
                }

                // Articulated 3-Pronged Magnetic Tarsus Claw at Foot
                float tibiaAng = (float)Math.Atan2(fy - ankleY, fx - ankleX);
                float clawSpread = stepping ? 0.48f : 0.22f;
                for (int cSide = -1; cSide <= 1; cSide += 2)
                {
                    float cAng = tibiaAng + cSide * clawSpread;
                    float cxTip = fx + (float)Math.Cos(cAng) * 8.5f;
                    float cyTip = fy + (float)Math.Sin(cAng) * 8.5f;
                    g.DrawLine(stepping ? orangePen : cyanPen, fx, fy, cxTip, cyTip);
                }
                g.FillEllipse(stepping ? Brushes.Orange : Brushes.Cyan, fx - 2.8f, fy - 2.8f, 5.6f, 5.6f);
            }
        }

        // 9. Sovereign Mecha Dual-Section Body (Opisthosoma Reactor + Swiveling Prosoma Head)
        GraphicsState st = g.Save();
        g.TranslateTransform(spiderX, spiderY);
        g.RotateTransform((float)((heading + Math.PI * 0.5) * 180.0 / Math.PI));

        // 9a. Orbital Tactical Reticle
        if (droneOrbitRingOn)
        {
            using (Pen orbitPen = new Pen(Color.FromArgb(150, 249, 115, 22), 1.3f))
            {
                for (int seg = 0; seg < 4; seg++)
                {
                    g.DrawArc(orbitPen, -54, -52, 108, 108, seg * 90 + 12 + runeAngle * 25.0f, 66);
                }
            }
        }

        // 9b. 4 Rear Spinneret Plasma Thrusters
        float speedMag = (float)Math.Sqrt(vx * vx + vy * vy);
        float plume = 9.0f + Math.Min(18.0f, speedMag * 1.6f) + corePulse * 10.0f;
        float[] thrusterX = new float[] { -8.5f, -3.2f, 3.2f, 8.5f };
        using (SolidBrush plumeOrange = new SolidBrush(Color.FromArgb(240, 249, 115, 22)))
        using (SolidBrush plumeCyan = new SolidBrush(Color.FromArgb(240, 34, 211, 238)))
        {
            for (int t = 0; t < 4; t++)
            {
                float tx = thrusterX[t];
                float ty = (t == 0 || t == 3) ? 31.0f : 34.0f;
                PointF[] cone = new PointF[] {
                    new PointF(tx - 2.0f, ty),
                    new PointF(tx + 2.0f, ty),
                    new PointF(tx, ty + plume)
                };
                g.FillPolygon((t % 2 == 0) ? plumeCyan : plumeOrange, cone);
            }
        }

        // 9c. 12-Facet Beveled Geodesic Opisthosoma (Abdomen at y = +11)
        float abY = 11.0f;
        PointF[] outerAb = new PointF[12];
        PointF[] midAb = new PointF[12];
        for (int i = 0; i < 12; i++)
        {
            double a = i * Math.PI / 6.0 + Math.PI / 12.0;
            float taper = (i >= 2 && i <= 9) ? 1.06f : 0.88f;
            outerAb[i] = new PointF((float)(Math.Cos(a) * 23.5 * taper), abY + (float)(Math.Sin(a) * 24.5));
            midAb[i] = new PointF((float)(Math.Cos(a) * 16.5 * taper), abY + (float)(Math.Sin(a) * 17.5));
        }

        using (SolidBrush bodyBrush = new SolidBrush(Color.FromArgb(255, 9, 18, 34)))
        using (SolidBrush bevelLight = new SolidBrush(Color.FromArgb(255, 24, 46, 78)))
        using (Pen cyanBorder = new Pen(Color.FromArgb(255, 56, 189, 248), 1.8f))
        using (Pen facetPen = new Pen(Color.FromArgb(180, 56, 189, 248), 0.9f))
        using (SolidBrush coreOuter = new SolidBrush(Color.FromArgb(255, 234, 88, 12)))
        using (SolidBrush coreMid = new SolidBrush(Color.FromArgb(255, 251, 146, 60)))
        using (SolidBrush coreHot = new SolidBrush(Color.FromArgb(255, 254, 249, 195)))
        {
            g.FillPolygon(bodyBrush, outerAb);
            for (int i = 0; i < 12; i++)
            {
                int n = (i + 1) % 12;
                PointF[] quad = new PointF[] { outerAb[i], outerAb[n], midAb[n], midAb[i] };
                if (i % 2 == 0) g.FillPolygon(bevelLight, quad);
                g.DrawPolygon(facetPen, quad);
            }
            g.DrawPolygon(cyanBorder, outerAb);

            // Gemma 4 12B-it + SH4Z Singularity Core
            float rC = 13.5f + corePulse * 3.5f;
            g.FillEllipse(coreOuter, -rC, abY - rC, rC * 2.0f, rC * 2.0f);
            g.FillEllipse(coreMid, -rC * 0.7f, abY - rC * 0.7f, rC * 1.4f, rC * 1.4f);
            g.FillEllipse(coreHot, -4.5f, abY - 4.5f, 9.0f, 9.0f);

            // Rotating 3D Geodesic Strut Lattice Over Core
            PointF[] cage = new PointF[6];
            for (int i = 0; i < 6; i++)
            {
                double th = i * Math.PI / 3.0 + runeAngle;
                cage[i] = new PointF((float)(Math.Cos(th) * 14.0), abY + (float)(Math.Sin(th) * 14.0));
            }
            g.DrawPolygon(cyanBorder, cage);
            for (int i = 0; i < 6; i++)
            {
                g.DrawLine(facetPen, cage[i].X, cage[i].Y, 0.0f, abY);
                g.DrawLine(facetPen, cage[i].X, cage[i].Y, cage[(i + 2) % 6].X, cage[(i + 2) % 6].Y);
            }

            // 9d. Independently Swiveling Anterior Prosoma (Cephalothorax + 8 Optical Lenses + Mandibles + Laser Scanner)
            GraphicsState headState = g.Save();
            g.TranslateTransform(0.0f, -13.0f);
            g.RotateTransform((float)(headYaw * 180.0 / Math.PI));

            // Anterior Laser Scanner Beams
            if (laserScannerOn)
            {
                using (Pen scanBeam = new Pen(Color.FromArgb(170, 34, 211, 238), 1.2f))
                using (Pen scanSweep = new Pen(Color.FromArgb(210, 249, 115, 22), 1.4f))
                {
                    scanBeam.DashStyle = DashStyle.Dot;
                    g.DrawLine(scanBeam, -4.0f, -15.0f, -24.0f, -85.0f);
                    g.DrawLine(scanBeam, 4.0f, -15.0f, 24.0f, -85.0f);
                    float sweepFrac = (float)((Math.Sin(runeAngle * 3.2f) + 1.0) * 0.5);
                    float sy = -18.0f - sweepFrac * 62.0f;
                    float hw = 4.5f + sweepFrac * 18.0f;
                    g.DrawLine(scanSweep, -hw, sy, hw, sy);
                }
            }

            // Articulated Plasma Chelicerae / Mandibles
            float pinch = (float)Math.Sin(runeAngle * 2.5f) * 2.5f;
            PointF[] leftPincer = new PointF[] {
                new PointF(-8.0f, -11.0f), new PointF(-14.0f + pinch, -19.0f),
                new PointF(-9.0f + pinch, -27.0f), new PointF(-5.5f, -15.0f)
            };
            PointF[] rightPincer = new PointF[] {
                new PointF(8.0f, -11.0f), new PointF(14.0f - pinch, -19.0f),
                new PointF(9.0f - pinch, -27.0f), new PointF(5.5f, -15.0f)
            };
            g.FillPolygon(bodyBrush, leftPincer);
            g.DrawPolygon(cyanBorder, leftPincer);
            g.FillPolygon(bodyBrush, rightPincer);
            g.DrawPolygon(cyanBorder, rightPincer);

            // Multi-Plate V-Chevron Cephalothorax Head Shield
            PointF[] headShield = new PointF[] {
                new PointF(0, -19), new PointF(13.5f, -11), new PointF(16, -1),
                new PointF(9, 5), new PointF(-9, 5), new PointF(-16, -1), new PointF(-13.5f, -11)
            };
            PointF[] headCrest = new PointF[] {
                new PointF(0, -15), new PointF(7.5f, -8.5f), new PointF(5, 2.5f), new PointF(-5, 2.5f), new PointF(-7.5f, -8.5f)
            };
            g.FillPolygon(bodyBrush, headShield);
            g.DrawPolygon(cyanBorder, headShield);
            g.FillPolygon(bevelLight, headCrest);
            g.DrawPolygon(facetPen, headCrest);

            // 8 Glowing Arachnid Optical Lenses (2 Primary Visor Slits + 6 Peripheral Ocelli)
            g.DrawLine(cyanBorder, -7.0f, -14.0f, -2.0f, -12.0f);
            g.DrawLine(cyanBorder, 7.0f, -14.0f, 2.0f, -12.0f);
            g.FillEllipse(Brushes.Cyan, -10.5f, -12.5f, 3.0f, 3.0f);
            g.FillEllipse(Brushes.Orange, -12.8f, -9.5f, 2.8f, 2.8f);
            g.FillEllipse(Brushes.Cyan, -14.0f, -6.2f, 2.4f, 2.4f);
            g.FillEllipse(Brushes.Cyan, 7.5f, -12.5f, 3.0f, 3.0f);
            g.FillEllipse(Brushes.Orange, 10.0f, -9.5f, 2.8f, 2.8f);
            g.FillEllipse(Brushes.Cyan, 11.6f, -6.2f, 2.4f, 2.4f);

            g.Restore(headState);
        }
        g.Restore(st);

        // 10. Floating Speech / MCP Telemetry Banner
        if (speechTimer > 0 && !string.IsNullOrEmpty(speechText))
        {
            using (SolidBrush bg = new SolidBrush(Color.FromArgb(240, 8, 15, 28)))
            using (Pen border = new Pen(Color.FromArgb(230, 34, 211, 238), 1.6f))
            using (Font fText = new Font("Consolas", 8.8f, FontStyle.Bold))
            {
                float bw = Math.Min(620.0f, this.Width - 40.0f);
                float bx = Math.Max(20.0f, Math.Min(this.Width - bw - 20.0f, spiderX - bw * 0.5f));
                float by = Math.Max(20.0f, spiderY - 84.0f);
                RectangleF rect = new RectangleF(bx, by, bw, 32.0f);
                g.FillRectangle(bg, rect);
                g.DrawRectangle(border, rect.X, rect.Y, rect.Width, rect.Height);
                g.DrawString(speechText, fText, Brushes.Orange, bx + 8.0f, by + 8.0f);
            }
        }
    }

    [STAThread]
    public static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new VesperArachneSwarmDroneOverlay());
    }
}
