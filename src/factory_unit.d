module factory_unit;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import steering;
import collision;
import unit;
//import spaceships;
import team;


import std.random;

import dsfml.graphics;



class FactoryUnit : Unit
{
	UnitType _current_build = UnitType.None;
	double _resources_until_build = 0.0;
	
	double _build_boredom_timer = 0.0;
	
	double _last_built_up = false; // alternate building left-up and left-right ot avoid odd behaviors
	
	this(double x, double y, 
		 double in_max_vel = 400.0, double in_max_accel = 800.0, float size = 2, ShapeType in_shape = ShapeType.Circle, Color in_color = Color.Red,
		 double in_st_too_close = 200.0, double in_st_dont_care = 1250.0,  double in_st_too_close_push = 0.0, double in_st_dont_care_push = 0.0, Lookahead in_st_lookahead = Lookahead.SHORT, 
		 TeamObj in_team = null, UnitType in_type = UnitType.Interceptor, double in_health_max= 100.0, ArmorType in_armor_type = ArmorType.Light, double in_range = 0.0, double in_rof = 1.0, double in_damage = 10.0, DamageType in_dmg_type = DamageType.Frag, double in_laser_dur = 0.1, bool in_player_controlled = false)
	{
		super( x, y, in_max_vel, in_max_accel, size, in_shape, in_color, in_st_too_close, in_st_dont_care, in_st_too_close_push, in_st_dont_care_push, in_st_lookahead, 
		in_team, in_type, in_health_max, in_armor_type, in_range, in_rof, in_damage, in_dmg_type, in_laser_dur, in_player_controlled); // gross
		
		_team._num_factories++;
		_current_build = _team.get_build_order(this);
		_resources_until_build = get_unit_build_cost( _current_build );
	}
	
	override void take_damage(double in_damage, DamageType dmg_type)
	{
		super.take_damage(in_damage, dmg_type);
		
		if( this._is_dead )
		{
			_team.notify_dead_factory();
		}
		
	}
	
	Unit give_resources(double res)
	{
		if(_is_dead || _current_build == UnitType.None) 
			return null;
	
		Unit retval = null;
		_resources_until_build -= res;
		if( _resources_until_build <= 0.0)
		{
			retval = build();
			
			if(_player_controlled)
			{
				retval._destination = _destination;
			}
			
			_team._unit_built_counts[_current_build]++;
			
			UnitType prev_build = _current_build;
			_current_build = determine_next_build();
			if(_current_build != prev_build)
			{
				_build_boredom_timer = 0.0;
			}
			
			_resources_until_build += get_unit_build_cost( _current_build ); 
		}
		return retval;
	}
	
	override void unit_update( CollisionGrid grid /+Unit[] dots+/, double dt )
	{
		super.unit_update( grid /+dots+/, dt);
		
		_build_boredom_timer += dt;
	}
	
	
	Unit build()
	{
		double y_offset = _last_built_up ? - 0.5 : 0.5;
		_last_built_up = !_last_built_up;
		Unit produced = make_unit(_current_build, _team, _color, _pos.x - 1.0, _pos.y + y_offset, _player_controlled );
		produced.get_orders();
		return produced;
	}
	
	UnitType determine_next_build()
	{
		if(_player_controlled)
		{
			_team.record_build_decision(this, _current_build);
			return _current_build;
		}
		return _team.get_build_order(this);
	}
	
	void change_build(UnitType newbuild)
	{

		_resources_until_build += get_unit_build_cost( newbuild );
		_resources_until_build -= get_unit_build_cost( _current_build );	
		
		_current_build = newbuild;
	}
	
	
}


const double UNIT_COST_BASE = 100.0;

//inelegant, but whatevs.
double get_unit_build_cost( UnitType type )
{
	final switch(type)
	{
		case UnitType.Interceptor:
			return UNIT_COST_BASE * 2.0;
			break;
		case UnitType.Destroyer:
			return UNIT_COST_BASE * 6.0;
			break;
		case UnitType.Cruiser:
			return UNIT_COST_BASE * 12.0;
			break;
		case UnitType.Battleship:
			return UNIT_COST_BASE * 18.0;
			break;
		case UnitType.Miner:
			return UNIT_COST_BASE * 4.0;
			break;
		case UnitType.Mothership:
			return UNIT_COST_BASE * 36.0;
			break;
		case UnitType.None:
			assert(0);
	}

}