module spaceships;


/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.math;
import std.random;	
import std.stdio;
import std.conv;
import std.algorithm;
import std.algorithm.mutation;
import std.algorithm.iteration;
import std.algorithm.searching;
import std.typecons;
import std.file;
import std.array;

import core.memory;

import mathutil;
import steering;
import collision;
import unit;
import factory_unit;
import capture_point;
import team;
import team_manual;
import team_random;
import team_scripted_capper;
import team_scripted_defender;
import team_scripted_aggro;
import team_scripted_boom;
import team_scripted_capper2;
import team_scripted_assassin;
import team_single_strategy;
import team_mod_reinforcement;
import team_mod_r_strat;
import team_mod_r_with_history;
import team_mod_r_with_history_strat;
import team_strategy;
import ai_base;
import ai_build;
import ai_command;
import matchinfo;
import strategy;
import strategies;
import explosion;
import record_history;

import nn_manager_mod_r_with_history; // TODO: temp, we can remove this with better abstraction;

import dsfml.graphics;
import dsfml.system;
import and.api;


const int NUM_CAPTURE_POINTS = 12;

//TODO: deal with these better, some won't be needed
const Color steel_blue   = Color(0x46, 0x82, 0xB4);
const Color dark_green   = Color(0x00, 0x64, 0x00);
const Color forest_green = Color(0x22, 0x8B, 0x22);
//DarkSlateBlue  	#483D8B




struct NamedColor
{
	this(Color in_c, string in_n)
	{
		c = in_c;
		n = in_n;
	}
	
	this(ubyte r, ubyte g, ubyte b, string in_n)
	{
		c = Color(r,g,b);
		n = in_n;
	}
	
	Color  c;
	string n;
}

enum AiType { NeuralNet, NeuralNetDontTrain, NeuralNetModReinforcement, NeuralNetModRWithHistory, NeuralNetModRWithHistoryStrat, NeuralNetStrat, NeuralNetModRStrat,
			   Manual, 
			   // only scripted ais after this point.
			   Random, ScriptedCapper, ScriptedDefender, ScriptedAggro, ScriptedBoom, ScriptedCapper2, ScriptedAssassin,
			   Strategy1, Strategy2, Strategy3, Strategy4, Strategy5, Strategy6, Strategy7, Strategy8, Strategy9, Strategy10};
enum ActFnType { Default, Sigmoid, ReLU, Tanh, ReLU6 };
enum NNArchi: int[] { Smol = [144], Standard = [144, 48], ThiccBoi = [96, 72, 60, 48]};


struct PlayerIdentity
{
  string n;
  Color c;
  AiType type;
  ActFnType act_fn;
  int[] nn_archi;
  
  this(string in_n, Color in_c, AiType in_type, ActFnType in_act_fn = ActFnType.Default, int[] in_nn_archi = NNArchi.Standard)
  {
	n = in_n;
	c = in_c;
	type = in_type;
	act_fn = in_act_fn;
	nn_archi = in_nn_archi;
  }
  bool is_scripted()
  {
	return type >= AiType.Random;
  }
  
}

/+
NamedColor[]  AI_colors = [  NamedColor(0xFF, 0x00, 0x00, "Red")
							,NamedColor(0x46, 0x82, 0xB4, "SteelBlue") 
							];
	+/						

/+
NamedColor[]  AI_colors = [  NamedColor(0xFF, 0x00, 0x00, "Red")
							,NamedColor(0x46, 0x82, 0xB4, "SteelBlue")
							,NamedColor(0x7F, 0xFF, 0x00, "Chartreuse")
							,NamedColor(0xFF, 0x7F, 0x50, "Coral")
							//,NamedColor(0x00, 0x64, 0x00, "DarkGreen")
							//,NamedColor(0xFF, 0x8C, 0x00, "DarkOrange")
							//,NamedColor(0x55, 0x6B, 0x2F, "DarkOliveGreen")
							,NamedColor(0x94, 0x00, 0xD3, "DarkViolet")
							//,NamedColor(0x00, 0xCE, 0xD1, "DarkTurquiose")
							,NamedColor(0xFF, 0x14, 0x93, "DeepPink")
							,NamedColor(0x40, 0x40 ,0x40, "▀▀▄▐▄█▀█▄▌█▀ ▌▌▌")
							];
							
							//,NamedColor(0xDC, 0x14, 0x3C, "Crimson")
			  
			  //,NamedColor(0xFF,0xCC,0x00, "Yellow")
			  +/
			  
