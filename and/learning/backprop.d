/**

Author: Charles Sanders
Date: 2006.4.28


The Backward Error Propagation ILearningFunction implementation

*/
module and.learning.backprop;

private import and.learning.model.ilearning;
private import and.network.neuralnetwork;
private import and.network.layer;
private import and.network.neuron;
private import and.platform;
private import and.util;
private import and.cost.model.icostfunction;


/**
   The learning function is the main worker class of the library.  It trains the network and computes the output.

*/
class BackPropagation : ILearningFunction
{

  NeuralNetwork neuralNetwork; /// The network to train
  CostFunction costFunction;
  

  real errorThreshold = 0.001;
  real learningRate = 0.1;  /// the learning rate ( common values are 0.05 <= n <= 0.75 )
  real momentum = 0.2; /// the momemtum, this is a fraction of the previous weight change, 0 <= a <= 0.9
  int epochs = 100_000; /// max iterations for training
  uint actualEpochs = 0; /// the total epochs 
  uint callBackEpochs = 1; /// when to call the progress callback
  real [] lastWeightChange; /// a record of changes in weights for momemtum
  trainingProgressCallback progressCallback;

  /**
     Parameters: a NeuralNetwork instance

  */

  this ( NeuralNetwork n , CostFunction c) 
  {
    neuralNetwork = n;
    costFunction = c;
  }

  void setProgressCallback( trainingProgressCallback p , uint callBackEpochs )
  {

    progressCallback = p;
    this.callBackEpochs = callBackEpochs;


  }

  /**
     Parameters: an array of inputs to the network

  */

void feedForward ( real [] inputs) {

    

	real sum = 0;
	int lastHiddenLayer = neuralNetwork.hidden.length - 1;

	foreach ( int currentLayer, Layer l; neuralNetwork.hidden )
	{

		foreach ( int currentNeuron, /+inout+/ Neuron nh; l.neurons )
		{

			sum = 0;

			foreach ( int i , real inp;inputs )
			{
				sum += inp * nh.synapses[i];
			}

			sum += nh.bias;
			nh.value = l.activationFunction.f(sum);

		}

	}

	foreach ( int currentNeuron, /+inout+/ Neuron no;neuralNetwork.output.neurons )
	{

		sum = 0;


		for ( int i = 0 ; i < no.synapses.length;i++ )
		{
			sum += neuralNetwork.hidden[lastHiddenLayer].neurons[i].value * no.synapses[i];

		}

		sum += no.bias;

		no.value = neuralNetwork.output.activationFunction.f(sum);
	
	}




   }

  /**
     Parameters: the inputs to the network

  */
  private void updateWeights(real [] inputs ) /// Parameters: the inputs to the network
  {

		Layer [] tempLayers = neuralNetwork.hidden;
		tempLayers ~= neuralNetwork.output;

		// Udpate all layers except the first hidden

	for ( int layerCount = tempLayers.length - 1;layerCount > 0;layerCount-- )
	{

		Layer outerLayer = tempLayers[layerCount];
		Layer innerLayer = tempLayers[layerCount-1];

		foreach ( /+inout+/ Neuron outerNeuron;outerLayer.neurons )
		{

			foreach ( int i , /+inout+/ Neuron innerNeuron;innerLayer.neurons )
			{
				real value = ( learningRate * outerNeuron.error * innerNeuron.value );
				/+++/assert(!isNaN(value));
				/+++/assert(!isNaN(outerNeuron.lastWeightChange[i]));
				/+++/assert(!isNaN(momentum));
				value += momentum * outerNeuron.lastWeightChange[i];
				/+++/assert(!isNaN(value));
				
				outerNeuron.lastWeightChange[i] = value;
				outerNeuron.synapses[i] +=  value;

			}
		real biasValue = ( learningRate * outerNeuron.error );
		biasValue += momentum * outerNeuron.lastBiasChange;

		outerNeuron.lastBiasChange = biasValue;
		outerNeuron.bias  += biasValue;

		}
	}

    
    //    Update the first hidden layer;

		foreach ( /+inout+/ Neuron nh;neuralNetwork.hidden[0].neurons )
		{
			foreach ( int i , real input;inputs )
			{
				real value = ( learningRate * nh.error * input );
				/+++/assert(!isNaN(nh.error));
				/+++/assert(!isNaN(input));
				/+++/assert(!isNaN(value));
				value += momentum * nh.lastWeightChange[i];
				/+++/assert(!isNaN(nh.lastWeightChange[i]));
				/+++/assert(!isNaN(value));

				nh.lastWeightChange[i] = value;
				nh.synapses[i] += value;


			}

		real biasValue = ( learningRate * nh.error );
		biasValue += momentum * nh.lastBiasChange;
		/+++/assert(!isNaN(biasValue));

		nh.lastBiasChange = biasValue;
		nh.bias += biasValue;

		}



   }

