/**

Author: Charles Sanders
Date: 2006.4.28


NeuralNetwork module.

This class contains mostly just the architecure for the neuralnetwork.  Its main purpose is to provide an interface for the ILearning class to manipulate.  You'll notice its only real job is to randomize the weights.

*/

module and.network.neuralnetwork;

import mt;

private import and.network.neuron;
private import and.network.model.ineuralnetwork;
private import and.network.layer;
private import and.activation.model.iactivation;
private import and.activation.sigmoid;
private import and.platform;

 /** NeuralNetwork class serves mainly as the architecture */
class NeuralNetwork : INeuralNetwork
{

  Layer input;
  Layer [] hidden;
  Layer output;
  

  

  real r_min = -0.5; /// the min random value
  real r_max = 0.5; /// the max random value



  /**
     Parameters: numberOfInputs, numberOfHidden, numberOfOutputs, activationFunction, learningRate, skipRandomizingWeights ( for loading )
  */
  this ( Layer input , Layer [] hidden, Layer output, bool skipRandom = false ) 
  in
  {
    assert(input !is null);
    assert(hidden.length);
    assert(output !is null );
  }
  body 
  {
    this.input = input;
    this.hidden = hidden;
    this.output  = output;

    int lastNeuronCount = 0;

    debug // assert that the neurons and synapse count is correct
    {
      foreach ( Layer l;hidden )
      {
	if ( lastNeuronCount == 0 ) 
	  {
	    // then check current layer against input layer
	    assert(input.neurons.length == l.neurons[0].synapses.length );

	    lastNeuronCount = l.neurons.length;
	    continue;
	  }
	writefln("%d %d",l.neurons[0].synapses.length,lastNeuronCount);
	assert(l.neurons[0].synapses.length == lastNeuronCount );

	lastNeuronCount = l.neurons.length;

      }

      assert(hidden[$-1].neurons.length == output.neurons[0].synapses.length );
    }

    if ( !skipRandom ) randomizeWeights();
  }


  
  void randomizeWeights()  /// randomizes the hidden and output layer's synapses
  {


    foreach ( int currentLayer, Layer l;hidden )
      {

	foreach (int currentNeuron, /+inout+/ Neuron nh;l.neurons )
	  {

	    for ( int i = 0 ; i < nh.synapses.length; i++ )
	      {

		real w = genrand_range!(real)(r_min,r_max ,true);
		debug writefln("Randomizing Layer [ %d ] Neuron [ %d ] Synapse  [ %d ]  with [ %f ]",currentLayer,currentNeuron,i,w );
		nh.synapses[i] = w;
		nh.lastWeightChange[i] = 0;
	      }
	    nh.bias = genrand_range!(real)(r_min,r_max ,true);
	    debug writefln("Randomizing Layer [ %d ] Neuron [ %d ] Bias with [ %f ]",currentLayer,currentNeuron,nh.bias );

	  }
      }

    foreach ( Neuron no;output.neurons )
      {

	for ( int i = 0 ; i < no.synapses.length; i++ )
	  {
	    real w = genrand_range!(real)(r_min,r_max );
	    debug writefln("Randomizing Output weight [ %d ] with [ %f ]",i,w );
	    no.synapses[i] = w;
	    no.lastWeightChange[i] = 0;
	  }

	  no.bias = genrand_range!(real)(r_min,r_max );

      }


  }


}