PlayerIdentity[]  ai_identities = [  
						  /+
						   PlayerIdentity( "Red"       , Color(0xFF, 0x00, 0x00), AiType.NeuralNet)
						  //,PlayerIdentity( "SteelBlue" , Color(0x46, 0x82, 0xB4), AiType.NeuralNet)
						  //,PlayerIdentity( "Chartreuse", Color(0x7F, 0xFF, 0x00), AiType.NeuralNet)
						  ,PlayerIdentity( "SteelBlue_MRL"  , Color(0x46, 0x82, 0xB4), AiType.NeuralNetModReinforcement)
						  ,PlayerIdentity( "Chartreuse_MRLH", Color(0x7F, 0xFF, 0x00), AiType.NeuralNetModRWithHistory)
						  ,PlayerIdentity( "Coral_MRLH"     , Color(0xFF, 0x7F, 0x50), AiType.NeuralNetModRWithHistory)
						  //,PlayerIdentity( "Coral"     , Color(0xFF, 0x7F, 0x50), AiType.NeuralNet)
						  //,PlayerIdentity( "DarkViolet", Color(0x94, 0x00, 0xD3), AiType.NeuralNet)
						  //,PlayerIdentity( "DeepPink"  , Color(0xFF, 0x14, 0x93), AiType.NeuralNet)
						  ,PlayerIdentity( "DarkGrey"  , Color(0x60, 0x60 ,0x60), AiType.NeuralNetDontTrain)
						  /+
						  ,PlayerIdentity( "Coral_MRL"     , Color(0xFF, 0x7F, 0x50), AiType.NeuralNetModReinforcement)
						  ,PlayerIdentity( "DarkViolet_MRL", Color(0x94, 0x00, 0xD3), AiType.NeuralNetModReinforcement)
						  ,PlayerIdentity( "DeepPink_MRL"  , Color(0xFF, 0x14, 0x93), AiType.NeuralNetModReinforcement)
						  ,PlayerIdentity( "DarkOliveGreen_MRL",Color(0x55,0x6B,0x2F), AiType.NeuralNetModReinforcement)
						  +/
						  ,PlayerIdentity( "YellowOrange",Color(0xFF,0xCC,0x00), AiType.Random)
							//,NamedColor(0x00, 0x64, 0x00, "DarkGreen")
							//,NamedColor(0xFF, 0x8C, 0x00, "DarkOrange")
						  ,PlayerIdentity("DarkTurquiose", Color(0x00, 0xCE, 0xD1), AiType.ScriptedCapper)
						  //,PlayerIdentity("Blue"         , Color(0x00, 0x00, 0xFF), AiType.ScriptedDefender)
						  //,PlayerIdentity( "YellowOrange", Color(0xFF, 0xE0, 0x80), AiType.NeuralNetDontTrain)
						  //,PlayerIdentity("DarkTurquiose", Color(0x80, 0xF0, 0xE0), AiType.NeuralNetDontTrain)
						  //,PlayerIdentity("Blue"         , Color(0x80, 0x80, 0xFF), AiType.NeuralNetDontTrain)
						  +/
						  
						  
						  /+
						   PlayerIdentity( "Red_modr_strat"       , Color(0xFF, 0x00, 0x00), AiType.NeuralNetModRStrat, ActFnType.ReLU)
						  ,PlayerIdentity( "DeepPink_strat"  , Color(0xFF, 0x14, 0x93), AiType.NeuralNetStrat)
						  ,PlayerIdentity( "DarkViolet", Color(0x94, 0x00, 0xD3), AiType.NeuralNetModRWithHistoryStrat, ActFnType.ReLU)
						  ,PlayerIdentity( "SteelBlue" , Color(0x46, 0x82, 0xB4), AiType.NeuralNet)
						  ,PlayerIdentity( "Blue_NN_RELU"         , Color(0x00, 0x00, 0xFF), AiType.NeuralNet, ActFnType.ReLU)
						  ,PlayerIdentity( "Chartreuse_MRLH", Color(0x7F, 0xFF, 0x00), AiType.NeuralNetModRWithHistory, ActFnType.ReLU)
						  ,PlayerIdentity( "DarkOliveGreen",Color(0x55,0x6B,0x2F), AiType.NeuralNetModReinforcement, ActFnType.ReLU)
						  ,PlayerIdentity( "DarkTurquiose__", Color(0x00, 0xCE, 0xFF), AiType.Strategy4)
						  +/

						/+
						   PlayerIdentity( "Coral_MRLH"     , Color(0xFF, 0x7F, 0x50), AiType.NeuralNetModRWithHistoryStrat, ActFnType.Tanh)
						  ,PlayerIdentity( "Chartreuse_MRLH", Color(0x7F, 0xFF, 0x00), AiType.NeuralNetModRWithHistoryStrat, ActFnType.ReLU)
						  ,PlayerIdentity( "YellowOrange"   , Color(0xFF, 0xCC, 0x00), AiType.NeuralNetModRWithHistoryStrat, ActFnType.Sigmoid)
						  ,PlayerIdentity( "SkyBlue"        , Color(0x70, 0xFF, 0xC0), AiType.NeuralNetModRWithHistoryStrat, ActFnType.ReLU6)
						  ,PlayerIdentity( "SteelBlue"      , Color(0x46, 0x82, 0xB4), AiType.NeuralNetModRWithHistoryStrat, ActFnType.ReLU, NNArchi.ThiccBoi)
						  ,PlayerIdentity( "DeepPink" , Color(0xFF, 0x14, 0x93), AiType.NeuralNetModRWithHistory, ActFnType.ReLU)
						  ,PlayerIdentity( "DarkTurquiose"  , Color(0x00, 0xCE, 0xD1), AiType.ScriptedCapper)
						  ,PlayerIdentity( "Red_aggro"      , Color(0xFF, 0x00, 0x00), AiType.ScriptedAggro)
						  ,PlayerIdentity( "Pink_boom"      , Color(0xFF, 0x69, 0xb4), AiType.ScriptedBoom)
						 +/

						   
						  
						   //PlayerIdentity( "YellowOrange"   , Color(0xFF, 0xCC, 0x00), AiType.NeuralNetModRWithHistoryStrat, ActFnType.Sigmoid)
						  //,PlayerIdentity( "Coral     "     , Color(0xFF, 0x7F, 0x50), AiType.NeuralNetModRWithHistoryStrat, ActFnType.Sigmoid, NNArchi.ThiccBoi)
						  PlayerIdentity( "DarkViolet_"     , Color(0x94, 0x00, 0xD3), AiType.NeuralNetModRWithHistoryStrat, ActFnType.ReLU)
						  //,PlayerIdentity( "DeepPink_"       , Color(0xFF, 0x14, 0x93), AiType.NeuralNetModRWithHistoryStrat, ActFnType.ReLU, NNArchi.ThiccBoi)
						  ,PlayerIdentity( "Chartreuse_"     , Color(0x7F, 0xFF, 0x00), AiType.NeuralNetModRWithHistoryStrat, ActFnType.ReLU6)
						  //,PlayerIdentity( "Aquamarine_"     , Color(0x70, 0xFF, 0xC0), AiType.NeuralNetModRWithHistoryStrat, ActFnType.ReLU6, NNArchi.ThiccBoi)
						  ,PlayerIdentity( "DarkTurquiose"  , Color(0x00, 0xCE, 0xD1), AiType.ScriptedCapper2)
						  ,PlayerIdentity( "DarkRed"        , Color(0xB2, 0x22, 0x22), AiType.ScriptedAssassin)
						  ,PlayerIdentity( "Red_aggro"      , Color(0xFF, 0x00, 0x00), AiType.ScriptedAggro)
						  ,PlayerIdentity( "Pink_boom"      , Color(0xFF, 0x69, 0xb4), AiType.ScriptedBoom)
						  
						  
						  
						  
						  /+
						  // strategy testing group
						  ,PlayerIdentity( "Red"       , Color(0xFF, 0x00, 0x00), AiType.Strategy1)
						  ,PlayerIdentity( "SteelBlue" , Color(0x46, 0x82, 0xB4), AiType.Strategy2)
						  ,PlayerIdentity( "Chartreuse", Color(0x7F, 0xFF, 0x00), AiType.Strategy3)
						  ,PlayerIdentity( "Coral"     , Color(0xFF, 0x7F, 0x50), AiType.Strategy4)
						  ,PlayerIdentity( "DarkGrey"  , Color(0x60, 0x60 ,0x60), AiType.Strategy5)
						  ,PlayerIdentity( "DarkViolet", Color(0x94, 0x00, 0xD3), AiType.Strategy6)
						  ,PlayerIdentity( "DeepPink"  , Color(0xFF, 0x14, 0x93), AiType.Strategy7)
						  ,PlayerIdentity( "YellowOrange", Color(0xFF, 0xE0, 0x80), AiType.Strategy8)
						  ,PlayerIdentity("DarkTurquiose", Color(0x80, 0xF0, 0xE0), AiType.Strategy9)
						  ,PlayerIdentity( "DarkOliveGreen",Color(0x55,0x6B,0x2F), AiType.Strategy10)
						  +/
							];
			  
