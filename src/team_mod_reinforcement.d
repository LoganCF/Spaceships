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
import ai_build;
import ai_command;
import nn_manager;
import nn_manager_mod_reinforcement;
//import ai_command_mod_reinforcement;
//import ai_build_mod_reinforcement;


import dsfml.graphics;
import dsfml.system;
import and.api;


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
		NNManagerBase build_nnm = new NNManagerModReinforcement(in_name ~ "_build.txt"    ,new SigmoidActivationFunction());
		_build_ai   = new BuildAI( build_nnm ); 
		
		NNManagerBase command_nnm = new NNManagerModReinforcement(in_name ~ "_command.txt",new SigmoidActivationFunction());
		_command_ai = new CommandAI( command_nnm  );
	}
	
	/+
	override void update_ai_records(double now)
	{
		//writeln(compute_score(this), compute_score(_opponent));
		real score = get_score_diff(); 
		int terr_diff = get_territory_diff();
		assert(!isNaN(score));
		_build_ai  .update_records(now, score);
		_command_ai.update_records(now, score);
	}+/
	
	override int assign_command(Unit unit)
	{
		int retval = super.assign_command(unit);
		
		
		if( ((*_factories).length > 0 && unit == (*_factories)[0])
		  ||((*_factories).length > 1 && unit == (*_factories)[1])) // TODO: this better
		{
			_last_output = _command_ai._nn_mgr._backprop.lastOutput(); // to update display //TODO: bad oop
			
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
				label.position.x = to!int(label.position.x);
				label.position.y = to!int(label.position.y);
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
		
		_score_disp.setString( format("%+#.3f",_command_ai._record_keeper._last_score) );
		renderTarget.draw(_score_disp);
		
		super.draw(renderTarget, renderStates);
	}
	
	
}





