module team_mod_r_strat;

import team;
import team_mod_reinforcement;
import ai_base;
import ai_build;
import ai_command;
import ai_command_strategy;
import nn_manager;
import nn_manager_mod_reinforcement;
import strategies;


import dsfml.graphics;
import dsfml.system;
import and.api;

import std.conv;
import std.format;



class ReinforcementLearningStrategyTeam : ReinforcementLearningTeam
{
	this(TeamID in_id, inout Color in_color, inout char[] in_name, bool in_train = true,
		IActivationFunction in_build_act_fn = null, IActivationFunction in_command_act_fn = null, int[] in_nn_archi = [] ) // will take AI objects.
	{
		super(in_id, in_color, in_name, in_train, in_build_act_fn, in_command_act_fn, in_nn_archi);
		_labels.length = g_strategies.length;
	}
	
	override string generate_display_str()
	{
		return format("Mod-R strategy-picker AI using %s", get_ai_actfn_name());
	}

	override void init_ais(inout char[] in_name, int[] nn_archi)
	{
		NNManagerBase build_nnm   = new NNManagerModReinforcement(in_name ~ "_build.txt"  ,
			_build_act_fn);
		_build_ai   = new BuildAI( build_nnm ); 
		
		NNManagerBase command_nnm = new NNManagerModReinforcement(in_name ~ "_command.txt", 
			_command_act_fn);
		_command_ai = new StrategyCommandAI( command_nnm );
	}
	
	override void position_labels()
	{
		foreach( i, ref label; _labels)
		{
			Vector2!float offset = _input_disp._base_position + Vector2f(0, _input_disp.size().y + 30);
			label.position = Vector2!float(0.0, i * 12.0 ) + offset; 
			label.position.x = to!int(label.position.x);
			label.position.y = to!int(label.position.y);
		}
	}
	
	override void set_label_text()
	{
		foreach(int i, ref label; _labels)
		{
			label.setString(format("%5s: %+#.3f",g_strategies[i]._name, _last_output[i] ) );
		}
	}
	
}