PlayerIdentity manual_identity = PlayerIdentity( "DarkGrey",forest_green,AiType.Manual);
							
							//,NamedColor(0xDC, 0x14, 0x3C, "Crimson")
							
int[string] win_counts;
int[string] loss_counts;
alias Tuple!(string,string) countvskey;
int[countvskey] win_counts_vs; // win_counts_vs[A][B] is the number of games A has won against B.
int[countvskey] loss_counts_vs;

//factory function for various kinds of TeamObj
TeamObj make_team(TeamID id, PlayerIdentity player_identity)
{
  IActivationFunction build_fn = make_build_fn(player_identity.act_fn);
  IActivationFunction command_fn = make_command_fn(player_identity.act_fn);
  
  final switch(player_identity.type)
  {
	case AiType.NeuralNet:
		return new TeamObj   (id, player_identity.c, player_identity.n, true, build_fn, command_fn, player_identity.nn_archi);
	case AiType.NeuralNetDontTrain:
		return new TeamObj   (id, player_identity.c, player_identity.n, false, build_fn, command_fn, player_identity.nn_archi);
	case AiType.NeuralNetModReinforcement:
		return new ReinforcementLearningTeam(id, player_identity.c, player_identity.n, true, build_fn, command_fn, player_identity.nn_archi);
	case AiType.NeuralNetModRWithHistory:
		return new ReinforcementLearningTeamWithHistory(id, player_identity.c, player_identity.n, true, build_fn, command_fn, player_identity.nn_archi);
	case AiType.Random:
		return new RandomTeam(id, player_identity.c, player_identity.n);
	case AiType.Manual:
		return new PlayerTeam(id, player_identity.c, player_identity.n, "Player", build_fn, command_fn, player_identity.nn_archi);
	case AiType.ScriptedCapper:
		return new CapperTeam(id, player_identity.c, player_identity.n);
	case AiType.ScriptedCapper2:
		return new ScriptedCapper2Team(id, player_identity.c, player_identity.n);
	case AiType.ScriptedDefender:
		return new DefenderTeam(id, player_identity.c, player_identity.n);
	case AiType.Strategy1: case AiType.Strategy2: case AiType.Strategy3: case AiType.Strategy4: case AiType.Strategy5: 
	case AiType.Strategy6: case AiType.Strategy7: case AiType.Strategy8: case AiType.Strategy9: case AiType.Strategy10:
		return new SingleStrategyTeam(id, player_identity.c, player_identity.n, to!(int)(player_identity.type - AiType.Strategy1));
	case AiType.NeuralNetModRWithHistoryStrat:
		return new ReinforcementLearningStrategyTeamWithHistory(id, player_identity.c, player_identity.n, true, build_fn, command_fn, player_identity.nn_archi);
	case AiType.NeuralNetStrat:
		return new StrategyTeam(id, player_identity.c, player_identity.n, true, build_fn, command_fn, player_identity.nn_archi);
	case AiType.NeuralNetModRStrat:
		return new ReinforcementLearningStrategyTeam(id, player_identity.c, player_identity.n, true, build_fn, command_fn, player_identity.nn_archi);
	case AiType.ScriptedAggro:
		return new ScriptedAggroTeam(id, player_identity.c, player_identity.n);
	case AiType.ScriptedBoom:
		return new ScriptedBoomerTeam(id, player_identity.c, player_identity.n);
	case AiType.ScriptedAssassin:
		return new ScriptedAssassinTeam(id, player_identity.c, player_identity.n);
	
  }
}

