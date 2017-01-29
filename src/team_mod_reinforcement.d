module team_mod_reinforcement;


/*
Copyright (c) 2017, Logan Freesh
All rights reserved.

See "License.txt"
(It boils down to "do whatever you want, just give me credit if you use this for something")
*/



import std.stdio;
import std.conv;
import std.algorithm.comparison;
import std.format;

import spaceships;
import team;
import steering;
import collision;
import unit;
import factory_unit;

import ai_base;
import ai_command_mod_reinforcement;
import ai_build_mod_reinforcement;


import dsfml.graphics;
import dsfml.system;


class ReinforcementLearningTeam : TeamObj
{
	Font _font; // TODO: should really go somewhere else, like a display class
	Text[] _labels;
	Text   _score_disp;
	real[] _last_output; // last NN output for drawing labels
	bool _labels_inited = false;
	
	this(TeamID in_id, inout Color in_color, inout char[] in_name, bool in_train = true ) // will take AI objects.
	{
		super( in_id, in_color, in_name );
		_font = new Font();
		if (!_font.loadFromFile("font/OpenSans-Regular.ttf"))
		{
			assert(false, "font didn't load");
		}
		_labels.length = NUM_CAPTURE_POINTS;
		
	}

	override void init_ais(inout char[] in_name)
	{
		_build_ai   = new ModifiedReinforcementBuildAI(in_name ~ "_build.txt"    , BUILD_AI_WINDOW ); 
		_command_ai = new ModifiedReinforcementCommandAI(in_name ~ "_command.txt", COMMAND_AI_WINDOW );
	}
	
	override void update_ai_records(double now)
	{
		//writeln(compute_score(this), compute_score(_opponent));
		real score = compute_score(this) - compute_score(_opponent); 
		assert(!isNaN(score));
		_build_ai  .update_records(now, score);
		_command_ai.update_records(now, score);
	}
	
	override int assign_command(Unit unit)
	{
		int retval = super.assign_command(unit);
		
		
		if( ((*_factories).length > 0 && unit == (*_factories)[0])
		  ||((*_factories).length > 1 && unit == (*_factories)[1])) // TODO: this better
		{
			_last_output = _command_ai._backprop.lastOutput(); // to update display
			
		}
		return retval;
	}
	
	
	override void draw(RenderTarget renderTarget, RenderStates renderStates)
	{
		if(!_labels_inited)
		{
			foreach( i, ref label; _labels)
			{
				_labels[i] = new Text();
				//writeln(i, _points.length);
				Vector2!float offset = _id == TeamID.One ? Vector2!float(10.0, -20.0) : Vector2!float(10.0, 25.0);
				label.position = to!(Vector2!float)(_points[i]._pos) + offset; 
				label.setFont(_font); 
				label.setCharacterSize(10);
				label.setColor(_color);

			}
			_score_disp = new Text();
			Vector2!float offset = _id == TeamID.One ? Vector2!float(0.0, 0.0) : Vector2!float(50.0, 0.0);
			_score_disp.position = Vector2!float(25, 60) + offset; 
			_score_disp.setFont(_font); 
			_score_disp.setCharacterSize(14);
			_score_disp.setColor(_color);
			
			_labels_inited = true;
		}
		
		if(_last_output.length > 0)
		{
			foreach(int i, ref label; _labels)
			{
				label.setString(format("%+#.3f",_last_output[i] /+ - _command_ai._last_score+/) );
				renderTarget.draw(label);
			}
		}
		
		_score_disp.setString( format("%+#.3f",_command_ai._last_score) );
		renderTarget.draw(_score_disp);
		
		super.draw(renderTarget, renderStates);
	}
	
	
}




// computes a score in the approximate range [-1.0, 1.0] It can go a bit over or under becasue we use ReLUs in the AI (which are not bound to that range)
	// the opponent's score should be subtracted from this TODO: rename this function
	real compute_score(TeamObj t)
	{
		// each metric is divided by a reasonable maxiumum
		/* 	  1/3 * points_capped/12 points 
			+ 1/3 * income / (income form 12 points + default income + 1 miner at each point)
			+ 1/3 * army strength / 20 battleships
		*/
		//writefln("pts: %d, income: %f * %d, army: %f", t._num_points_owned, t._income_per_factory, t._num_factories, t._total_army_value);
		assert(!isNaN(t._income_per_factory), "income is NaN" );
		assert(!isNaN(t._total_army_value)  , "army is NaN" );
		real retval = 1.0/3.0 * t._num_points_owned / NUM_CAPTURE_POINTS
					+ 1.0/3.0 * t._income_per_factory * t._num_factories / (INCOME_BASE + INCOME_PER_POINT * NUM_CAPTURE_POINTS + INCOME_PER_POINT * TeamObj.MINER_INCOME_FRACTION * NUM_CAPTURE_POINTS )
					+ 1.0/3.0 * t._total_army_value / (get_unit_build_cost(UnitType.Battleship) * 20) ;
					
		if(retval >  1.0){ retval =  1.0; }
		if(retval < -1.0){ retval = -1.0; }
		return retval;
	}
