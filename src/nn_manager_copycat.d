module nn_manager_copycat;

// This is an AI designed to be trained by watching a player or bot's games.
// It just copies whatever player or bot does!

import std.algorithm.comparison;
import std.file;
import std.random;

import and.api;
import and.platform; 

import nn_manager;
import nn_manager_classifier;
import record_keeper;

class NNManagerCopycat : NNManagerClassifier
{

	this(char[] filename, IActivationFunction actfn)
	{
		super(filename, actfn);
	}
	
	override void make_training_data_from_own_record( ref CompletedRecord record)
	{
		//make "correct" record
		_good_decisions ++;
		real[] output = make_training_array( record.decision, true, _neural_net.output.neurons.length );
		//replication, TODO: maybe this should be done elsewhere
		for(int i = 0; i < record.num_duplicates; ++i)
		{
			_training_output ~= output;
			_training_input  ~= record.inputs;			
		}
		
	}
	
	override void make_training_data_from_opponent_record(ref CompletedRecord record)
	{
		return; // kthxbye!
	}
}