IActivationFunction make_build_fn(ActFnType type)
{
	final switch (type)
	{
		case ActFnType.Default:
			return null; //TeamObj supplies the act_fn in this case
		case ActFnType.Sigmoid:
			return new SigmoidActivationFunction();
		case ActFnType.ReLU:
			return new LeakyReLUActivationFunction();
		case ActFnType.Tanh:
			return new TanhActivationFunction();
		case ActFnType.ReLU6:
			return new LeakyReLU6ActivationFunction();
	}
}

IActivationFunction make_command_fn(ActFnType type)
{
	// there might be types that specify different act_fns for build and command in the future, but it is not this day.
	return make_build_fn(type);
}
			  

//this should go in an env object or something
TeamObj[] g_teams = [
					null,
					null,
					new TeamObj(TeamID.Neutral, Color.White, "" )
				 ];

RectangleShape[] g_ticket_bars = [
								   null,
								   null
							     ];
								 
RectangleShape g_timer_bar;
				 
const double g_starting_tickets = 600.0;				 
				 
				 
bool g_is_manual_game = false; // TODO: this should be one of the parameters to run match.
				 
void main(string[] args)
{
	auto window = new RenderWindow(VideoMode(window_width,window_height),"AI: Artifical Idiocy");
	
	while( window.isOpen() )
	{
		if(args.length == 1)
			run_tourney(args, window);
		else
		if(args[1] == "play")
		{
			run_manual(args[2..$], window);
		} else if (args[1] == "tourney")
		{
			run_tourney(args[2..$], window);
		} else if(args[1] == "duel")
		{
			run_duel(args[2..$], window);
		} else if(args[1] == "nemesis")
		{
			run_duel_manual(args[2..$], window);
		} else if(args[1] == "train")
		{
			run_training(args[2..$], window);
		}else 
		{
			run_tourney(args, window);
		}
		
		//g_teams[0] = new TeamObj(TeamID.One,     AI_colors[0].c , AI_colors[0].n);
		//g_teams[1] = new TeamObj(TeamID.Two,     AI_colors[1].c , AI_colors[1].n);
		//run_match(args, window);
		
		
	}
}

string TOURNEY_FILE = "nets\\_tourney_state.txt";

void run_tourney(string [] args, RenderWindow window)
{
	static bool allow_scripted_vs_scripted = false; // TODO: read from params
	
	//load position
	int[2] result;
	result = read_tourney_state();
	string state_string;
	
	///result = [0,1]; ///
	writefln("loaded state %s, %s", result[0], result[1]);
	
	for( int challenger = result[0] ; challenger < ai_identities.length && window.isOpen(); ++challenger )
	{
		for( int opponent = result[1] ; opponent   < ai_identities.length && window.isOpen(); ++opponent )
		{
			if(challenger != opponent && 
				(allow_scripted_vs_scripted || 
				(!ai_identities[challenger].is_scripted()) || !ai_identities[opponent].is_scripted()) )
			{
				//save position
				write_tourney_state(challenger, opponent);
				
				if(g_teams[0] !is null) { destroy(g_teams[0]); }
				if(g_teams[1] !is null) { destroy(g_teams[1]); }
				
				g_teams[0] = make_team(TeamID.One, ai_identities[challenger]);
				g_teams[1] = make_team(TeamID.Two, ai_identities[opponent]  );
				run_match(args, window);
				GC.collect();
			}
		}
		result[1] = 0;
		
	}
	
	// save poition 0,1 for next tourney
	if( window.isOpen() )
	{
		write_tourney_state(0, 1);
	}
}

void write_tourney_state(int p1, int p2)
{
	File f;
	f.open(TOURNEY_FILE, "w");
	//write last opponents
	f.writefln("%d,%d", p1, p2);
	scope (exit) 
	{
		f.close();
	}
	
	// write win counts by player
	// name win/loss,
	foreach (name; win_counts.byKey())
	{
		f.writefln("%s: %d/%d", name, win_counts[name], loss_counts[name]);
	}
	
	if (win_counts.length == 0)
		return;
	int maxlen = win_counts.byKey().map!(a => a.length).reduce!((a,b)=>max(a,b)); //func yeah.
	//write win counts vs
	//name vs opp1: win/loss, vs opp2: win/loss
	foreach(name ; win_counts.byKey())
	{
		f.writef("%*s ", maxlen, name);
		foreach(name2 ; win_counts.byKey())
		{
			countvskey key = countvskey(name, name2);
			int won  = key in  win_counts_vs ?  win_counts_vs[key] : 0;
			int lost = key in loss_counts_vs ? loss_counts_vs[key] : 0;
			f.writef("vs %*s: %d/%d, ", maxlen, name2, won, lost);
		}
		f.writeln();
	}
}

int[2] read_tourney_state()
{
	if(!exists(TOURNEY_FILE))
		return [0, 1];
	//TODO: the rest of that stuff from above
	
	File f;
	f.open(TOURNEY_FILE, "r");
	int[2] result;
	f.readf("%d,%d\n", &result[0], &result[1]);
	
	
	f.close();
	return result;
}

void run_manual(string [] args, RenderWindow window)
{
	//"▀▀▄▐▄█▀█▄▌█▀ ▌▌▌" 
	
	g_is_manual_game = true;
	
	for( int opponent = 0 ; opponent < ai_identities.length && window.isOpen(); ++opponent )
	{
	
		if(g_teams[0] !is null) { destroy(g_teams[0]); }
		if(g_teams[1] !is null) { destroy(g_teams[1]); }
		
		PlayerTeam pt =  to!PlayerTeam( make_team(TeamID.One, manual_identity) );
		g_teams[0]    = pt;
		g_teams[1]    = make_team(TeamID.Two, ai_identities[opponent]);
		
		pt.set_window(window);
		run_match(args, window);
		GC.collect();
	
	}
}


