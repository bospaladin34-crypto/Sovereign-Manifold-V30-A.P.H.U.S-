import React from "react";
import { TelemetryHud } from "./components/TelemetryHud";
import { InteractiveConsole } from "./components/InteractiveConsole";

export function App() {
  return (
    <div style={{ minHeight: "100vh", background: "#0E1116", color: "#FFFEFB", padding: "12px" }}>
      <TelemetryHud />
      <InteractiveConsole />
    </div>
  );
}
export default App;
