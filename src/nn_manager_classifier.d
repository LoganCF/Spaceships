module nn_manager_classifier;

import std.random;
import std.algorithm.comparison;

import and.api;
import and.platform; 

import nn_manager;
import record_keeper;



class NNManagerClassifier : NNManagerBase
{
	real[][]  _training_output; // "correct" output of all output nodes based on how the decision worked out.
	

	int _good_decisions = 0;
	int _bad_decisions  = 0;
	
	this(char[] filename, IActivationFunction actfn)
	{
		super(filename, actfn);
		_epoch_limit   = 5000;
	}
	
	
	
	override void do_init(int num_inputs, int[] num_hidden_neurons_in_layer, int num_outputs)
	{
		//make layers and NN
		IActivationFunction act_fn =  _activation_function; //new SigmoidActivationFunction;
		Layer input  = new Layer(num_inputs,0);
		Layer[] hidden = [ new Layer(num_hidden_neurons_in_layer[0], num_inputs, act_fn) ];
		foreach (int i; 1..num_hidden_neurons_in_layer.length)
		{
			hidden ~= new Layer(num_hidden_neurons_in_layer[i], num_hidden_neurons_in_layer[i-1], act_fn);
		}
		Layer output = new Layer(num_outputs, num_hidden_neurons_in_layer[$-1], act_fn);
		
		_neural_net = new NeuralNetwork(input, hidden, output);
		
		_cost = new SSE(); // sum-squared errors
		_backprop = new BackPropagation(_neural_net, _cost);
		
		//configure_backprop(); adjust_nn_params is called by ai
	}
	
	//TODO: decision # is returned by a function from the AI (So it can get strategy/choice)
	//TODO: we could also get the delta_territory_diff with an abstract function so that subclasses can use delta_territory_diff/score. (use is_record_good instead?)
	override void make_training_data_from_own_record( ref CompletedRecord record)
	{
		if (_ai.getResultFromRecord(record) == -1)
			return;
		if(record.delta_territory_diff > 0)
		{
			//make "correct" record
			_good_decisions ++;
			real[] output = make_training_array( _ai.getResultFromRecord(record), true, _neural_net.output.neurons.length );
			//replication, TODO: maybe this should be done elsewhere
			for(int i = 0; i < record.num_duplicates; ++i)
			{
				_training_output ~= output;
				_training_input  ~= record.inputs;			
			}
		} else 
		if(record.delta_territory_diff < 0 || 
		   !(record.endgame && _record_keeper.victory) ) // 0 diff is 'wrong' except for records right before we won.
		{
			//make "incorrect" record
			_bad_decisions++;
			real[] output = make_training_array( _ai.getResultFromRecord(record), false, _neural_net.output.neurons.length );
			//TODO: replication (or is this handled by the AI?)
			for(int i = 0; i < record.num_duplicates; ++i)
			{
				_training_output ~= output;
				_training_input  ~= record.inputs;			
			}			
		} 
	}
	
	override void make_training_data_from_opponent_record(ref CompletedRecord record)
	{
		if (_ai.getResultFromRecord(record) == -1)
			return;
		if(record.delta_territory_diff > 0)
		{
			//make "correct" record
			//_good_decisions ++; not here. the opponent made the good decision
			real[] output = make_training_array( _ai.getResultFromRecord(record), true, _neural_net.output.neurons.length );
			//TODO: replication (or is this handled by the AI?)
			for(int i = 0; i < record.num_duplicates; ++i)
			{
				_training_output ~= output;
				_training_input  ~= record.inputs;			
			}					
		}
	}
	
	override void train_net() 
	{
		do_training(_training_input, _training_output);
	}
	
	void do_training(real[][] inputs, real[][] training_outputs)
	{
		assert(inputs.length == training_outputs.length);
		
		if( inputs.length == 0 )
		{
			writeln("No Training Data for Neural Network!");
			return;
		}
		
		int epochs = min(inputs.length*20, _epoch_limit);
		writefln("Training, %d epochs, %d records", epochs, training_outputs.length);
		
		_backprop.setProgressCallback(&callback, 500 );
		
		_backprop.epochs += epochs;
		_backprop.train(inputs, training_outputs);
		writeln("done training");
	}
	
	
	
	
	
	override void adjust_NN_params(){} //Do nothing in this subclass
	
	
	override void cleanup()
	{
		_training_output.length = 0;
		super.cleanup();
	}
	
	//?
	/+void make_training_record(ClosedRecord closed_record)
	{
		(is_correct ? _good_decisions : _bad_decisions)++;
    
		real[] output = make_training_array( pending_record.decision, is_correct, _neural_net.output.neurons.length );
		//int num_duplicates = get_duplication_factor(is_correct);
		for( int i = 0 ; i < num_duplicates; ++i)
		{
			_training_output ~= record;
			// in some cases, we do additional replication later for some decision types (like more expensive units int the build AI)
			// based on the values in output records
			_output_records  ~= pending_record.decision; 
			_training_input   ~= pending_record.inputs;
			
		}
	}+/
	
	//TODO: finish this, also make one for opponent record
	//This would need to return int, 1 = good, 0 = do nothing, -1 = bad
	int is_record_good(ref CompletedRecord record)
	{
		// condition where it says what is good or bad
		return 0; //TODO: make this function
	}
	
	override string get_training_header(){
		return format("%d good decisions, %d bad decisions", _good_decisions, _bad_decisions);
	}
	
	
}





real[] make_training_array(int result, bool correct, int num_output_neurons)
{
	if(correct)
	{
		return make_training_array_helper(result, num_output_neurons);
	} else {
		
		// now returns an array with all 1's except the decision made
		//return make_training_array_helper_inverse( result, num_output_neurons);
    
        int roll = random_in_range_excluding(0, num_output_neurons - 1, result);
        return make_training_array_helper(roll, num_output_neurons);
	}
}

real[] make_training_array_helper(int index_where_a_1_goes, int num_output_neurons)
{
	real[] retval;
	retval.length = num_output_neurons;
	retval[] = 0.0;
	retval[index_where_a_1_goes] = 1.0;
	return retval;
}

real[] make_training_array_helper_inverse(int index_where_a_0_goes, int num_output_neurons)
{
	real[] retval;
	retval.length = num_output_neurons;
	retval[] = 1.0;
	retval[index_where_a_0_goes] = 0.0;
	return retval;
}


int random_in_range_excluding(int min, int max, int not_this_one)
{
	assert(max > min + 1);
	int roll = to!int(floor(uniform01!(float)() * (max - min - 1))) + min;
	if ( roll >= not_this_one)
	{
		roll += 1;
	}
	return roll;
}