void run_duel(string [] args, RenderWindow window)
{	
	g_is_manual_game = false;
	
	int player_1 = to!int(args[0]);
	int player_2 = to!int(args[1]);
	
	while(window.isOpen())
	{
		
		if(g_teams[0] !is null) { destroy(g_teams[0]); }
		if(g_teams[1] !is null) { destroy(g_teams[1]); }
		
		g_teams[0]    = make_team(TeamID.One, ai_identities[player_1] );
		g_teams[1]    = make_team(TeamID.Two, ai_identities[player_2] );
		
		run_match(args[2..$], window);
		GC.collect();
	
		//swap starting locations
		int temp = player_1;
		player_1 = player_2;
		player_2 = temp;
	}
}

void run_duel_manual(string [] args, RenderWindow window)
{
	
	g_is_manual_game = true;
  
  bool swap_positions = false;
	
	while(window.isOpen())
	{
		int opponent =  to!int(args[0]);
		
		if(g_teams[0] !is null) { destroy(g_teams[0]); }
		if(g_teams[1] !is null) { destroy(g_teams[1]); }
		
	PlayerTeam pt;
	
	if(!swap_positions) 
	{      
	  pt            = to!PlayerTeam( make_team(TeamID.One, manual_identity) );
	  g_teams[0]    = pt;
	  g_teams[1]    = make_team(TeamID.Two, ai_identities[opponent]);
	} else {
	  g_teams[0]    = make_team(TeamID.One, ai_identities[opponent]);
	  pt            =  to!PlayerTeam( make_team(TeamID.Two, manual_identity) );
	  g_teams[1]    = pt;
	}
	
	swap_positions = !swap_positions;
		
		pt.set_window(window);
		run_match(args[1..$], window);
		GC.collect();
	
	}
}


void run_training (string [] args, RenderWindow window)
{
	g_is_manual_game = false;
	
	int player_id;
	string what_ai = "both";
	int num_records = -1;
	int num_epochs  = -1;
	real error_threshold = -1;
	
	if (args.length >= 1)
	{
		player_id = to!int(args[0]);
	} else {
		writeln("player# required");
		return;
	}
	if (args.length >= 2)
		what_ai = args[1];
	if (args.length >= 3)
		num_records = to!int(args[2]);
	if (args.length >= 4)
		num_epochs = to!int(args[3]);
	if (args.length >=5)
		error_threshold = to!(real)(args[4]);
	
	
	bool train_build = false;
	bool train_command = false;
	if (what_ai == "both")
	{
		train_build = true;
		train_command = true;
	} else if  (what_ai == "command")
	{
		train_command = true;
	} else if  (what_ai == "build")
	{
		train_build = true;
	} else 
	{
		writefln("invalid value '%s' for ai, use (both|command|build)", what_ai);
	} 
	g_teams[0]   = make_team(TeamID.One, ai_identities[player_id] );
	TeamObj team = g_teams[0];
	
	//TODO: abstract out the history stuff so we can use it on nets that don't normally use it.
	// filling the training records from history could be a function of the base nn_manager (these are never opponent's records)
	
	void train_ai(BaseAI ai)
	{
		NNManagerModReinforcementWithHistory nnm = to!(NNManagerModReinforcementWithHistory)(ai._nn_mgr);
		
		writeln("TRAIN AI IS CURRENTLY BROKEN");
		RecordHistory hist = nnm.make_history();
		hist.set_read_from_start();
		if (num_records == -1)
			nnm._record_limit = hist._num_records;
		else
			nnm._record_limit = num_records;
		if (num_epochs == -1)
			nnm._epoch_limit = nnm._record_limit * 100;
		else
			nnm._epoch_limit  = num_epochs;
		if (error_threshold > 0)
		{
			nnm._backprop.errorThreshold = error_threshold; //TODO: fix bad oop.
		}
		ai.make_training_data( null );
		ai.train_net();
		ai.save_net();
	}
	
	if( train_build )
	{ 
		writeln("\nTraining Build AI");
		train_ai(team._build_ai);
	}
	if ( train_command )
	{ 
		writeln("\nTraining Command AI");
		train_ai(team._command_ai);
	}
}


