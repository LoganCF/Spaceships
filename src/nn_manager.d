module nn_manager;

import core.memory;
import std.algorithm.comparison;
import std.file;
import std.random;

import record_keeper;
import ai_base;
import mathutil;

import and.api;
import and.platform;


const bool g_train_on_opponent_records = true;


// initializes, queries, and trains a Neural Network
class NNManagerBase
{
	NeuralNetwork _neural_net;
	IActivationFunction _activation_function;
	CostFunction _cost;
	BackPropagation _backprop;
	
	real _random_scaling = 0.0; // chance to take a random action when predicted score = -1, scales quadratically down to 0 at predicted score = 1.
	
	BaseAI _ai; // the ai that owns this nnm
	
	real[][]  _training_input;
	
	char[] _filename;
	char[] _ai_shortname;
	
	RecordKeeper _record_keeper;
	double time_window_scale = 1.0; // changes how long record keeper waits to close records, subclasses can change this.
	
	int _epoch_limit = 2000;
	
	/*int _num_input;
	int _num_hidden;
	int _num_ouput;*/
	
	
	this(char[] filename, IActivationFunction actfn)
	{
		_filename = "nets\\" ~ filename; 
		_ai_shortname = filename.length >=4 && filename[$-4] == '.' ? filename[0..$-4] : filename;
		_activation_function = actfn;
	}
	
	~this()
	{
		destroy(_backprop);
		destroy(_neural_net);
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
	
	abstract void do_init(int num_inputs, int[] num_hidden_neurons_in_layer, int num_outputs);
	
	
	
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
		if (opponent is null)
			return;
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
	
	int reductions_avail = 4;
	
	void callback( uint currentEpoch, real currentError, real deltaError, real largestError, real deltaLargestError  )
	{
		if (currentEpoch % 2000 == 0) //TODO: blegh
		{
			writefln("%20s Iteration %d: Average Error: % 7f (%+7f)    Largest Error: % 7f (%+7f)", _ai_shortname, currentEpoch, currentError, deltaError, largestError, deltaLargestError);
		}
		
		if ( deltaError > 0.001 && reductions_avail > 0)
		{
			_backprop.learningRate /= 2;
			reductions_avail--;
			writefln("%20s setting learningRate to %f", _ai_shortname, _backprop.learningRate);
		}
		if(currentError <= _backprop.errorThreshold)
		{
			writefln("%20s done! (Avg Error is: % 7 f", _ai_shortname, currentError);
		}
		if (currentEpoch % 2000 == 0) //TODO: blegh
		{
			_backprop.errorThreshold *= 1.01; // this makes it double about every 69 callbacks
		}
		
		/+if ( expected != 0.0 || nn_result != 0.0)
			writefln("Epoch: [ %5s ] | Error [ % f ]   | Actual [ % f ] | Predicted [ % f ]",currentEpoch, currentError,expected, nn_result );
		else
			writefln("Epoch: [ %5s ] | Error [ % f ]",currentEpoch, currentError);+/
	}
	
	
	
	//TODO: move to NN Manager, make abstract
	// this is replaced with make_data_from_own/opponent_record
	//abstract void make_training_record(CompletedRecord completed_record);
	
	
	int query_net(real[] inputs)
	{
		assert(inputs.length == _neural_net.input.neurons.length, "Input is the wrong size: " ~ text!int(inputs.length) ~ " instead of " ~ text!int(_neural_net.input.neurons.length));
		//nn get
		real[] results = _backprop.computeOutput(inputs);
		int winner = nodeWinner( results );
		
		if (_random_scaling != 0.0)
		{
			real chance = square((1.0 - results[winner]) / (1.0 - -1.0)) * _random_scaling;
			if(uniform01() < chance)
			{
				winner = to!int(uniform(0,results.length));
			}
			
		}
		return winner;
	}
	
	string get_training_header(){
		return "";
	}
	
}