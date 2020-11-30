module nn_manager_mod_reinforcement;

import std.algorithm.comparison;
import std.file;
import std.random;

import nn_manager;
import record_keeper;

import and.api;
import and.platform; 




class NNManagerModReinforcement : NNManagerBase
{
	real[] _training_scores; // array of what the score actually was a time after an order was executed, passed to the NN so it can calculate error
	int[]  _output_records;  // array of which choice was made for each order

	this(char[] filename, IActivationFunction actfn)
	{
		super(filename, actfn);
	}
	
	override void do_init(int num_inputs, int num_hidden_neurons, int num_outputs)
	{
		//make layers and NN
		IActivationFunction act_fn        = _activation_function;
		IActivationFunction output_act_fn = new TanhActivationFunction();
		Layer input  = new Layer(num_inputs,0);
		Layer[] hidden = [ new Layer(num_hidden_neurons, num_inputs, act_fn) ];
		Layer output = new Layer(num_outputs, num_hidden_neurons, output_act_fn);
		
		_neural_net = new NeuralNetwork(input, hidden, output);
		
		_cost = new SSE(); // sum-squared errors
		_backprop = new ModifiedReinforcementBackPropagation(_neural_net, _cost);
		
		//configure_backprop(); // asjust_nn_params is called from ai
	}
	
	// mostly the same as the superclass's load_net, but it makes a different type of backprop object
	// TODO: could use a factory method + overridden helper to avoid copy-pasta?
	override bool load_net()
	{
		if(exists(_filename))
		{
			_neural_net = loadNetwork(getcwd() ~ "\\" ~ _filename); 
			
			_cost = new SSE();
			_backprop = new ModifiedReinforcementBackPropagation(_neural_net,_cost);
			//configure_backprop(); //TODO: do we define configure backprop?
			return true;
		} else {
			return false;
		}
	}
	
	
	override void make_training_data_from_own_record( ref CompletedRecord record)
	{
		make_training_data_internal(record);	
	}
	
	
	override void make_training_data_from_opponent_record(ref CompletedRecord record)
	{
		make_training_data_internal(record);
	}
	
	// we treat our own records and opponent's records the same, so we do both in one place.
	void make_training_data_internal(ref CompletedRecord record)
	{
		if (_ai.getResultFromRecord(record) == -1)
			return;
		for(int i = 0; i < record.num_duplicates; ++i)
		{
			_training_input  ~= record.inputs;	
			_output_records  ~= _ai.getResultFromRecord(record);
			_training_scores ~= record.score;
		}
	}
	
	void do_training(real[][] inputs, int[] output_records, real[] training_scores)
	{
		assert(inputs.length == output_records.length);
		
		if( inputs.length == 0 )
		{
			writeln("No Training Data for Neural Network!");
			return;
		}
		
		int epochs = max(inputs.length, 10_000);
		/+to!int( epoch_factor / inputs.length );
		if (epochs == 0) epochs = 1=+/;
		writefln("Training Mod-Reinforcement Network, %d epochs, %d records", epochs, output_records.length);
		
		_backprop.setProgressCallback(&callback, 500 );
		
		_backprop.epochs = epochs;
		to!ModifiedReinforcementBackPropagation(_backprop).train(inputs, training_scores, output_records);
		writeln("done training");
	}
	
	
	override void train_net() 
	{
		do_training(_training_input, _output_records, _training_scores);
	}
	
	override void cleanup()
	{
		_training_scores.length = 0;
		_output_records .length = 0;
	}
	
	
	
	override void adjust_NN_params()
	{
		//_backprop.learningRate *= 2.0; //TODO: is this called at a reasonable time? //TODO: make this bigger?
		_backprop.errorThreshold = .005; // we can actually expect more accuracy from the non-history version because the record-sets are smaller.
	} 
	
	
	
	override string get_training_header(){
		return format("");
	}
}