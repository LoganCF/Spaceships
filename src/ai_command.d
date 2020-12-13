module ai_command;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.file;

import ai_base;
import nn_manager;
import spaceships;
import unit;
import factory_unit;

import and.api;
import and.platform;

const int NUM_COMMAND_AI_INPUTS = NUM_BASE_AI_INPUTS;


class CommandAI : BaseAI
{
	// has a neuralnet and a record of decisions made in the most recent game.
	
	this( NNManagerBase in_nnm, int[] in_num_hidden = [144, 48] )
	{
		super(in_nnm, in_num_hidden);
		_record_keeper.set_time_window(COMMAND_AI_WINDOW * _nn_mgr.time_window_scale);
	}
	
	/+override size_t get_num_record_duplicates(UnitType type)
	{
		return 1; 
	}+/
	
	override void init_nnm()
	{
		int num_inputs = NUM_COMMAND_AI_INPUTS;
			
		int num_outputs = NUM_CAPTURE_POINTS;
		int[] num_hidden_neurons = _num_hidden;
		
		_nn_mgr.do_init(num_inputs, num_hidden_neurons, num_outputs);	
		
	}
	
	
	override void configure_backprop()
	{
		with (_nn_mgr)
		{
			
			_backprop.epochs = 0;
			_backprop.learningRate = 0.05;
			_backprop.momentum = 0.2;
			_backprop.errorThreshold = 0.1;
			
		}
		//_record_keeper._time_window = COMMAND_AI_WINDOW; // TODO: where this go?
	}
	
	//moved to nnm
	//override void adjust_NN_params(){} //TODO: this function
	
	// return the number of times the record should appear in the training set
	override int get_num_duplicates(real[] inputs, int output)
	{
		return 1;  // this was just too jank, and was messing up the results since I added the closest point in gen 3.5
		/+
		UnitType type = get_type_from_inputs(inputs);
		//writef("unittype:%d ",to!int(type)); // debug
		
		// currenlty order frequency is constant, if it becomes scaled based on unit cost, this should take that into account.
		double unit_cost = get_unit_build_cost(type);
		return to!int( unit_cost / UNIT_COST_BASE );
		+/
	}
	
	UnitType get_type_from_inputs(real [] inputs)
	{
		writeln("don't use get_type_from_inputs!");
		int offset = NUM_UNIT_TYPES * NUM_CAPTURE_POINTS * 4 + NUM_CAPTURE_POINTS * 2 + 3 + 2 + NUM_CAPTURE_POINTS * 2; //TODO: this is crazy
		int i;
		for (i = 0 ; i < NUM_UNIT_TYPES; ++i)
		{
			if (inputs[offset+i] > 0.0)
			{
				return to!UnitType(i);
			}
		}
		assert(false, "NN input indicates Unit has no type! Preposterous!");
		//return UnitType.None; //??? this shouldn't happen.
	}
}