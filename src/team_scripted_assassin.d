module team_scripted_assassin;


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


// this team builds very few interceptors, opting to go for destroyers very early.
// it tries to capture territory with the destroyers until it has enough, then attacks the enemy mothership
// if it runs out of destroyers, it will return to capturing territory until it has enough again.
class ScriptedAssassinTeam : TeamObj
{
  int _mush_orders = 0;
  int _dest_orders = 0;
  int _num_interceptors_needed = 3;
  bool _attempt_assassination = false;

  this(TeamID in_id, inout Color in_color, inout char[] in_name)
  {
    super( in_id, in_color, in_name, false);
  }
  
  override string generate_display_str()
	{
		return format("Scripted Assassin AI");
	}

	override int assign_command(Unit unit)
	{ 
		
		int decision = unit._destination_id;
		UnitType type = unit._type;
		StateInfo gamestate = make_state_info(unit);
		const (Strategy)* strat;
		
		if (_total_units_by_type[UnitType.Destroyer] >= 4)
		{
			//party time.
			_attempt_assassination = true;
		} 
		else if(_total_units_by_type[UnitType.Destroyer] == 0 && _attempt_assassination)
		{
			_attempt_assassination = false;
			_num_interceptors_needed = 6;
		}
		
		
		if (type == UnitType.Interceptor)
		{
			strat = &strat_expand_safe;
		}
		
		if (type == UnitType.Mothership)
		{
			if(_mush_orders < 3)
			{
				strat = &strat_expand_safe;
			}
			else if(_attempt_assassination)
			{
				strat = &strat_attack_mothership;
			}
			else
			{
				strat = &strat_contest_caps;
			}
			_mush_orders++;
		}

		if(type == UnitType.Destroyer)
		{
			if(_dest_orders < 3)
			{
				strat = &strat_expand_safe; //spread out in the very early game
			}
			else if(_attempt_assassination)
			{
				strat = &strat_attack_mothership;
			}
			else
			{
				strat = &strat_capture_least_guarded; // capture points as a pack until the time is right
			}
			_dest_orders++;
		}
		
		int strat_index = index_of_strat(*strat);
		decision = (*strat).evaluate(gamestate);
		
		
		if (decision == -1) decision = unit._destination_id;
		if (decision == -1) decision = 0;
		
		int old_dest = unit._destination_id;
		int new_dest = decision;
		if(old_dest != -1)
		{
			_unit_destination_counts[old_dest][unit._type]--;
		}
		_unit_destination_counts[new_dest][unit._type]++;
		
		unit._last_strat = strat_index;
		record_move_order(unit, decision, strat_index); 
		return decision;
	}
	
	override UnitType get_build_order ( FactoryUnit building_unit )
	{
		UnitType decision;
		if ( _num_interceptors_needed > 0)
		{
			decision = UnitType.Interceptor;
			_num_interceptors_needed--;
		} else {
			decision = UnitType.Destroyer;
		}
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