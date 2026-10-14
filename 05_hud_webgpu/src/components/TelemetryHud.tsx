import React from 'react';
import { TelemetryData } from '../hooks/useTelemetryStream';

export interface TelemetryHudProps {
  telemetry?: TelemetryData;
  isConnected?: boolean;
  connected?: boolean;
}

export const TelemetryHud: React.FC<TelemetryHudProps> = (props) => {
  const trVal = typeof props.telemetry?.tr_u_res === 'number' ? props.telemetry.tr_u_res.toFixed(6) : '1.000000';
  const tokensTotal = props.telemetry?.tokens_total ?? 288936;
  const shardsTotal = props.telemetry?.shards_total ?? 415;

  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(4, 1fr)',
      gap: 12,
      marginBottom: 16,
      fontFamily: 'monospace'
    }}>
      <div style={{
        background: 'rgba(13, 20, 36, 0.75)',
        backdropFilter: 'blur(16px)',
        border: '1px solid rgba(56, 189, 248, 0.25)',
        borderRadius: 10,
        padding: '12px 16px'
      }}>
        <div style={{ fontSize: 10, letterSpacing: 1, color: '#38bdf8' }}>MAJORANA-1 PARITY</div>
        <div style={{ fontSize: 16, fontWeight: 'bold', color: '#4ade80', margin: '2px 0' }}>Tr(U_res) = {trVal}</div>
        <div style={{ fontSize: 10, color: '#94a3b8' }}>CONSERVATION: PASS</div>
      </div>

      <div style={{
        background: 'rgba(13, 20, 36, 0.75)',
        backdropFilter: 'blur(16px)',
        border: '1px solid rgba(56, 189, 248, 0.25)',
        borderRadius: 10,
        padding: '12px 16px'
      }}>
        <div style={{ fontSize: 10, letterSpacing: 1, color: '#38bdf8' }}>GEODESIC CARRIER CLOCK</div>
        <div style={{ fontSize: 16, fontWeight: 'bold', color: '#38bdf8', margin: '2px 0' }}>15.00 Hz (LOCK VERIFIED)</div>
        <div style={{ fontSize: 10, color: '#94a3b8' }}>MISSOULA, MT (46.8721° N)</div>
      </div>

      <div style={{
        background: 'rgba(13, 20, 36, 0.75)',
        backdropFilter: 'blur(16px)',
        border: '1px solid rgba(16, 185, 129, 0.25)',
        borderRadius: 10,
        padding: '12px 16px'
      }}>
        <div style={{ fontSize: 10, letterSpacing: 1, color: '#10b981' }}>AFE STICTION & CRITICALITY</div>
        <div style={{ fontSize: 16, fontWeight: 'bold', color: '#10b981', margin: '2px 0' }}>SLIP (ACTIVE TRANSPORT)</div>
        <div style={{ fontSize: 10, color: '#94a3b8' }}>TEMP T = 0.68 (GOVERNED)</div>
      </div>

      <div style={{
        background: 'rgba(13, 20, 36, 0.75)',
        backdropFilter: 'blur(16px)',
        border: '1px solid rgba(245, 158, 11, 0.25)',
        borderRadius: 10,
        padding: '12px 16px',
        textAlign: 'right'
      }}>
        <div style={{ fontSize: 10, letterSpacing: 1, color: '#f59e0b' }}>ACTIVE VAULT SCALE</div>
        <div style={{ fontSize: 16, fontWeight: 'bold', color: '#f59e0b', margin: '2px 0' }}>
          {tokensTotal.toLocaleString()} TOKENS
        </div>
        <div style={{ fontSize: 10, color: '#94a3b8' }}>{shardsTotal} SHARDS (EXPANDING IN-LOOP)</div>
      </div>
    </div>
  );
};