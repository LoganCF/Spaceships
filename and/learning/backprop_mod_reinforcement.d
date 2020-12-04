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
	
	static const real error_clamp = 5.0;

	void backPropogate(real [] inputs, real expected, int output_neuron_num)
	{
		//write( output_neuron_num, " ");
		  // calculate the output layer errors first
		foreach ( int i , /+inout+/ Neuron no; neuralNetwork.output.neurons )
		{
			if(i == output_neuron_num)
			{
				//error = derivative of SSE * derivative of output activation function 
				no.error = ( expected - no.value ) * neuralNetwork.output.activationFunction.fDerivative(no.value );
				if (isNaN(no.error) )
				{
					writefln("actual: %f, predicted: %f, deriv: %f, epoch: %d",expected, no.value, neuralNetwork.output.activationFunction.fDerivative(no.value ), actualEpochs);
				}
				// head off some ReLU nonsense
				if (no.error > error_clamp)  no.error = error_clamp;
				if (no.error < -error_clamp) no.error = -error_clamp;
				//debug
				/+
				if(neuralNetwork.output.activationFunction.fDerivative(no.value ) < 0.01)
				{
					writefln("expected is: %f, val is %f, derivative is %f",expected,no.value, neuralNetwork.output.activationFunction.fDerivative(no.value ));
				}
				+/
			} else {
				no.error = 0.0;
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
					if (isNaN(nh.error) )
					{
						writefln("error is NaN.  next layer error: %s, synapse val: %s", to!string(nhInner.error), to!string(nhInner.synapses[currentSynapse]));
					}
					/+++/assert(!isNaN(nh.error));
					if (nh.error > error_clamp)  nh.error = error_clamp;
					if (nh.error < -error_clamp) nh.error = -error_clamp;
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


	void train (real [] [] inputs , real [] expectedOutputs, int [] output_neuron_numbers, int depth = 0  ) {
		 
		assert(inputs.length );
		assert(expectedOutputs.length );
		assert(inputs.length == expectedOutputs.length );
		assert(inputs[0].length == neuralNetwork.input.neurons.length );
		
		
		// holds the records that are beyond the error threshold.
		real [][] problem_inputs = [];
		real [] problem_expected = [];
		int [] problem_neuron_outputs = [];
		
		actualEpochs = 0;

		int patternCount = 0;
		real error = 0;
		real total_abs_error = 0;
		
		int last_problem_count = 0;
		real last_error = 0.0;
		real largest_error = 0.0;
		real last_largest_error = 0.0;
		
		real expected = 0; //experimental value
		real actual = 0;  // what we calculated from the NN
		bool write_progress = true;
		
		
		while ( 1 )
		{
			error = 0;
			feedForward(inputs[patternCount] );
			backPropogate(inputs[patternCount],expectedOutputs[patternCount], output_neuron_numbers[patternCount] );

			const bool train_on_problem_inputs = false;
			
			/+real [] actual;
			foreach ( int nCount, Neuron no;neuralNetwork.output.neurons)
			{
				actual ~= no.value;
				//error += (expectedOutputs[patternCount][nCount] - no.value ) * (expectedOutputs[patternCount][nCount] - no.value );

			}
			error = costFunction.f(expectedOutputs[patternCount],actual );
			/+++/assert(!isNaN(error));
			+/
			expected = expectedOutputs[patternCount];
			actual = neuralNetwork.output.neurons[output_neuron_numbers[patternCount]].value;
			error =  expected - actual;
			total_abs_error += abs(error);
			if (abs(error) > largest_error)
				largest_error = abs(error);
			
			if(train_on_problem_inputs && abs(error) > errorThreshold)
			{	
				problem_inputs ~= inputs[patternCount];
				problem_expected ~= expectedOutputs[patternCount];
				problem_neuron_outputs ~= output_neuron_numbers[patternCount];
			}

			patternCount++;
			debug 
			{
				writef("Iterations [ %d ] Error [ ",actualEpochs  );
				for ( int i = 0 ; i < neuralNetwork.output.neurons.length; i++ )
				{
					writef(" %s ",to!string(neuralNetwork.output.neurons[i].error) );
				}
				writefln(" ] Cost [ %s ]",error);
			}
				 
			if ( patternCount >= inputs.length ) 
			{
				//for(int i = 0; i < depth; ++i) write(" ");
				//writef("Learning rate: %f",learningRate);
				real avg_err = total_abs_error / patternCount;
				if(last_error == 0.0) last_error = avg_err;
				if(last_largest_error == 0.0) last_largest_error = largest_error;
				if(write_progress)
				{
					writefln("Average Error: % 7f (%+7f)    Largest Error: % 7f (%+7f)", avg_err, avg_err - last_error, largest_error, largest_error - last_largest_error);
					write_progress = false;
					}
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
				
				if(train_on_problem_inputs && problem_inputs.length > 500)
				{	
					//for(int i = 0; i < depth; ++i) write(" ");
					if(last_problem_count == 0) last_problem_count = problem_inputs.length;
					writefln("%d problem records (%+d)", problem_inputs.length, problem_inputs.length - last_problem_count);
					last_problem_count = problem_inputs.length;
					train(problem_inputs, problem_expected, problem_neuron_outputs, depth+1);
				}
			}

			if ( actualEpochs % callBackEpochs == 0 ) 
			{
				//for(int i = 0; i < depth; ++i) write(" ");
				/+if ( progressCallback !is null )
				{
					progressCallback( actualEpochs, error, expected, actual );
				}+/
				write_progress = true;
			}

			if ( ++actualEpochs >= epochs ) break;
			//if ( error <= this.errorThreshold ) break; // negative error is PERFECTLY NORMAL when doing value prediction, like we do for reinforcement learning.
			//  really, I could also make it display SSE, becasue I'm using its derivative in the computation anyway, but displaying raw error is more informative in this context.

		}
		 

		 
	}
	
}