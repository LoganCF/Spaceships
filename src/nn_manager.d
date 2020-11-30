module nn_manager;

import core.memory;
import std.algorithm.comparison;
import std.file;

import record_keeper;
import ai_base;

import and.api;
import and.platform;


const bool g_train_on_opponent_records = false;


// initializes, queries, and trains a Neural Network
class NNManagerBase
{
	NeuralNetwork _neural_net;
	IActivationFunction _activation_function;
	CostFunction _cost;
	BackPropagation _backprop;
	
	BaseAI _ai; // the ai that owns this nnm
	
	real[][]  _training_input;
	
	char[] _filename;
	
	RecordKeeper _record_keeper;
	double time_window_scale = 1.0; // changes how long record keeper waits to close records, subclasses can change this.
	
	
	
	int _num_input;
	int _num_hidden;
	int _num_ouput;
	
	
	this(char[] filename, IActivationFunction actfn)
	{
		_filename = "nets\\" ~ filename; 
		_activation_function = actfn;
	}
	
	//TODO: make load_net beefier instead
	/+
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
	}+/
	
	abstract void do_init(int num_inputs, int num_hidden_neurons, int num_outputs);
	
	
	
	abstract void adjust_NN_params(); 
	
	
	void save_net()
	{
		//write( _filename, _neural_net.serialize() );
		/*if(!g_savenets)
		{
			return;
		}*/
		
		char[] path = getcwd() ~ "\\" ~ _filename;
		writefln("Saving Neural Net:  %s", path);
		if (! saveNetwork(_neural_net, path ) ) 
		{
			writefln("Saving NN failed, path= %s", path);
		}
	}
	
	
	bool load_net()
	{
		if(exists(_filename))
		{
			_neural_net = loadNetwork(getcwd() ~ "\\" ~ _filename); 
			
			_cost = new SSE();
			_backprop = new BackPropagation(_neural_net,_cost);
			//configure_backprop(); //TODO: do we define configure backprop?
			return true;
		} else {
			return false;
		}
	}
	
	// subclasses should override this to cleanup their own training arrays.
	void cleanup()
	{
		_training_input .length = 0;
		
		
		GC.collect();
	}
	
	void make_training_data(NNManagerBase opponent)
	{
		foreach(record ; _record_keeper._completed_records)
		{
			make_training_data_from_own_record( record );
		}
		
		if (!g_train_on_opponent_records)
		{
			writeln("training on opponent's records is disabled.");
			return;
		}
		foreach(record ; opponent._record_keeper._completed_records)
		{
			make_training_data_from_opponent_record( record );
		}
	
	}
	
	// subclasses are responsible for handling replication
	abstract void make_training_data_from_own_record( ref CompletedRecord record);
	abstract void make_training_data_from_opponent_record(ref CompletedRecord record);
	
	//subclases should override this
	abstract void train_net();
	
	void callback( uint currentEpoch, real currentError, real expected, real nn_result )
	{
		if ( expected != 0.0 || nn_result != 0.0)
			writefln("Epoch: [ %5s ] | Error [ % f ]   | Actual [ % f ] | Predicted [ % f ]",currentEpoch, currentError,expected, nn_result );
		else
			writefln("Epoch: [ %5s ] | Error [ % f ]",currentEpoch, currentError);
	}
	
	
	
	//TODO: move to NN Manager, make abstract
	// this is replaced with make_data_from_own/opponent_record
	//abstract void make_training_record(CompletedRecord completed_record);
	
	
	int query_net(real[] inputs)
	{
		assert(inputs.length == _neural_net.input.neurons.length, "Input is the wrong size: " ~ text!int(inputs.length) ~ " instead of " ~ text!int(_neural_net.input.neurons.length));
		//nn get
		real[] results = _backprop.computeOutput(inputs);
		return nodeWinner( results );
	}
	
	string get_training_header(){
		return "";
	}
	
}