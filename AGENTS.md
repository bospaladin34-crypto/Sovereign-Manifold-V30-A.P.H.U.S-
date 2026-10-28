# ACT-Omega Net v50.0.0 (SH4Z v5000 TLV | CHAIN 135) — Multi-Agent Roster & Standing Constraints (`AGENTS.md`)

- **Zenodo Permanent DOI**: `10.5281/zenodo.23651696` (https://doi.org/10.5281/zenodo.23651696)
- **OSF Permanent DOI**: `10.17605/OSF.IO/2XQ5Z` (https://osf.io/2xq5z/overview)

## Standing Global Constraint (Applies to Parent Agent & All Subagents)
> **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."**

Every agent operating in `C:\sovereign_manifold_v31` must enforce this constraint before any code edit, build, or commit:
1. **Zero Hardcoded Telemetry or Metrics**: Every telemetry field, loss, perplexity, acceptance rate, attention score, temperature, clock speed, byte size, and token count must be genuinely measured from hardware/OS probes, filesystem metadata, or computed directly from on-disk weight tensors and live input vectors.
2. **Zero Clamped Floors / Synthetic Formulas**: Never use `.max(...)` or `.min(...)` to artificially force a metric into a target range or fabricate convergence (e.g., never clamp perplexity to `1.000000008`).
3. **Zero Hardcoded Digests**: All SHA-256 and FNV-1a digests must be computed over actual file bytes on disk or via WebCrypto/D1 audit rows.
4. **Zero Unauthenticated Admin Endpoints**: Any administrative or lifecycle endpoint must require strict loopback origin verification and authenticated secret validation (`ACT_OMEGA_OPERATOR_SECRET` / `03_vault/connectome/operator_vault_secret.key`).
5. **Real Failure Thresholds in All Audits**: Every self-profiler, lifecycle verifier, and edge audit must evaluate concrete pass/fail thresholds and report `DEGRADED`/`FAILED` when a threshold is violated.