void run_match(string [] args, RenderWindow window)
{
	
	auto waypoint = new RectangleShape(Vector2f(4,4));
	waypoint.fillColor = Color.White;
	waypoint.position = Vector2f(window_width/2,window_height/2);
	
	// make a clock
	Clock the_clock = new Clock();
	
	// make some dots
	Unit[] dots;
	FactoryUnit[] factories;
	CapturePoint[] capture_points;
	Explosion[] explosions;
	
	double game_timer = 0.0;
	double time_since_last_draw = 1.0; // draw at beginning
	double framerate = 60;
	double game_time_limit = 750.0;
	bool   game_over = false;
	double game_speed = 10.0;
	bool allow_overtime = false;
	
	g_teams[0].set_opponent(g_teams[1]);
	g_teams[1].set_opponent(g_teams[0]);
	g_teams[1].set_mirror_points(true);
	writeln("opponents are set");
	
	////////////////////////////////////
	//Handle args and make initial units
	////////////////////////////////////
	if(args.length >= 1)
	{
		game_speed = to!double(args[0]);
	}
	
	if(args.length >= 2)
	{
		game_time_limit = to!double(args[1]);
	}
	
	while(args.length < 11)
	{
		args ~= "0";
	}
	
	int num_red_fighters   = to!int(args[2]);
	int num_red_lightships = to!int(args[3]);
	int num_red_bigships   = to!int(args[4]);
	int num_red_mthrships  = to!int(args[5]); 
	int num_blu_fighters   = to!int(args[6]);
	int num_blu_lightships = to!int(args[7]);
	int num_blu_bigships   = to!int(args[8]);
	int num_blu_mthrships  = to!int(args[9]);
	
	g_unit_count = 0;
	
	//TODO: these parameterized units don't get registered
	for( int i = 0; i < num_red_fighters   ; ++i )
	{
		dots ~= make_unit(UnitType.Interceptor, g_teams[0], g_teams[0]._color, uniform(0.0,window_width/2), uniform(0.0,window_height));
		g_teams[0].notify_unit_created(UnitType.Interceptor);
	}
	for( int i = 0; i < num_red_lightships ; ++i )
	{
		dots ~= make_unit(UnitType.Destroyer   , g_teams[0], g_teams[0]._color, uniform(0.0,window_width/2), uniform(0.0,window_height));
		g_teams[0].notify_unit_created(UnitType.Destroyer);
	}
	for( int i = 0; i < num_red_bigships   ; ++i )
	{
		dots ~= make_unit(UnitType.Battleship , g_teams[0], g_teams[0]._color, uniform(0.0,window_width/2), uniform(0.0,window_height));
		g_teams[0].notify_unit_created(UnitType.Battleship);
	}
	for( int i = 0; i < num_red_mthrships  ; ++i )
	{
		FactoryUnit factory1 = cast(FactoryUnit)make_unit(UnitType.Mothership, g_teams[0], g_teams[0]._color, uniform(0.0,window_width/2), uniform(0.0,window_height));
		dots ~= factory1;
		factories ~= factory1;
		g_teams[0].notify_unit_created(UnitType.Mothership);
	}
	
	for( int i = 0; i < num_blu_fighters   ; ++i )
	{
		dots ~= make_unit(UnitType.Interceptor, g_teams[1], g_teams[1]._color, uniform(window_width/2,window_width), uniform(0.0,window_height));
		g_teams[1].notify_unit_created(UnitType.Interceptor);
	}
	for( int i = 0; i < num_blu_lightships ; ++i )
	{
		dots ~= make_unit(UnitType.Destroyer   , g_teams[1], g_teams[1]._color, uniform(window_width/2,window_width), uniform(0.0,window_height));
		g_teams[1].notify_unit_created(UnitType.Destroyer);
	}
	for( int i = 0; i < num_blu_bigships  ; ++i )
	{
		dots ~= make_unit(UnitType.Battleship , g_teams[1], g_teams[1]._color, uniform(window_width/2,window_width), uniform(0.0,window_height));
		g_teams[1].notify_unit_created(UnitType.Battleship);
	}
	for( int i = 0; i < num_blu_mthrships  ; ++i )
	{
		FactoryUnit factory1 = cast(FactoryUnit)make_unit(UnitType.Mothership, g_teams[1], g_teams[1]._color, uniform(window_width/2,window_width), uniform(0.0,window_height));
		dots ~= factory1;
		factories ~= factory1;
		g_teams[1].notify_unit_created(UnitType.Mothership);
	}
	
	const double cap_radius = 100.0;
	const double cap_placement_scale = 125;
	int count = 0;
	capture_points ~= new CapturePoint(cap_placement_scale*1.0, cap_placement_scale*1.0, cap_radius, count++);
	capture_points[$-1].set_team( TeamID.One );
	
	capture_points ~= new CapturePoint(cap_placement_scale*4.0, cap_placement_scale*1.0, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*2.5, cap_placement_scale*2.5, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*1.0, cap_placement_scale*4.0, cap_radius, count++);
	
	capture_points ~= new CapturePoint(cap_placement_scale*6.5, cap_placement_scale*1.5, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*5.0, cap_placement_scale*3.0, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*3.0, cap_placement_scale*5.0, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*1.5, cap_placement_scale*6.5, cap_radius, count++);
	
	capture_points ~= new CapturePoint(cap_placement_scale*7.0, cap_placement_scale*4.0, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*5.5, cap_placement_scale*5.5, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*4.0, cap_placement_scale*7.0, cap_radius, count++);
	
	capture_points ~= new CapturePoint(cap_placement_scale*7.0, cap_placement_scale*7.0, cap_radius, count++);
	capture_points[$-1].set_team( TeamID.Two );
	
	Vector2d battlefield_size = Vector2d(cap_placement_scale*8.0, cap_placement_scale*8.0);
	
	CollisionGrid grid = new CollisionGrid( Vector2d(cap_placement_scale*0.5, cap_placement_scale*0.5),
											battlefield_size + Vector2d(cap_placement_scale, cap_placement_scale),
											30, 30 );
											
											
	MatchInfo minfo = MatchInfo( battlefield_size, game_time_limit, g_starting_tickets, NUM_CAPTURE_POINTS );
	
	g_teams[0].set_points(capture_points);
	g_teams[1].set_points(capture_points);
	
	g_teams[0].set_factory_array(&factories);
	g_teams[1].set_factory_array(&factories);
	
	g_teams[0].set_match_info(minfo);
	g_teams[1].set_match_info(minfo);
	
	// if the colors are the same, generate an alternate one.
	if (g_teams[0]._color == g_teams[1]._color)
	{
		Color base = g_teams[0]._color;
		g_teams[1]._color = Color(255 - base.r, 255 - base.g, 255 - base.b);
	}
	
	FactoryUnit factory1 = cast(FactoryUnit)make_unit(UnitType.Mothership, g_teams[0], g_teams[0]._color, cap_placement_scale*1.0, cap_placement_scale*1.0, g_teams[0]._is_player_controlled ); 
		dots      ~= factory1;
		factories ~= factory1;
		g_teams[0].notify_unit_created(UnitType.Mothership);
	FactoryUnit factory2 = cast(FactoryUnit)make_unit(UnitType.Mothership, g_teams[1], g_teams[1]._color, cap_placement_scale*7.0, cap_placement_scale*7.0, g_teams[1]._is_player_controlled );
		dots      ~= factory2;
		factories ~= factory2;
		g_teams[1].notify_unit_created(UnitType.Mothership);
	
	
	g_teams[0].set_ai_input_display(  Vector2f(window.size.x - 200, 100) ); // use display size?
	g_teams[1].set_ai_input_display(  Vector2f(window.size.x - 300, 100) ); // use display size?
	
	g_ticket_bars[0] = new RectangleShape(Vector2f(0,20));
	g_ticket_bars[1] = new RectangleShape(Vector2f(0,20));
	g_ticket_bars[0].fillColor = g_teams[0]._color;
	g_ticket_bars[1].fillColor = g_teams[1]._color;
	
	g_timer_bar = new RectangleShape( Vector2f( 50.0f , 30.0f ) );
	g_timer_bar.fillColor = Color.White;
	
	/+foreach(dot; dots[0..20])
	{
		dot._disp.fillColor = Color(255,100,0);
	}+/
	
	writeln("'bout that time, eh chaps?");
	Time now      = the_clock.getElapsedTime();
	Time previous = the_clock.getElapsedTime();
	writeln("Righto.");
	
	while( window.isOpen() && !game_over )
	{
		//writeln("loopin'");
		Event event;

		while(window.pollEvent(event))
		{
			if(event.type == event.EventType.Closed)
			{
				window.close();
			}
		}
		
		if(Keyboard.isKeyPressed(Keyboard.Key.LAlt) || Keyboard.isKeyPressed(Keyboard.Key.RAlt) ) 
		{
		
			if( Keyboard.isKeyPressed(Keyboard.Key.End) )
			{
				g_teams[0].notify_game_over(false);
				g_teams[1].notify_game_over(false);
			}
			
			if( Keyboard.isKeyPressed(Keyboard.Key.Home) )
			{
				allow_overtime = true;
			}
			
			if( Keyboard.isKeyPressed(Keyboard.Key.Num1) || Keyboard.isKeyPressed(Keyboard.Key.Numpad1) )
			{
				g_teams[1].notify_game_over(false);
				g_teams[0].notify_game_over(true);
			}
			
			if( Keyboard.isKeyPressed(Keyboard.Key.Num2) || Keyboard.isKeyPressed(Keyboard.Key.Numpad2) )
			{
				g_teams[0].notify_game_over(false);
				g_teams[1].notify_game_over(true);
			}
		
		}
		
		if (Mouse.isButtonPressed(Mouse.Button.Left))
		{
			// left mouse button is pressed: set dest
			Vector2i mouse_pos = Mouse.getPosition(window);
			if( mouse_pos.x >= 0 && mouse_pos.x <= window_width &&
				mouse_pos.y >= 0 && mouse_pos.y <= window_height   )
			{			
				/+foreach(dot; dots)
				{
					if(dot._team._id == TeamID.One)
					{
						dot._destination = mouse_pos;
					}
				}+/
				waypoint.position = Vector2f(mouse_pos.x, mouse_pos.y);
			}
		}
		
		
		now = the_clock.getElapsedTime();
		double dt = (now - previous).asMicroseconds() / 1000000.0; // number of seconds since last update as double
		time_since_last_draw += dt;
		previous = now;
		const double dt_max = 1.0/30.0;
		if(dt > dt_max) dt = dt_max;
		dt *= game_speed;
		game_timer += dt;
		if(game_timer > game_time_limit && !allow_overtime)
		{
			g_teams[0].notify_game_over(false);
			g_teams[1].notify_game_over(false);
		}
		//writefln("dt= %f", dt);
		
		
		//team_incomes[] = 20.0;
		
		//////////////////////
		// Update Everything!
		//////////////////////
		
		grid.update( dots );
		
		
		foreach(team ; g_teams[0..2])
		{
			team.update_ai_records(game_timer);
		}
		
		foreach(point; capture_points)
		{
			point.update( grid , dt);
			//team_incomes[point._team] += 20.0; 
		}
		
		foreach(dot; dots)
		{
			dot.unit_update( grid , dt);
			//TODO: unit should just handle this itself
			if(dot._needs_orders && !dot._player_controlled && !dot.is_dead)
			{
				dot.get_orders();
				dot._destination = capture_points[dot._destination_id]._pos;
				
			}
		}
		
		foreach(explosion; explosions)
		{
			explosion.update(dt);
		}
		
		foreach(team ; g_teams[0..2])
		{
			team.update(grid, dt);
		}
		
		foreach(factory ; factories)
		{ 
			Unit produced = factory.give_resources(factory._team._income_per_factory * dt);
			if(produced !is null)
			{
				dots ~= produced;
				if(produced._type == UnitType.Mothership )
				{
					factories ~= cast(FactoryUnit) produced;
					writeln("adding a factory");
				}
			}
		}
		
		foreach(dot; dots)
		{
			if(dot.is_dead())
			{
				explosions ~= new Explosion(dot._pos, dot._draw_size, 1.0 + dot._draw_size/5.0, 3.0);
			}
		}
		
		game_over = g_teams[0]._game_over || g_teams[1]._game_over;
		///////////////////
		//draw everything
		///////////////////
		if(time_since_last_draw >= 1/framerate || game_over)
		{
			time_since_last_draw = 0.0;
			window.clear();
			
			foreach(explosion; explosions)
			{
				window.draw(explosion);
			}
			
			foreach(team; g_teams)
			{
				window.draw(team);
			}
			
			foreach(dot; dots)
			{
				dot.draw_lasers(window);
			}
			
			foreach(dot; dots)
			{
				window.draw(dot);
			}
			
			foreach(point; capture_points)
			{
				window.draw(point); 
			}
			
			
			draw_ticket_bars(window);
			draw_timer_bar  (window, game_time_limit, game_timer);
			draw_ticket_arrows(window);
			
			window.display();
		
		}
		
		///////////
		//cleanup
		///////////
		
		//remove any dead stuff
		dots = remove!("a.is_dead()")(dots);
		explosions = remove!("a.is_dead()")(explosions);
		factories = remove!("a.is_dead()")(factories);
		
		if(game_over)
		{
			// update win/loss counts
			void update_win_loss_counts(string team_name, string opp_name, bool won)
			{
				if( (team_name in  win_counts) is null)
					win_counts [team_name] = 0;
				if( (team_name in loss_counts) is null)
					loss_counts[team_name] = 0;
				if(won)
					win_counts [team_name]++;
				else
					loss_counts[team_name]++;
					
				
				countvskey key = countvskey(team_name, opp_name);
				if ( (key in  win_counts_vs) is null)
					win_counts_vs [key] = 0;
				if ( (key in loss_counts_vs) is null)
					loss_counts_vs[key] = 0;
				if (won)
					win_counts_vs [key]++;
				else
					loss_counts_vs[key]++;
			}
			
			update_win_loss_counts(g_teams[0]._name.idup(), g_teams[1]._name.idup(), g_teams[0]._won_game);
			update_win_loss_counts(g_teams[1]._name.idup(), g_teams[0]._name.idup(), g_teams[1]._won_game);
			
			foreach(team; g_teams[0..2])
			{
				string team_name = team._name.idup(); // we do this twice because training spams the console a LOT
				writefln("%s: %d Wins, %d Losses", team_name, win_counts[team_name], loss_counts[team_name]);
				
			}
			if (g_teams[0]._train && g_teams[1]._train && g_teams[0]._name == g_teams[1]._name)
			{
				foreach(team; g_teams[0..2])
				{
					team.handle_endgame_parrallel(); // if we're training the same net, we really don't want to train them both at once.
					team.wait_on_training_tasks();
				}
			} else {
				foreach(team; g_teams[0..2])
				{
					team.handle_endgame_parrallel(); 
				}
				
				// wait on threadpool tasks
				g_teams[0].wait_on_training_tasks();
				g_teams[1].wait_on_training_tasks();
			}
			
			//TODO: make the console less spammy.
			foreach(team; g_teams[0..2])
			{
				string team_name = team._name.idup();
				writefln("%s: %d Wins, %d Losses", team_name, win_counts[team_name], loss_counts[team_name]);
			}
			
			write("\n\n");
		}
		
		//window.draw(waypoint);
		
		
	}
	
	g_teams[0].cleanup_ais(); //TODO: is this necessary? why was it necessary?
	g_teams[1].cleanup_ais();
	//g_teams[2].cleanup_ais();
	
	
	
}



