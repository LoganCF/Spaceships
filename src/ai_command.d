module ai_command;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.file;

import ai_base;
import spaceships;
import unit;

import and.api;
import and.platform;


class CommandAI : BaseAI
{
	// has a neuralnet and a record of decisions made in the most recent game.
	
	this( char[] filename )
	{
		super(filename);
	}
	
	
	override void init_net()
	{
		int num_inputs = NUM_UNIT_TYPES * NUM_CAPTURE_POINTS * 4 + NUM_CAPTURE_POINTS * 2 + 3   //starting to smell like a funciton up in here.
			+ NUM_UNIT_TYPES + NUM_CAPTURE_POINTS + 1     // command_ai specific stuff
			+ 1 + NUM_UNIT_TYPES * 4 + NUM_CAPTURE_POINTS * 2   // gen2
			+ 2; // gen 2.5
			
		int num_outputs = NUM_CAPTURE_POINTS;
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
}