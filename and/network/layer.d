/**

Author: Charles Sanders
Date: 2006.4.28


Layer, abstracts out input, hidden and output layers

*/


module and.network.layer;


private import and.network.model.ilayer;
private import and.activation.model.iactivation;
private import and.network.neuron;

/** Class to abstract out a layer of neurons, input, hidden ,and output layers */
class Layer : ILayer
{
  
  Neuron [] neurons; /// Neurons in the layer
  IActivationFunction activationFunction; /// activation function for the layer

  /** Parameters: number of neurons in layer, number of synapses ( this is number of neurons to previous layer ), and activation function */
  this ( int neuronCount, int synapseCount ,IActivationFunction f = null)
  {
    activationFunction = f;
    for ( int i = 0 ; i < neuronCount; i ++ )
      {
	Neuron n = new Neuron;
	neurons ~= n;
	n.synapses.length = synapseCount;
	n.lastWeightChange.length = synapseCount;
      }


  }


}
