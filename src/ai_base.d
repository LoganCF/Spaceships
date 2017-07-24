module ai_base;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
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
import nn_manager;
import record_keeper;
import unit;


//TODO: move these constants to ai subclasses?
const double BUILD_AI_WINDOW   = 90.0;
const double COMMAND_AI_WINDOW = 15.0;





class BaseAI
{
	
	//bool _emulatable = true; 
	
	NNManagerBase _nn_mgr;
	RecordKeeper _record_keeper;
	
	double CHANCE_OF_RANDOM_ACTION = 0.005;
	

	this( NNManagerBase in_nnm) 
	{
		_nn_mgr = in_nnm;
		if( !_nn_mgr.load_net() ) 
		{
			init_nnm();
		}
		
		_record_keeper = new RecordKeeper();
		
		configure_backprop();
		setup_ai(in_nnm);
		
	}
	
	//TODO: 
	// calls functions in record keeper and manager
	void reset_records()
	{
		/+
		_training_input .length = 0; //TODO: nnm
		_training_output.length = 0; //TODO: classifier
		_good_decisions = 0; //TODO: classifier
		_bad_decisions  = 0; //TODO: classifier
		_record_keeper.clear_records();
		_nn_mgr.clear_training_data();
		+/
	}
	
	void setup_ai(NNManagerBase nnm)
	{
		_nn_mgr = nnm;
		_nn_mgr._record_keeper = _record_keeper;
		//_nn_mgr.init_net();//TODO: input, hidden, output.  probably should be load_or_init.
		/*if(!_nn_mgr.load_net()) // already done in ctor (does this make sense?)
		{
			init_nnm();
		}*/
		adjust_NN_params();
	}
	
	abstract void init_nnm();
	
	abstract void adjust_NN_params();
	
	abstract void configure_backprop();
	
	// returns the number of times the record should appear in the training set
	abstract int get_num_duplicates(real[] inputs, int output);
	
	//abstract size_t get_num_record_duplicates(UnitType type);
	
	/**
		gets a decision from the NN and records the input paramters & decision for training.
		asserts that the NN has the same number of input neurons as the "input" parameter
	*/
	//TODO: move some of the logic to NNM.
	//TODO: interact correctly with Strategy.
	//TODO: how do I get unittype here? (get from a function decided by move/build ai?) (get from inputs/output, get_num_duplicates is implemented by command/move AI)
	int get_decision(real[] inputs)
	{	
		/+load_or_initialize_net();+/
		
		if(uniform01() < CHANCE_OF_RANDOM_ACTION)
		{
			int random_result = to!int(uniform(0,_nn_mgr._neural_net.output.neurons.length));
			_record_keeper.record_decision(inputs, get_num_duplicates(inputs, random_result), random_result, -1); //TODO: strategy here
			return random_result;
		}
		
		int retval = _nn_mgr.query_net(inputs);
		
		//add to records
		_record_keeper.record_decision(inputs, get_num_duplicates(inputs, retval), retval, -1);// subclasses may specify a strategy here, but we just send -1 for "no strategy"
		
		return retval;
	}
	
	
	
	

	
	/+void train_net(bool victory) 
	{
		if(!g_savenets) return;
	
		double factor =  victory ? TRAINING_EPOCHS_FACTOR_WON : TRAINING_EPOCHS_FACTOR_LOST;
		
		/*_training_output.length = 0;
		
		foreach(output; _output_records)
		{
			_training_output ~= make_training_array(output, victory, _neural_net.output.neurons.length);
		}*/
		
		do_training(_training_input, _training_output, factor);
	}
	
	void train_net_to_emulate(BaseAI other)
	{
		if(!g_savenets) return;
		do_training( other._training_input_emulation, other._training_output_emulation, TRAINING_EPOCHS_FACTOR_EMULATE );
	}+/
	
	

	
	
	
	//close all records whose windows have elasped
	void update_records(double now, int territory_diff, real score )
	{
		_record_keeper.update_records(now, territory_diff, score);
	}
	
	// game is over, so update all pending records based on change in score
	// last score reported in update_records is used as current score.
	void update_records_endgame(bool victory, int territory_diff, real score)
	{
		_record_keeper.update_records_endgame(victory, territory_diff, score);
	}
	
	
	
	
	//TODO: call-throughs to NNM
	void make_training_data( BaseAI opponent)
	{
		_nn_mgr.make_training_data(opponent._nn_mgr);
	}
	
	
	void train_net()
	{
		_nn_mgr.train_net();
	}
	
	//TODO: My abstraction is leaking!
	void record_external_decision(real[] inputs, int choice, int strategy = -1)
	{
		_record_keeper.record_decision(inputs, get_num_duplicates(inputs, choice), choice, strategy);
	}

	string get_training_header(){
		return _nn_mgr.get_training_header();
	}
	
	void save_net()
	{
		_nn_mgr.save_net();
	}
	
	void cleanup(){
		_nn_mgr.cleanup();
	}
	
		
}



real sigmoid(real in_val)
{
	return ( 1.0 / ( 1.0 + exp( -in_val ) ) );
}

