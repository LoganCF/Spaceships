module team_single_strategy;


import std.random;
import std.conv;
import std.stdio;
import std.format;

import team;
import ai_base;
import unit;
import factory_unit;
import collision;
import strategy;
import strategies;
import gamestateinfo;

import dsfml.graphics;
import dsfml.system;

class SingleStrategyTeam : TeamObj
{
  int _strat_id = 0;

  this(TeamID in_id, inout Color in_color, inout char[] in_name, int in_strat_id)
  {
    super( in_id, in_color, in_name );
	_strat_id = in_strat_id;
  }
  
  override string generate_display_str()
	{
		return format("Scripted Single-Strategy AI: %s", g_strategies[_strat_id]._name);
	}

	override int assign_command(Unit unit)
	{ 
		/+_command_ai.load_or_initialize_net();+/

		int decision = unit._destination_id;
		
		StateInfo gamestate = make_state_info(unit);
		
		decision = strategies.g_strategies[_strat_id].evaluate(gamestate);
		
		
		if (decision == -1) decision = unit._destination_id;
		if (decision == -1) decision = 0;
		
		int old_dest = unit._destination_id;
		int new_dest = decision;
		if(old_dest != -1)
		{
			_unit_destination_counts[old_dest][unit._type]--;
		}
		_unit_destination_counts[new_dest][unit._type]++;
		
		record_move_order(unit, decision); //TODO: this should record strategy as well
		return decision;
	}
	
	override UnitType get_build_order ( FactoryUnit building_unit )
	{
		/+_build_ai  .load_or_initialize_net();+/
		
		UnitType decision = to!UnitType( dice(18,6,3,2,9,1) );
		record_build_decision(building_unit, decision);
		return decision;
		
		
		record_build_decision(building_unit, decision);
		return decision;
		
	}
	
	override void update( CollisionGrid grid, double dt )
	{
		/+_command_ai.load_or_initialize_net();
		_build_ai  .load_or_initialize_net();+/
  
    super.update(grid, dt);
  }
    

}