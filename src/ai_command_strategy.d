module ai_command_strategy;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.file;
import std.random;

import ai_base;
import ai_command;
import nn_manager;
import spaceships;
import unit;
import factory_unit;
import strategy;
import strategies;
import gamestateinfo;
import record_keeper;

import and.api;
import and.platform;


class StrategyCommandAI : CommandAI
{
	// picks and evals strategies
	
	this( NNManagerBase in_nnm)
	{
		super(in_nnm);
		_record_keeper.set_time_window(COMMAND_AI_WINDOW * _nn_mgr.time_window_scale);
	}
	
	override DecisionResult get_decision(real[] inputs, StateInfo gamestate)
	{	
		/+load_or_initialize_net();+/
		int strategy_index;
		if(uniform01() < CHANCE_OF_RANDOM_ACTION)
		{
			strategy_index = to!int(uniform(0,_nn_mgr._neural_net.output.neurons.length));
			
		} else {
			strategy_index = _nn_mgr.query_net(inputs);
		}
		
		int decision = g_strategies[strategy_index].evaluate(gamestate);
		
		//add to records
		_record_keeper.record_decision(inputs, 1, decision, strategy_index);
		
		if( decision == -1)
			writefln("strategy:  %d, result: %d", strategy_index ,decision);
		
		return DecisionResult(decision, strategy_index);
	}
	
	override int getResultFromRecord(ref CompletedRecord record)
	{
		return record.strategy;
	}
	
	override void init_nnm()
	{
		int num_inputs = NUM_COMMAND_AI_INPUTS;
			
		int num_outputs = g_strategies.length;
		int[] num_hidden_neurons = [144, 48];
		
		_nn_mgr.do_init(num_inputs, num_hidden_neurons, num_outputs);	
		
	}
	
}