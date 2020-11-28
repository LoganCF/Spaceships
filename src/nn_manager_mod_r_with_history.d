module nn_manager_mod_r_with_history;

import std.stdio;
import std.algorithm.comparison;
//import

import nn_manager;
import nn_manager_mod_reinforcement;
import record_keeper;
import record_history;

import and.api;
import and.platform;


class NNManagerModReinforcementWithHistory : NNManagerModReinforcement
{
	RecordHistory _hist;
	int _record_limit  = 2_000; //TODO: not magic number
	
	this(char[] filename, IActivationFunction actfn)
	{
		super(filename, actfn);
		
	}
	
	
	override void make_training_data_internal(ref CompletedRecord record)
	{
		if (_ai.getResultFromRecord(record) == -1)
			return;
		//overriden so we don't do any duplication
		_training_input  ~= record.inputs;	
		_output_records  ~= _ai.getResultFromRecord(record);
		_training_scores ~= record.score;
	}
	
	
	//TODO: this is much copy of pasta, could just make the part that calcs epochs its own function
	override void do_training(real[][] inputs, int[] output_records, real[] training_scores)
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
		writefln("Training Mod-Reinforcement Network With History, %d epochs, %d records", epochs, output_records.length);
		
		_backprop.setProgressCallback(&callback, 500 );
		
		_backprop.epochs = epochs;
		to!ModifiedReinforcementBackPropagation(_backprop).train(inputs, training_scores, output_records);
		writeln("done training");
	}
	
	
	override void do_init(int num_inputs, int num_hidden_neurons, int num_outputs)
	{
		init_hist(_filename, num_inputs);
		
		super.do_init(num_inputs, num_hidden_neurons, num_outputs);
	}
	
	override bool load_net()
	{
		bool retval = super.load_net();
		//TODO: abstraction is leaking, badly!
		if(retval) 
		{
			init_hist(_filename, _backprop.neuralNetwork.input.neurons.length);
		}
		return retval;
	}
	
	
	void init_hist(char[] ai_filename, uint num_inputs)
	{
		char[] filename_no_ext;
		if(ai_filename[$-4..$] == ".txt")
		{
			filename_no_ext = ai_filename[0..$-4];
		} else {
			filename_no_ext = ai_filename;
		}
		
		assert("blah.txt"[$-4..$] == ".txt");
		
		_hist = new RecordHistory(to!string(filename_no_ext), num_inputs);
	}
	
	
	override void make_training_data(NNManagerBase opponent)
	{
		// write completed records to file
		_record_keeper.write_records_to_history(_hist);
		// don't write opponent records to file, this could cause weird duplication errors
		/+opponent._record_keeper.write_records_to_history(_hist);+/
		// read from file
		/+_record_keeper.fill_to_n_records_from_history(_hist, _record_limit);+/
		CompletedRecord[] records_from_history = [];
		uint num_records_to_load = _record_limit - _record_keeper._completed_records.length 
								        - opponent._record_keeper._completed_records.length;
		_hist.fill_array_to_n_records( records_from_history, num_records_to_load );
		
		super.make_training_data(opponent);
		
		foreach(record ; records_from_history)
		{
			make_training_data_internal(record);
		}
		
		_hist.close();
		
	}
	
	override void adjust_NN_params()
	{
		super.adjust_NN_params();
		_backprop.learningRate = 0.025;
		_backprop.errorThreshold = 0.025;
	}
	
	
}