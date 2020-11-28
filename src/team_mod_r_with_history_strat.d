module team_mod_r_with_history_strat;

import team;
import team_mod_reinforcement;
import team_mod_r_strat;
import ai_base;
import ai_build;
import ai_command;
import ai_command_strategy;
import nn_manager;
import nn_manager_mod_r_with_history;
import strategies;


import dsfml.graphics;
import dsfml.system;
import and.api;

import std.conv;
import std.format;

//regular team_mod_r_with_history doesn't have much in it, so we can sidestep the diamond problem and only duplicate a *little* code
class ReinforcementLearningStrategyTeamWithHistory : ReinforcementLearningStrategyTeam
{
	this(TeamID in_id, inout Color in_color, inout char[] in_name, bool in_train = true,
		IActivationFunction in_build_act_fn = null, IActivationFunction in_command_act_fn = null) // will take AI objects.
	{
		super(in_id, in_color, in_name, in_train, in_build_act_fn, in_command_act_fn);
	}
	
	override string generate_display_str()
	{
		return format("Mod-R strategy-picker AI with history using %s", get_ai_actfn_name());
	}

	override void init_ais(inout char[] in_name)
	{
		NNManagerBase build_nnm   = new NNManagerModReinforcementWithHistory(in_name ~ "_build.txt"  ,
			_build_act_fn);
		_build_ai   = new BuildAI( build_nnm ); 
		
		NNManagerBase command_nnm = new NNManagerModReinforcementWithHistory(in_name ~ "_command.txt", 
			_command_act_fn);
		_command_ai = new StrategyCommandAI( command_nnm, );
	}
	
}