void draw_ticket_bars( RenderTarget surface )
{
	float total_width = surface.getSize().x;
	float midpoint = total_width/2.0;
	
	//writefln("midpoint %f", midpoint);
	//writefln("%f",midpoint * g_teams[0]._tickets / g_starting_tickets);
	
	g_ticket_bars[0].size( Vector2f( g_ticket_bars[0].size.x = midpoint * g_teams[0]._tickets / g_starting_tickets, 30.0f ));
	g_ticket_bars[1].size( Vector2f( g_ticket_bars[1].size.x = midpoint * g_teams[1]._tickets / g_starting_tickets, 30.0f ));
	
	//writefln("width %f", g_ticket_bars[0].size.x);
	
	g_ticket_bars[0].position( Vector2f( midpoint - g_ticket_bars[0].size.x, 0 ));
	g_ticket_bars[1].position( Vector2f( midpoint                          , 0 ));
	
	
	if ( g_teams[0]._tickets > 0 )
	{
		surface.draw(g_ticket_bars[0]);
	} 
		
	
	if ( g_teams[1]._tickets > 0 )
	{
		surface.draw(g_ticket_bars[1]);
	}
	
}


void draw_timer_bar( RenderTarget surface, double time_limit, double game_timer )
{
	
	double time_left = time_limit - game_timer;
	
	float bar_full_height = surface.getSize().y - 30.0f;
	
	float bar_draw_height = bar_full_height * time_left / time_limit;
	
	g_timer_bar.size = Vector2f( 40.0f , bar_draw_height  );
	
	g_timer_bar.position = Vector2f( surface.getSize().x - 50.0f , 30.0f );
	
	surface.draw(g_timer_bar);
	
}



