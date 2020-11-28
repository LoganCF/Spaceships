module team_strategy;

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
import ai_command_strategy;
import nn_manager;
import nn_manager_classifier;



import dsfml.graphics;
import dsfml.system;
import and.api;


class StrategyTeam : TeamObj
{

	this(TeamID in_id, inout Color in_color, inout char[] in_name, bool in_train = true,
		IActivationFunction in_build_act_fn = null, IActivationFunction in_command_act_fn = null) // will take AI objects.
	{
		super(in_id, in_color, in_name, in_train, in_build_act_fn, in_command_act_fn);
	}
	
	override string generate_display_str()
	{
		return format("Classifier strategy-picker AI using %s", get_ai_actfn_name());
	}
	
	override void init_ais(inout char[] in_name)
	{
		NNManagerBase build_nnm = new NNManagerClassifier(in_name ~ "_build.txt", 
			_build_act_fn);
			//new SigmoidActivationFunction());
		_build_ai   = new BuildAI( build_nnm ); 
		
		NNManagerBase command_nnm = new NNManagerClassifier(in_name ~ "_command.txt",
			_command_act_fn);
			//new SigmoidActivationFunction());
		_command_ai = new StrategyCommandAI( command_nnm  );
	}
}