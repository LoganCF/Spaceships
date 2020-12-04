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

import std.parallelism;




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

    
	assert (inputs.length == neuralNetwork.input.neurons.length);
	real sum = 0;
	int lastHiddenLayer = neuralNetwork.hidden.length - 1;
	
	foreach ( int currentNeuron, Neuron nh; neuralNetwork.hidden[0].neurons)
	{

		sum = 0;

		foreach ( int i , real inp;inputs )
		{
			debug real sum_before = sum;	

			//TODO: would this be faster with parralel reduce?
			sum += inp * nh.synapses[i];
			
			debug {
				if( isNaN(sum) )
				{
					writefln("RAW INPUT\n%(%a %)\n", inputs);
					writefln("INPUT\n%(%f %)\n", inputs);
					writefln("%a, %a", inp, nh.synapses[i]);
					writefln("neuron input is NaN. Layer = 0, neuron#: %d, input value = %f, synapse = %f, synapse#: %d, value*synapse: %f, sum before = %f"
					, currentNeuron, inp, nh.synapses[i], i, inp * nh.synapses[i], sum_before);
					assert(false);
				}
			}
		}

		sum += nh.bias;
		nh.value = neuralNetwork.hidden[0].activationFunction.f(sum);
		debug {
			if( isNaN(nh.value) )
			{
				writeln("neuron output is NaN. Layer = 0" ~ ", neuron#: " ~to!string(currentNeuron));
			}
		}

	}
		
	Layer prev_layer = neuralNetwork.hidden[0];

	foreach ( int currentLayer, Layer l; neuralNetwork.hidden[1..$] )
	{
		
		foreach ( int currentNeuron, /+inout+/ Neuron nh; l.neurons )
		{

			sum = 0;

			foreach ( int i , Neuron prev_neuron; prev_layer.neurons )
			{
				debug real sum_before = sum;
				//writefln("neurons in prev_layer: %d, num synapses: %d, synapse#: %d", prev_layer.neurons.length, nh.synapses.length, i);
				
				debug 
				{
					if( isNaN(prev_neuron.value)) writefln("prev neuron is nan: %a", prev_neuron.value);
					if( isNaN(nh.synapses[i])) writefln("synapse is nan: %a", nh.synapses[i]);
				}
				sum += prev_neuron.value * nh.synapses[i];
				
				debug {
					if( isNaN(sum) )
					{
						writefln("%(%a %)", inputs);
						writefln("%a, %a", prev_neuron.value, nh.synapses[i]);
						writefln("neuron input is NaN. Layer = %d, neuron#: %d, input value = %f, synapse = %f, synapse#: %d, value*synapse: %f, sum before = %f"
						, currentLayer, currentNeuron, prev_neuron.value, nh.synapses[i], i, prev_neuron.value * nh.synapses[i], sum_before);
						assert(false);
					}
				}
			}

			sum += nh.bias;
			nh.value = l.activationFunction.f(sum);
			debug {
				if( isNaN(nh.value) )
				{
					writeln("neuron output is NaN. Layer = " ~ to!string(currentLayer) ~", neuron#: " ~to!string(currentNeuron));
				}
			}

		}
		prev_layer = l;

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
	
		/*if(no.value >1.0)//debug
		{
			write("double wtf all across the sky.");
		}*/
	}

 }
   
   
   
   
   /+ WIP
   void feedForwardParralel ( real [] inputs) {

    
	assert (inputs.length == neuralNetwork.input.neurons.length);
	real sum = 0;
	int lastHiddenLayer = neuralNetwork.hidden.length - 1;
	
	foreach ( int currentNeuron, Neuron nh; neuralNetwork.hidden[0].neurons)
	{

		sum = taskPool.reduce!"a+b"(0.0, zip(inputs, nh.synapses).map!"a[0] * a[1]")
		

		sum += nh.bias;
		nh.value = neuralNetwork.hidden[0].activationFunction.f(sum);
		debug {
			if( isNaN(nh.value) )
			{
				writeln("neuron output is NaN. Layer = 0" ~ ", neuron#: " ~to!string(currentNeuron));
			}
		}

	}
	/////////////// vvv not changed yet vvv
		
	Layer prev_layer = neuralNetwork.hidden[0];

	foreach ( int currentLayer, Layer l; neuralNetwork.hidden[1..$] )
	{
		
		foreach ( int currentNeuron, /+inout+/ Neuron nh; l.neurons )
		{

			sum = 0;

			foreach ( int i , Neuron prev_neuron; prev_layer.neurons )
			{
				debug real sum_before = sum;
				//writefln("neurons in prev_layer: %d, num synapses: %d, synapse#: %d", prev_layer.neurons.length, nh.synapses.length, i);
				
				debug 
				{
					if( isNaN(prev_neuron.value)) writefln("prev neuron is nan: %a", prev_neuron.value);
					if( isNaN(nh.synapses[i])) writefln("synapse is nan: %a", nh.synapses[i]);
				}
				sum += prev_neuron.value * nh.synapses[i];
				
				debug {
					if( isNaN(sum) )
					{
						writefln("%(%a %)", inputs);
						writefln("%a, %a", prev_neuron.value, nh.synapses[i]);
						writefln("neuron input is NaN. Layer = %d, neuron#: %d, input value = %f, synapse = %f, synapse#: %d, value*synapse: %f, sum before = %f"
						, currentLayer, currentNeuron, prev_neuron.value, nh.synapses[i], i, prev_neuron.value * nh.synapses[i], sum_before);
						assert(false);
					}
				}
			}

			sum += nh.bias;
			nh.value = l.activationFunction.f(sum);
			debug {
				if( isNaN(nh.value) )
				{
					writeln("neuron output is NaN. Layer = " ~ to!string(currentLayer) ~", neuron#: " ~to!string(currentNeuron));
				}
			}

		}
		prev_layer = l;

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
	
		/*if(no.value >1.0)//debug
		{
			write("double wtf all across the sky.");
		}*/
	}

}+/

  /**
     Parameters: the inputs to the network

  */
  void updateWeights(real [] inputs ) /// Parameters: the inputs to the network
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
				/+++/debug assert(!isNaN(value));
				/+++/debug assert(!isNaN(outerNeuron.lastWeightChange[i]));
				/+++/debug assert(!isNaN(momentum));
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
				/+++/debug assert(!isNaN(nh.error));
				/+++/debug assert(!isNaN(input));
				/+++/debug assert(!isNaN(value));
				value += momentum * nh.lastWeightChange[i];
				/+++/debug assert(!isNaN(nh.lastWeightChange[i]));
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

			/+ error = derivative of SSE * derivative of activation function +/
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
		real total_abs_error = 0; /+++/
		real last_error = 0.0; /+++/
		real largest_error = 0.0; /+++/
		real last_largest_error = 0.0; /+++/
		
		actualEpochs = 0;
		
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
			/+++/total_abs_error += abs(error);
			/+++/if (abs(error) > largest_error)
				/+++/largest_error = abs(error);
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
				 
			

			if ( actualEpochs % callBackEpochs == 0 ) 
			{
				if ( progressCallback !is null )
				{
					progressCallback( actualEpochs, error, 0, 0 );
				}
			}
			
			/+++/ // except conditional and patternCount = 0;
			if ( patternCount >= inputs.length ) 
			{
				real avg_err = total_abs_error / patternCount;
				if(last_error == 0.0) last_error = avg_err;
				if(last_largest_error == 0.0) last_largest_error = largest_error;
				writefln("Average Error: % 7f (%+7f)    Largest Error: % 7f (%+7f)", avg_err, avg_err - last_error, largest_error, largest_error - last_largest_error);
				last_error = avg_err;
				last_largest_error = largest_error;
				largest_error = 0.0;
				// if average error is small enough, we're done!
				if(total_abs_error / patternCount <= this.errorThreshold)
				{
					break;
				}
				
				//otherwise, start at the beginning.
				patternCount = 0;
				total_abs_error = 0;
			}

			if ( ++actualEpochs >= epochs ) break;
			//if ( error <= this.errorThreshold ) break; // need to move this into a function

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
	
	real [] lastOutput()
	{
		real [] ret;
		 
		foreach ( Neuron n; neuralNetwork.output.neurons )
		{

			ret ~= n.value;

		}

		return ret;
	}



}

