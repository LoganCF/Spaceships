module ai_build;


/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/


import std.file;

import ai_base;
import unit;
import factory_unit;
import nn_manager;
import spaceships;

import and.api;
import and.platform;


class BuildAI : BaseAI
{
	// see ai_command.d for what this should have
	//real[][]  _training_input;
	//real[][] _output_records;
	
	//string _filename;

	this( NNManagerBase in_nnm )
	{
		super(in_nnm);
		_record_keeper.set_time_window(BUILD_AI_WINDOW * _nn_mgr.time_window_scale);
	}
	
	//functionality moved to nnm and get num_record_duplicates
	/+//TODO: this should still happen, but how? as this net generates units?  (did I mean closes records?)
	//TODO: command_ais shoud have access to this, and should be able to set (or scale the order duration
	void weight_records(bool victory)
	{
		// make duplicate records for more expensive units.
		size_t training_len = _nn_mgr._training_input.length;
		for(size_t i = 0; i < training_len; ++i)
		{
			UnitType unit_type = cast(UnitType)(_output_records[i]);  // cast(UnitType)nodeWinner(_output_records[i]) ;
			double unit_cost = get_unit_build_cost(unit_type);
			size_t num_dups = to!size_t( unit_cost / UNIT_COST_BASE ) - 1;
			for(size_t j = 0; j < num_dups; ++j)
			{
				_training_input    ~= _training_input[i];
				//_training_output ~= _training_output[i]; 
			}
		}
	}+/
	
	/+override size_t get_num_record_duplicates(UnitType type)
	{
		//TODO: this function
		double unit_cost = get_unit_build_cost(type);
		return to!size_t( unit_cost / UNIT_COST_BASE ) - 1;
	}+/
	
	
	override void init_nnm()
	{
			int num_inputs = NUM_BASE_AI_INPUTS + 1;
				
			int num_outputs = NUM_UNIT_TYPES;
			int[] num_hidden_neurons = [144, 48];
			
			
			_nn_mgr.do_init(num_inputs, num_hidden_neurons, num_outputs);	
			
	}
	
	
	override void configure_backprop()
	{
		with(_nn_mgr){ //TODO: this should be defined by the NN_mgr, the AI object should call adjust_NN_parameters
		
			_backprop.epochs = 0;
			_backprop.learningRate = 0.05;
			_backprop.momentum = 0.2;
			_backprop.errorThreshold = 0.1;
		}
	}
	
	//moved to nnm
	//override void adjust_NN_params(){} //TODO: ?
	
	/+override int get_decision(real [] inputs)
	{
		assert
	}+/
	
	override void train_net()
	{
		//weight_records(); TODO: when is replication happening again?
		super.train_net();
	}
	
	// return the number of times the record should appear in the training set
	override int get_num_duplicates(real[] inputs, int output)
	{
		return 1;
		/*
		double unit_cost = get_unit_build_cost(to!UnitType(output));
		return to!int( unit_cost / UNIT_COST_BASE );
		*/
	}
	
	

}
