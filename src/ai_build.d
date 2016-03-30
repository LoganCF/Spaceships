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
import spaceships;

import and.api;
import and.platform;


class BuildAI : BaseAI
{
	// see ai_command.d for what this should have
	//real[][]  _input_records;
	//real[][] _output_records;
	
	//string _filename;

	this( char[] filename)
	{
		super(filename);
	}
	
	
	
	void weight_records(bool victory)
	{
		// make duplicate records for more expensive units.
		size_t training_len = _input_records.length;
		for(size_t i = 0; i < training_len; ++i)
		{
			UnitType unit_type = cast(UnitType)(_output_records[i]);  // cast(UnitType)nodeWinner(_output_records[i]) ;
			double unit_cost = get_unit_build_cost(unit_type);
			size_t num_dups = to!size_t( unit_cost / UNIT_COST_BASE ) - 1;
			for(size_t j = 0; j < num_dups; ++j)
			{
				_input_records  ~=  _input_records[i];
				if(victory)
				{
					_output_records ~= _output_records[i];
				} else {
					_output_records ~= random_in_range_excluding(0, NUM_UNIT_TYPES, _output_records[i] );
				}
			}
		}
	}
	
	
	override void init_net()
	{
			int num_inputs = NUM_UNIT_TYPES * NUM_CAPTURE_POINTS * 4 + NUM_CAPTURE_POINTS * 2 + 3
							 + NUM_UNIT_TYPES 
							 + NUM_CAPTURE_POINTS + 3 + NUM_UNIT_TYPES * 4 + NUM_CAPTURE_POINTS * 2   // gen2
							 + 2; // gen 2.5
				
			int num_outputs = NUM_UNIT_TYPES;
			int num_hidden_neurons = 144; // because I wanted it to be.
			
			
			do_init(num_inputs, num_hidden_neurons, num_outputs);	
			
	}
	
	
	override void configure_backprop()
	{
	
		void callback( uint currentEpoch, real currentError  )
		{
			writefln("Epoch: [ %s ] | Error [ %f ] ",currentEpoch, currentError );
		}
		_backprop.setProgressCallback(&callback, 10 );
	
		_backprop.epochs = 0;
		_backprop.learningRate = 0.05;
		_backprop.momentum = 0.5;
		_backprop.errorThreshold = 0.000001;
	}
	
	
	/+override int get_decision(real [] inputs)
	{
		assert
	}+/
	
	override void train_net(bool victory)
	{
		weight_records(victory);
		super.train_net(victory);
	}
	

}

