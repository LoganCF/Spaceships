module team_scripted_defender;


import std.random;
import std.conv;

import team;
import ai_base;
import unit;
import factory_unit;
import collision;

import dsfml.graphics;
import dsfml.system;

class DefenderTeam : TeamObj
{

  this(TeamID in_id, inout Color in_color, inout char[] in_name)
  {
    super( in_id, in_color, in_name );
  }

  override int assign_command(Unit unit)
	{ 
    _command_ai.load_or_initialize_net();
    
    int decision = unit._destination_id;
    double min_dist_sq = 10_000_000.0;  // arbitrary large initial values for finding minimums
    for(int i = 0 ; i < _points.length; ++i )
    {
      int units;
      if( unit._destination_id != -1)
      {
        units = _unit_destination_counts[unit._destination_id][to!int(UnitType.Cruiser)] + _unit_destination_counts[unit._destination_id][to!int(UnitType.Mothership)];
      } else {
        units = 2;
      }
      if(units > 1)
      {
        double dist_sq = pow(unit._pos.x - _points[i]._pos.x, 2.0) + pow(unit._pos.y - _points[i]._pos.y, 2.0);
        if(dist_sq < min_dist_sq && _unit_counts[i][to!int(UnitType.Cruiser)] == 0 )
        {
          decision = i;
          min_dist_sq = dist_sq;
        }
      }
    }
    
    if (decision == -1) decision = 0;
    
    int old_dest = unit._destination_id;
		int new_dest = decision;
		if(old_dest != -1)
		{
			_unit_destination_counts[old_dest][unit._type]--;
		}
    _unit_destination_counts[new_dest][unit._type]++;
    
    record_move_order(unit, decision);
		return decision;
	}
	
	override UnitType get_build_order ( FactoryUnit building_unit )
	{
    _build_ai  .load_or_initialize_net();
    
    UnitType decision = UnitType.Cruiser;
    
    
    record_build_decision(building_unit, decision);
		return decision;
		
	}
	
	override void update( CollisionGrid grid, double dt )
	{
    _command_ai.load_or_initialize_net();
    _build_ai  .load_or_initialize_net();
  
    super.update(grid, dt);
  }
    

}