module team_random;

import std.random;
import std.conv;

import team;
import ai_base;
import unit;
import factory_unit;
import collision;

import dsfml.graphics;
import dsfml.system;

class RandomTeam : TeamObj
{

	this(TeamID in_id, inout Color in_color, inout char[] in_name)
	{
		super( in_id, in_color, in_name );
	}

	override int assign_command(Unit unit)
	{ 
		_command_ai.load_or_initialize_net();
		int decision = uniform!"[)"(0,_command_ai._neural_net.output.neurons.length);
	
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
		UnitType decision = to!UnitType( dice(18,6,3,2,9,1) );
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