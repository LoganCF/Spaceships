/**

Author: Logan Freesh
Date: 2017.1.18

*/
module and.learning.backprop_mod_reinforcement;

private import and.learning.model.ilearning;
private import and.learning.backprop;
private import and.network.neuralnetwork;
private import and.network.layer;
private import and.network.neuron;
private import and.platform;
private import and.util;
private import and.cost.model.icostfunction;


/**
   This is a learning function that preforms a modfied version of Reinforcement Learning.
   This version has multiple output neurons, each representing the projected reward some time in the future after making the choice corresponding to that output neuron.
   We train the network ex-post-facto, so we don't have to use Temporal Difference learning to guess at the actual reward.
   We train only the output neuron that was selected (as that action was actually taken and we have the real value to compare to our projection).
*/

class ModifiedReinforcementBackPropagation : BackPropagation 
{
	this ( NeuralNetwork n , CostFunction c) 
	{
		super(n, c);
	}

	void backPropogate(real [] inputs, real expected, int output_neuron_num)
	{
		write( output_neuron_num, " ");
		  // calculate the output layer errors first
		foreach ( int i , /+inout+/ Neuron no; neuralNetwork.output.neurons )
		{
			if(i == output_neuron_num)
			{
				//error = derivative of SSE * derivative of output activation function 
				no.error = ( expected - no.value ) * neuralNetwork.output.activationFunction.fDerivative(no.value );
			} else {
				no.error = 0;
			}
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


	void train (real [] [] inputs , real [] expectedOutputs, int [] output_neuron_numbers  ) {
		 
		assert(inputs.length );
		assert(expectedOutputs.length );
		assert(inputs.length == expectedOutputs.length );
		assert(inputs[0].length == neuralNetwork.input.neurons.length );

		int patternCount = 0;
		real error = 0;
		
		while ( 1 )
		{
			error = 0;
			feedForward(inputs[patternCount] );
			backPropogate(inputs[patternCount],expectedOutputs[patternCount], output_neuron_numbers[patternCount] );

			/+real [] actual;
			foreach ( int nCount, Neuron no;neuralNetwork.output.neurons)
			{
				actual ~= no.value;
				//error += (expectedOutputs[patternCount][nCount] - no.value ) * (expectedOutputs[patternCount][nCount] - no.value );

			}
			error = costFunction.f(expectedOutputs[patternCount],actual );
			/+++/assert(!isNaN(error));
			+/
			error = expectedOutputs[patternCount] - neuralNetwork.output.neurons[output_neuron_numbers[patternCount]].value;
			

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
			//if ( error <= this.errorThreshold ) break; // negative error is PERFECTLY NORMAL when doing value prediction, like we do for reinforcement learning.
			//  really, I could also make it display SSE, becasue I'm using its derivative in the computation anyway, but displaying raw error is more informative in this context.

		}
		 

		 
	}
	
}