void draw_ticket_arrows(RenderTarget surface)
{
	static Text label = null;
	static Font font = null;
	if(label is null)
		label = new Text();
	if(font is null)
	{
		font = new Font();
		if (!font.loadFromFile("font/OpenSans-Regular.ttf"))
		{
			assert(false, "font didn't load");
		}
	}
	
	
	int point_diff = g_teams[0]._num_points_owned - g_teams[1]._num_points_owned;
	char[] arrow_str = [];
	
	if (point_diff == 0) 
	{
		label.setColor(Color.White);
		arrow_str = "=".dup();
	} else {
		arrow_str.length = abs(point_diff);
		if (point_diff < 0)
		{
			label.setColor(g_teams[1]._color);
			arrow_str[] = '>';
		} else {
			label.setColor(g_teams[0]._color);
			arrow_str[] = '<';
		}
	}
	
	
	label.setFont(font); 
	label.setCharacterSize(15);
	label.setString(arrow_str.idup());
	
	label.position = Vector2!float(surface.getSize().x/2.0 - 5*arrow_str.length, 35.0);
	label.position.x = to!int(label.position.x);
	label.position.y = to!int(label.position.y);
	surface.draw(label);
	
}


/+
int get_command()
{
	//temptemptemp
	return to!int(floor(uniform01() * 12));
}
	
int get_build_order()
{
	//temptemptemp
	return dice(18,18,18,3,3,3,1,1,1);
}
+/