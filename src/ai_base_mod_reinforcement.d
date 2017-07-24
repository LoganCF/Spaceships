module ai_base_mod_reinforcement;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
(It boils down to "do whatever you want, just give me credit if you use this for something")
*/


import std.file;
import std.random;
import std.math;
import std.container.dlist;
import std.container.util;
import std.algorithm.comparison;	

import core.memory;

import and.api;
import and.platform;

import ai_base;

// keeps records of the expected score and sends these to the AI (to determine error)
//The mod_reinforcement AI guesses what game game-state value taking each possible order will result in.
class ModifiedReinforcementBaseAI : BaseAI
{
	real[] _training_scores; // array of what the score actually was a time after an order was executed, passed to the NN so it can calculate error
	
	this( char[] filename, double time_window )
	{
		super(filename, time_window);
		_emulatable = false;
	}
	
	override void reset_records()
	{
		super.reset_records();
		_training_scores.length = 0;
	}
	
	override void do_init(int num_inputs, int num_hidden_neurons, int num_outputs)
	{
		//make layers and NN
		IActivationFunction act_fn        = new SigmoidActivationFunction;
		IActivationFunction output_act_fn = new TanhActivationFunction();
		Layer input  = new Layer(num_inputs,0);
		Layer[] hidden = [ new Layer(num_hidden_neurons, num_inputs, act_fn) ];
		Layer output = new Layer(num_outputs, num_hidden_neurons, output_act_fn);
		
		_neural_net = new NeuralNetwork(input, hidden, output);
		
		_cost = new SSE(); // sum-squared errors
		_backprop = new ModifiedReinforcementBackPropagation(_neural_net, _cost);
		
		configure_backprop();
	}
	
	override void load_net()
	{
		//string netstring = readText(_filename);
		_neural_net = loadNetwork(getcwd() ~ "\\" ~ _filename); 
		//_input_layer = _neural_net.input;
		//_hidden_layers = _neural_net.hidden;
		//_output_layer = _neural_net.output;
		
		_cost = new SSE();
		_backprop = new ModifiedReinforcementBackPropagation(_neural_net,_cost);
		configure_backprop();
	}
	
	
	void do_training(real[][] inputs, int[] output_records, real[] training_scores)
	{
		assert(inputs.length == output_records.length);
		
		if( inputs.length == 0 )
		{
			writeln("No Training Data for Neural Network!");
			return;
		}
		
		int epochs = min(inputs.length, 5000);
		/+to!int( epoch_factor / inputs.length );
		if (epochs == 0) epochs = 1=+/;
		writefln("Training Mod-Reinforcement Network, %d epochs, %d records", epochs, output_records.length);
		
		void callback( uint currentEpoch, real currentError  )
		{
			writefln("Epoch: [ %s ] | Error [ %f ] ",currentEpoch, currentError );
		}
		_backprop.setProgressCallback(&callback, 100 );
		
		_backprop.epochs = epochs;
		to!ModifiedReinforcementBackPropagation(_backprop).train(inputs, training_scores, output_records);
		writeln("done training");
	}
	
	override void train_net(bool victory) 
	{
		do_training(_training_input, _output_records, _training_scores);
	}
	
	//don't do emulation training
	override void train_net_to_emulate(BaseAI other)
	{
		writeln("Mod-Reinforcement Network does not do emulation training");
	}
	
	
	//update all record whose windows have elasped
	override void update_records(double now, double score )
	{
		_last_score = score;
		_last_timestamp = now;
		while(!_pending_record_queue.empty && now - _pending_record_queue.front.timestamp >= _time_window)
		{
			//make record 
			close_record(_pending_record_queue.front);
			
			_pending_record_queue.removeFront();
		}
	}
	
	
	// game is over, so update all pending records
	// last score reported in update_records is used as current score.
	// TODO: shoud this be -1 or 1 based on victory/loss? or will that just confuse the poor robot?
	override void update_records_endgame(bool victory)
	{
		while(!_pending_record_queue.empty)
		{
			close_record(_pending_record_queue.front);
			
			_pending_record_queue.removeFront();
		}
	}
	
	
	
	void make_training_record(PendingRecord pending_record)
	{
		auto debg = pending_record.decision;
        auto debg2 = _neural_net.output.neurons.length;
    
		/+ real[] record = make_training_array( pending_record.decision, is_correct, _neural_net.output.neurons.length ); only needed for emulation +/
		
		/+_training_output ~= record; only needed for emulation +/
		// in some cases, we do additional replication later for some decision types (like more expensive units int the build AI)
		// based on the values in output records
		_output_records  ~= pending_record.decision; 
		_training_input   ~= pending_record.inputs;
		
		_training_scores ~= _last_score;
		
	}
}
