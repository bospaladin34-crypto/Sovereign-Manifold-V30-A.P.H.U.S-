// ACT-OMEGA SOVEREIGN MANIFOLD v56.0.0 F4SE CONNECTOME BRIDGE
// 1440 Chair-44 Columns x 44 Neurons = 63360 Neurons
#pragma once

extern "C" {
  bool F4SEPlugin_Query(void* f4se, void* info);
  bool F4SEPlugin_Load(void* f4se);
  unsigned int GetChair44ColumnActivation(void* tag, unsigned int columnId);
  float GetNeuronWeight(void* tag, unsigned int neuronId, unsigned int synapseIdx);
}
