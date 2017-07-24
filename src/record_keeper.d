module record_keeper;


import std.random;
import std.math;
import std.container.dlist;
import std.container.util;
import std.algorithm.comparison;	

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
struct CompletedRecord
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
	
	
}


//-----------------------------------------------------------------------------
// Keeps records for a neural net and trains the net at the end of a match.
// sublasses of this determine the neural net archetecture and how it is trained.
class RecordKeeper
{
	double _last_timestamp;
	double _time_window; // time between making a decision and recording success or failure based on delta(points controlled - enemy points controlled)
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
	//TODO: this needs to interact with strategy
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
			_pending_record_queue.removeFront();
		}
	}
	
	
	// game is over, so update all pending records based on change in score
	// last score reported in update_records is used as current score.
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
		_completed_records ~= CompletedRecord(pending_record, _last_territory_diff, _last_score, endgame);
	}
	
	void set_time_window(double in_window){
		_time_window = in_window;
	}
	
}



