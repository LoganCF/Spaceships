module ai_base;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/


import std.file;
import std.random;
import std.math;

import core.memory;

import and.api;
import and.platform;

string SAVE_DIR = "X:\\Neural_nets";

bool g_savenets = true; // this could be removed.

class BaseAI
{
	NeuralNetwork _neural_net;
	IActivationFunction _activation_fn;
	
	
	CostFunction _cost;
	BackPropagation _backprop;

	
	real[][]  _input_records;
	real[][]  _training_output;
	int[] _output_records;
	
	char[] _filename;

	this( char[] filename )
	{
		_filename = "nets\\" ~ filename;
		/+if(exists(_filename))
		{
			load_net();
		} else {
			init_net();
		}+/
	}
	
	void reset_records()
	{
		_input_records. length  = 0;
		_output_records.length  = 0;
		_training_output.length = 0;
	}
	
	void load_or_initialize_net()
	{
		if(_neural_net is null)
		{
			if(exists(_filename))
			{
				load_net();
			} else {
				init_net();
			}
		}
	}
	
	
	abstract void init_net();
	
	void do_init(int num_inputs, int num_hidden_neurons, int num_outputs)
	{
		//make layers and NN
		IActivationFunction act_fn = new SigmoidActivationFunction;
		Layer input  = new Layer(num_inputs,0);
		Layer[] hidden = [ new Layer(num_hidden_neurons, num_inputs, act_fn) ];
		Layer output = new Layer(num_outputs, num_hidden_neurons, act_fn);
		
		_neural_net = new NeuralNetwork(input, hidden, output);
		
		_cost = new SSE();
		_backprop = new BackPropagation(_neural_net, _cost);
		
		configure_backprop();
		save_net();// debug
	}
	
	
	abstract void configure_backprop();
	
	
	int get_decision(real[] inputs)
	{
		/+if(_neural_net is null)
		{
			if(exists(_filename))
			{
				load_net();
			} else {
				init_net();
			}
		}+/
		
		load_or_initialize_net();
		
		assert(inputs.length == _neural_net.input.neurons.length, "Input is the wrong size: " ~ text!int(inputs.length) ~ " instead of " ~ text!int(_neural_net.input.neurons.length));
		//nn get
		real[] results = _backprop.computeOutput(inputs);
		int retval = nodeWinner( results );
		//add to records
		if(true /+g_savenets+/)
		{
			_input_records  ~= inputs;
			_output_records ~= retval;
		}
		
		return retval;
	}
	
	void record_decision(real[] inputs, int choice)
	{
		_input_records  ~= inputs;
		_output_records ~= choice;
	}
	
	void save_net()
	{
		//write( _filename, _neural_net.serialize() );
		if(!g_savenets)
		{
			return;
		}
		
		char[] path = getcwd() ~ "\\" ~ _filename;
		//char[] path = SAVE_DIR ~ "\\" ~ _filename;
		writefln("Saving Neural Net:  %s", path);
		if (! saveNetwork(_neural_net, path ) ) 
			writefln("Saving NN failed, path= %s", path);
	}
	
	void load_net()
	{
		//string netstring = readText(_filename);
		_neural_net = loadNetwork(getcwd() ~ "\\" ~ _filename); 
		//_input_layer = _neural_net.input;
		//_hidden_layers = _neural_net.hidden;
		//_output_layer = _neural_net.output;
		
		_cost = new SSE();
		_backprop = new BackPropagation(_neural_net,_cost);
		configure_backprop();
	}
	
	// make these non-const members?
	const double TRAINING_EPOCHS_FACTOR_WON     = 2000.0;
	const double TRAINING_EPOCHS_FACTOR_LOST    = 1500.0;
	const double TRAINING_EPOCHS_FACTOR_EMULATE = 1000.0;

	
	void train_net(bool victory)
	{
		if(!g_savenets) return;
	
		double factor =  victory ? TRAINING_EPOCHS_FACTOR_WON : TRAINING_EPOCHS_FACTOR_LOST;
		
		_training_output.length = 0;
		
		foreach(output; _output_records)
		{
			_training_output ~= make_training_array(output, victory, _neural_net.output.neurons.length);
		}
		
		do_training(_input_records, _training_output, factor);
	}
	
	void train_net_to_emulate(BaseAI other)
	{
		if(!g_savenets) return;
		do_training( other._input_records, other._training_output, TRAINING_EPOCHS_FACTOR_EMULATE );
	}
	
	//TODO? void train_net_not_to_emulate(BaseAI other)?
	
	void do_training(real[][] inputs, real[][] training_outputs, double epoch_factor)
	{
		assert(inputs.length == training_outputs.length);
		
		if( inputs.length == 0 )
		{
			writeln("No Training Data for Neural Network!");
			return;
		}
		
		int epochs = to!int( epoch_factor / inputs.length );
		if (epochs == 0) epochs = 1;
		writefln("Training, %d epochs", epochs);
		
		void callback( uint currentEpoch, real currentError  )
		{
			writefln("Epoch: [ %s ] | Error [ %f ] ",currentEpoch, currentError );
		}
		_backprop.setProgressCallback(&callback, 1 );
		
		_backprop.epochs += epochs;
		_backprop.train(inputs, training_outputs);
		writeln("done training");
	}
	
	void cleanup()
	{
		_input_records  .length = 0;
		_training_output.length = 0;
		_output_records .length = 0;
		// writeln("cleaning arrays");
		GC.collect();
	}
		
}


//TODO: make this a member funtion
real[] make_training_array(int result, bool victory, int num_output_neurons)
{
	if(victory)
	{
		return make_training_array_helper(result, num_output_neurons);
	} else {
		// return a random other index in the array
		int roll = random_in_range_excluding(0, num_output_neurons - 1, result);
		return make_training_array_helper( roll, num_output_neurons);
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

real sigmoid(real in_val)
{
	return ( 1.0 / ( 1.0 + exp( -in_val ) ) );
}

