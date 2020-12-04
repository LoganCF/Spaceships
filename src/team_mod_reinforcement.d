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

	Text[] _labels;
	Text   _score_disp;
	Text[] _score_breakdown;
	static string[] s_score_prefixes = ["CPs:  ", "VPs:  ", "Army: ", "Econ: "];
	
	real[] _last_output; // last NN output for drawing labels
	bool _labels_inited = false;
	
	this(TeamID in_id, inout Color in_color, inout char[] in_name, bool in_train = true,
		IActivationFunction in_build_act_fn = null, IActivationFunction in_command_act_fn = null) // will take AI objects.
	{
		super( in_id, in_color, in_name, in_train, in_build_act_fn, in_command_act_fn );
		_labels.length = NUM_CAPTURE_POINTS;
		_score_breakdown.length = 4;
		
	}
	
	override string generate_display_str()
	{
		return format("Mod-R AI using %s", get_ai_actfn_name());
	}

	override void init_ais(inout char[] in_name)
	{
		NNManagerBase build_nnm = new NNManagerModReinforcement(in_name ~ "_build.txt", 
			_build_act_fn);
			//new SigmoidActivationFunction());
		_build_ai   = new BuildAI( build_nnm ); 
		
		NNManagerBase command_nnm = new NNManagerModReinforcement(in_name ~ "_command.txt",
			_command_act_fn);
			//new SigmoidActivationFunction());
		_command_ai = new CommandAI( command_nnm  );
	}
	
	override void ensure_act_fns()
	{
		if (_build_act_fn is null)
			_build_act_fn = new TanhActivationFunction();
		if (_command_act_fn is null)
			_command_act_fn = new TanhActivationFunction();
	}
	
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
	
	
	
	void init_labels()
	{
		foreach( i, ref label; _labels)
		{
			_labels[i] = new Text();
			//writeln(i, _points.length);
			label.setFont(ensure_font()); 
			label.setCharacterSize(10);
			label.setColor(_color);

		}
		position_labels();
		
		_score_disp = new Text();
		Vector2!float offset = _id == TeamID.One ? Vector2!float(0.0, 0.0) : Vector2!float(150.0, 0.0);
		_score_disp.position = Vector2!float(5, 50) + offset; 
		_score_disp.setFont(ensure_font()); 
		_score_disp.setCharacterSize(14);
		_score_disp.setColor(_color);
		
		foreach( i, ref label; _score_breakdown)
		{
			_score_breakdown[i] = new Text();
			//writeln(i, _points.length);
			label.setFont(ensure_font()); 
			label.setCharacterSize(12);
			label.setColor(_color);
			label.position = _score_disp.position + Vector2f(5.0f, (i+1)*15.0f);
		}
		
		_labels_inited = true;
	}
	
	void position_labels()
	{
		foreach( i, ref label; _labels)
		{
			Vector2!float offset = _id == TeamID.One ? Vector2!float(10.0, -20.0) : Vector2!float(10.0, 25.0);
			label.position = to!(Vector2!float)(_points[i]._pos) + offset; 
			label.position.x = to!int(label.position.x);
			label.position.y = to!int(label.position.y);
		}
	}
	
	void set_label_text()
	{
		foreach(int i, ref label; _labels)
		{
			label.setString(format("%+#.3f",_last_output[i] /+ - _command_ai._last_score+/) );
		}
	}
	
	override void draw(RenderTarget renderTarget, RenderStates renderStates)
	{
		if(!_labels_inited)
		{
			init_labels();
		}
		
		if(_last_output.length > 0)
		{
			set_label_text();
			foreach(int i, ref label; _labels)
			{
				renderTarget.draw(label);
			}
		}
		
		_score_disp.setString( format("%+#.3f", _score_data.score));//_command_ai._record_keeper._last_score) );
		renderTarget.draw(_score_disp);
		foreach(int i, ref label; _score_breakdown)
		{
			label.setString( format("%s%+#.3f", s_score_prefixes[i], _score_data[i] ));
			renderTarget.draw(label);
		}
		
		
		super.draw(renderTarget, renderStates);
	}
	
	
}





