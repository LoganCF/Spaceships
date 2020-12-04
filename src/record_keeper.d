module record_keeper;

import record_history;

import std.random;
import std.math;
import std.container.dlist;
import std.container.util;
import std.algorithm.comparison;	
import std.stdio;

import core.memory;

import and.api;
import and.platform;
import unit;


//-----------------------------------------------------------------------------
struct PendingRecord
{
	int territory_diff;
	//real score; ?
	
	double timestamp;
	real[] inputs;
	
	int decision;
	int strategy; // used only by AIs that pick scripted strategies TODO: make AIs that pick scripted strategies.
	
	UnitType unittype; // type of the unit receiving the order, or type of the unit being built
	int num_duplicates; //TODO: replace above with this
	
	this(int tdiff, double tim, real[] inpt, int dups, int dec, int strat = -1)
	{
		
		territory_diff = tdiff;
		//score     = sc; ?
		
		timestamp = tim;
		inputs    = inpt;
		
		decision  = dec;
		strategy = strat;
		num_duplicates = dups;
	}
}


//-----------------------------------------------------------------------------
class CompletedRecord
{
	int delta_territory_diff; // change in difference between opponent's and my territory.
	real score;
	
	real[] inputs;
	
	int decision;
	int strategy;
	
	bool endgame;
	
	int num_duplicates;
	
	this(int delta_terr_dif, real sc, real[] inpt, int dups, int dec, int strat = -1, bool is_end = false)
	{
		delta_territory_diff = delta_terr_dif;
		score = sc;
		inputs = inpt;
		decision = dec;
		strategy = strat;
		endgame = is_end;
		num_duplicates = dups;
		//write("r");
	}
	
	this(PendingRecord pending, int territory_diff_now, real score_now, bool is_end = false)
	{
		delta_territory_diff = territory_diff_now - pending.territory_diff;
		score = score_now;
		inputs   = pending.inputs;
		decision = pending.decision;
		strategy = pending.strategy;
		endgame = is_end;
		num_duplicates = pending.num_duplicates;
	}
	
	
	void write_to_binary(File f)
	{
		int[]  ints_to_write  = [delta_territory_diff, decision, strategy, num_duplicates];
		real[] reals_to_write = [score];
		bool[] bools_to_write = [endgame];
		
		f.rawWrite (ints_to_write);
		f.rawWrite (reals_to_write);
		f.rawWrite (bools_to_write);
		f.rawWrite (inputs);
		
	}
	
	static CompletedRecord read_from_binary(File f, int num_inputs)
	{
		int [4] ints_to_read;
		real[1] reals_to_read;
		bool[1] bools_to_read;
		real[] inputs_to_read;
		inputs_to_read.length = num_inputs;
		
		f.rawRead(ints_to_read);
		f.rawRead(reals_to_read);
		f.rawRead(bools_to_read);
		f.rawRead(inputs_to_read);
		
		return new CompletedRecord(
								ints_to_read[0],  //delta_territory_diff
								reals_to_read[0], //score
								inputs_to_read,   //inputs
								ints_to_read[3],  //num_duplicates
								ints_to_read[1],  //decision
								ints_to_read[2],  //strategy
								bools_to_read[0]  //endgame
								);
	}
	
	//bool opEquals( ref const CompletedRecord r) const
	override bool opEquals( Object o)
	{
		CompletedRecord r = to!CompletedRecord(o);
		
		if (delta_territory_diff != r.delta_territory_diff ||
			score != r.score ||
			inputs.length != r.inputs.length ||
			decision != r.decision ||
			strategy != r.strategy ||
			endgame != r.endgame ||
			num_duplicates != r.num_duplicates) 
		{
			return false;
		}
		
		foreach( int i, real input ; inputs)
		{
			if(input != r.inputs[i])
				return false;
		}
		
		return true;
	}
	
	void print()
	{
		writefln("d_terr_diff: %d",delta_territory_diff);
		writefln("score: %f",score);
		writefln("input count: %d",inputs.length);
		writefln("decision: %d",decision);
		writefln("strategy: %d",strategy);
		writefln("endgame: %s", endgame? "true":"false");
		foreach( int i, real input ; inputs)
		{
			writef("%d: %f, ",i,input);
		}
		
		writefln("");
	}
}




//-----------------------------------------------------------------------------
// Keeps records for a neural net and trains the net at the end of a match.
// sublasses of this determine the neural net archetecture and how it is trained.
class RecordKeeper
{
	double _last_timestamp = 0.0;
	double _time_window = 1.0; // time between making a decision and recording success or failure based on delta(points controlled - enemy points controlled)
	real _last_score = 0.0;
	int _last_territory_diff = 0;
	DList!PendingRecord _pending_record_queue;	
	CompletedRecord []  _completed_records;
	
	bool victory; // set at end of game
	
	
	this(){
		//TODO: needed?
		//_pending_record_queue = new DList!PendingRecord(0);
		//_pending_record_queue = make!(DList!PendingRecord);
	}
	
	// create a pending record, we add it to closed records when the time-window has elasped.
	// this function is called at the time an order is given.
	void record_decision(real[] inputs, int num_duplicates, int choice, int strategy)
	{
		_pending_record_queue.insert( PendingRecord(_last_territory_diff, _last_timestamp, inputs, num_duplicates, choice, strategy) );
	}
	
	//close all records whose windows have elasped
	void update_records(double now, int territory_diff, real score )
	{
		_last_score = score;
		_last_territory_diff = territory_diff;
		_last_timestamp = now;
		while(!_pending_record_queue.empty && now - _pending_record_queue.front.timestamp >= _time_window)
		{
			close_record(_pending_record_queue.front, false);
			//writefln("record closed: timestamp: %f, now: %f, now - timestamp: %f", _pending_record_queue.front.timestamp, now, now - _pending_record_queue.front.timestamp);
			_pending_record_queue.removeFront();

		}
	}
	
	
	// game is over, so update all pending records 
	void update_records_endgame(bool victory, int territory_diff, real score )
	{
		_last_score = score;
		_last_territory_diff = territory_diff;
		while(!_pending_record_queue.empty)
		{
			close_record(_pending_record_queue.front, true);
			_pending_record_queue.removeFront();
		}
	}
	
	
	void close_record(PendingRecord pending_record, bool endgame)
	{
		_completed_records ~= new CompletedRecord(pending_record, _last_territory_diff, _last_score, endgame);
	}
	
	void set_time_window(double in_window){
		_time_window = in_window;
	}
	
	
	void write_records_to_history( RecordHistory hist )
	{
		if( hist is null)
		{
			writeln("hist is null");
		}
		writefln("writing %d records to file.",_completed_records.length);
		foreach(record ; _completed_records)
		{
			/+
			write("record is: ");
			if( record !is null)
			{
				record.print();
			} else {
				writeln(" null");
			}
			+/
			hist.add_record_to_file(record);
		}
	}
	
	void garbage_collect()
	{
		_completed_records = null;
		GC.collect();
		writeln("Trash out!");
	}
	
	
	void fill_to_n_records_from_history(RecordHistory hist, uint n)
	{
		hist.fill_array_to_n_records(_completed_records, n);
	}
	
}





