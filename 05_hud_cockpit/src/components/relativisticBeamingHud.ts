// 05_hud_webgpu/src/components/relativisticBeamingHud.ts
// v30 Track 5: 60 FPS WebGPU Cockpit HUD Event Horizon Shadow & Relativistic Beaming Shader Math

export interface HorizonTelemetryHud {
  schwarzschildRadiusRs: number;
  photonRingRadiusRph: number;
  criticalShadowRadiusBc: number;
  lorentzGamma: number;
  beamingContrastRatio: number;
}

export function computeRelativisticDopplerGain(thetaRad: number, beta: number = 0.50): number {
  const b = Math.min(Math.max(beta, 0.0), 0.99);
  const gamma = 1.0 / Math.sqrt(1.0 - b * b);
  const doppler = 1.0 / (gamma * (1.0 - b * Math.cos(thetaRad)));
  return doppler * doppler * doppler;
}

export function computeHorizonShadowMetrics(rs: number = 1.0, beta: number = 0.50): HorizonTelemetryHud {
  const b = Math.min(Math.max(beta, 0.0), 0.99);
  const lorentzGamma = 1.0 / Math.sqrt(1.0 - b * b);
  const photonRingRadiusRph = 1.5 * rs;
  const criticalShadowRadiusBc = 1.5 * Math.sqrt(3.0) * rs;
  const ratio = (1.0 + b) / (1.0 - b);
  const beamingContrastRatio = ratio * ratio * ratio;
  return {
    schwarzschildRadiusRs: rs,
    photonRingRadiusRph,
    criticalShadowRadiusBc,
    lorentzGamma,
    beamingContrastRatio,
  };
}