  /**
     Parameters: the inputs to the network, the expected output you want it to have

  */
  

	void backPropogate(real [] inputs, real [] expected)
	{

		  // calculate the output layer errors first
		foreach ( int i , /+inout+/ Neuron no; neuralNetwork.output.neurons )
		{
			no.error = 0;

			no.error = ( expected[i] - no.value ) * neuralNetwork.output.activationFunction.fDerivative(no.value );
			/+++/assert(!isNaN(no.error));
		}
		  
		  //now calculate error for all hidden layers 
		  
		Layer operatingLayer;
		  
		int lastHiddenLayer = neuralNetwork.hidden.length - 1;

		for ( int currentHiddenLayer = lastHiddenLayer; currentHiddenLayer >= 0;currentHiddenLayer-- )
		{
			if ( currentHiddenLayer == lastHiddenLayer ) operatingLayer = neuralNetwork.output;
			else operatingLayer = neuralNetwork.hidden[currentHiddenLayer+1];


			foreach ( int currentSynapse, /+inout+/ Neuron nh;neuralNetwork.hidden[currentHiddenLayer].neurons)
			{

				nh.error = 0;
				foreach ( int currentNeuron , Neuron nhInner;operatingLayer.neurons )
				{
			 
					nh.error += nhInner.error * nhInner.synapses[currentSynapse];
					/+++/assert(!isNaN(nh.error));
				}

				nh.error *= operatingLayer.activationFunction.fDerivative(nh.value );
				/+++/assert(!isNaN(nh.error));
			}
		}

		  

			updateWeights(inputs);

	}


	  /**
		  Parameters: 2d array of inputs, 2d array of expected outputs

		  This will loop through all the inputs you give it for NeuralNetwork.epochs ( 10,000 by default ) or until the error limit is reached.

	  */


	void train (real [] [] inputs , real [] [] expectedOutputs ) {
		 
		assert(inputs.length );
		assert(expectedOutputs.length );
		assert(inputs.length == expectedOutputs.length );
		assert(inputs[0].length == neuralNetwork.input.neurons.length );
		assert(expectedOutputs[0].length == neuralNetwork.output.neurons.length );

		int patternCount = 0;
		real error = 0;
		
		while ( 1 )
		{
			error = 0;
			feedForward(inputs[patternCount] );
			backPropogate(inputs[patternCount],expectedOutputs[patternCount] );

			real [] actual;
			foreach ( int nCount, Neuron no;neuralNetwork.output.neurons)
			{
				actual ~= no.value;
				//error += (expectedOutputs[patternCount][nCount] - no.value ) * (expectedOutputs[patternCount][nCount] - no.value );

			}
			error = costFunction.f(expectedOutputs[patternCount],actual );
			/+++/assert(!isNaN(error));
			
			

			patternCount++;
			debug 
			{
				writef("Iterations [ %d ] Error [ ",actualEpochs  );
				for ( int i = 0 ; i < neuralNetwork.output.neurons.length; i++ )
				{
					writef(" %f ",neuralNetwork.output.neurons[i].error );
				}
				writefln(" ] Cost [ %f ]",error);
			}
				 
			if ( patternCount >= inputs.length ) patternCount = 0;

			if ( actualEpochs % callBackEpochs == 0 ) 
			{
				if ( progressCallback !is null )
				{
					progressCallback( actualEpochs, error );
				}
			}

			if ( ++actualEpochs >= epochs ) break;
			if ( error <= this.errorThreshold ) break; // need to move this into a function

		}
		 

		 
	}

	  /**
		  Parameters: array of inputs to the network

		  this function is used after you 

	  */


	real [] computeOutput( real [] inputs) 
	{

		real [] ret;

		feedForward(inputs);
		 
		foreach ( Neuron n; neuralNetwork.output.neurons )
		{

			ret ~= n.value;

		}

		return ret;

	}



}

