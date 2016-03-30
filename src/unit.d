module unit;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/


import steering;
import collision;
import factory_unit;
import team;


import dsfml.graphics;
import dsfml.system;


int g_unit_count = 0;

enum ArmorType  {Light=0, Medium=1, Heavy=2, Any=3}
enum DamageType {Frag=0, Explosive=1, AP=2, Universal=3}

const double[][] damage_type_matrix = [ [1.50, 0.75, 0.75],
										[0.75, 1.50, 0.75],
										[0.75, 0.75, 1.50],
										[1.00, 1.00, 1.00]	];
										
const ArmorType[] preferred_targets = [ ArmorType.Light, ArmorType.Medium, ArmorType.Heavy, ArmorType.Any ];

enum UnitType { Interceptor, AssaultFighter, Bomber, Corvette, Frigate, Destroyer, Cruiser, BattleCruiser, Battleship, Miner, Mothership, None } // important: None must remain the last element


const int NUM_UNIT_TYPES = 11;
										
class Unit  : Dot
{
	
	TeamObj _team;
	
	UnitType _type;
	
	double _health_max;
	double _health_current;
	ArmorType _armor_type;
	bool _is_dead = false;
	
	double _range;
	double _range_sq;
	double _rof;
	double _attack_cooldown;
	double _cooldown_remaining;
	double _attack_damage;
	DamageType _damage_type;
	ArmorType _preferred_target_type;
	
	Vertex[2] _laser;
	double _laser_draw_time = 0.1;
	double _remaining_laser_draw_time;
	bool   _draw_laser = false;
	
	double _order_duration = 10.0;
	double _time_till_next_order = 0.0;
	bool   _needs_orders = true;
	bool   _player_controlled = false;
	
	int _destination_id = -1;
	double _location_boredom_timer = 0.0;
	
	int _produced_order;
	
	//Vector2f draw_offset;
	
	this(double x, double y, 
		 double in_max_vel = 400.0, double in_max_accel = 800.0, float size = 2.0f, ShapeType in_shape = ShapeType.Circle, Color in_color = Color.Red,
		 double in_st_too_close = 200.0, double in_st_dont_care = 1250.0,  double in_st_too_close_push = 0.0, double in_st_dont_care_push = 0.0, Lookahead in_st_lookahead = Lookahead.SHORT, 
		 TeamObj in_team = null, UnitType in_type = UnitType.Interceptor, double in_health_max= 100.0, ArmorType in_armor_type = ArmorType.Light, double in_range = 0.0, double in_rof = 1.0, double in_damage = 10.0, DamageType in_dmg_type = DamageType.Frag, double in_laser_dur = 0.1, bool in_player_controlled = false)
	{
		super( x, y, in_max_vel, in_max_accel, size, in_shape, in_color, in_st_too_close, in_st_dont_care, in_st_too_close_push, in_st_dont_care_push, in_st_lookahead); // gross
		
		_team = in_team;
		_type = in_type;	
		
		_health_max     = in_health_max;
		_health_current = in_health_max;
		
		_armor_type = in_armor_type;
		_range    = in_range;
		_range_sq = square(in_range);
		_rof = in_rof;
		_attack_cooldown = 1.0 / in_rof;
		_cooldown_remaining = _attack_cooldown;
		_attack_damage = in_damage;
		_damage_type  = in_dmg_type;
		
		_laser_draw_time = in_laser_dur;
		
		_preferred_target_type = preferred_targets[_damage_type];
		
		_produced_order = g_unit_count;
		g_unit_count++;
		
		_player_controlled = in_player_controlled;
		
		//temp?
		_order_duration = 10.0 * 100.0 / get_unit_build_cost(_type);
		
	}
	
	
	
	void take_damage(double in_damage, DamageType dmg_type)
	{
		_health_current -= in_damage * damage_type_matrix[dmg_type][_armor_type];
		if(_health_current < 0.0)
		{
			_is_dead = true; // kaboom!
			_team._unit_lost_counts[_type]++;
			if(_destination_id != -1)
			{
				_team._unit_destination_counts[_destination_id][_type]--;
			}
		}
	}
	
	
	bool is_dead()
	{
		return _is_dead;
	}
	
	void get_orders()
	{
		int last_dest = _destination_id;
		_destination_id = _team.assign_command(this);
		if(_destination_id != last_dest)
		{
			_location_boredom_timer = 0.0;
		}
		//update team's destination counts.
		_needs_orders = false;
		
	}
	
	void shoot( Unit target )
	{
		target.take_damage(_attack_damage, _damage_type);
		_cooldown_remaining = _attack_cooldown;
		
		// TODO: tell environment that an attack happened ... somehow.
		// maintain a shooty_line obejct and whether it should be drawn?
		_remaining_laser_draw_time = _laser_draw_time;
		_draw_laser = true;
		
		_laser[0].position = Vector2f(_pos.x, _pos.y);
		_laser[0].color    = _color; 
		_laser[1].position = Vector2f(target._pos.x, target._pos.y);
		_laser[1].color    = Color.White;
		
		
	}
	
	Unit pick_target( CollisionGrid grid /+Unit[] candidates+/ )
	{
		Unit ok_candidate = null; 
		Unit good_candidate = null;
		//int ok_earliest_produced   = -1;
		//int good_earliest_produced = -1;
		double closest_ok;
		double closest_good;
		
		/+foreach(candidate; candidates)+/
		grid.collision_query_grid_only 
		(  _pos, _range,
			delegate void(Unit candidate) 
			{
				// candidate is hostile && candidate is in range
				if(candidate._team != _team && !candidate._is_dead)
				{
					Vector2d pos_diff = candidate._pos - _pos;
					double dist_sq = pos_diff.x * pos_diff.x + pos_diff.y * pos_diff.y;
					if(dist_sq <= _range_sq)
					{
						if(candidate._armor_type == _preferred_target_type || _preferred_target_type == ArmorType.Any)
						{
							if(good_candidate is null || dist_sq < closest_good)//candidate._produced_order < good_candidate._produced_order )
							{
								good_candidate = candidate;
								closest_good   = dist_sq; 
							}
						} 
						else if( good_candidate is null ) 
						{
							if(ok_candidate is null || dist_sq < closest_ok ) // candidate._produced_order < ok_candidate._produced_order)
							{
								ok_candidate = candidate; // we'll pick this one if there's no better one;
								closest_ok   = dist_sq;
							}
						}
					}
				}
			}
		);
		
		
		return good_candidate !is null ? good_candidate : ok_candidate;
	}
	
	void pick_target_and_attack(  CollisionGrid grid /+Unit [] candidates+/)
	{
		Unit target = pick_target( grid /+candidates+/);
		if(target !is null)
		{
			shoot(target);
		}
	}
	
	void unit_update( CollisionGrid grid /+Unit[] dots+/, double dt )
	{
		/+update( cast(Dot[])dots, dt );+/
		update( grid, dt );
		
		
		if(_cooldown_remaining <= 0)
		{
			pick_target_and_attack( grid /+dots+/);
		} else {
			_cooldown_remaining -= dt;
		}
		
		if(_remaining_laser_draw_time > 0.0)
		{
			_laser[0].position = Vector2f(_pos.x, _pos.y);
			_remaining_laser_draw_time -= dt;
		}
		
		_time_till_next_order -= dt;
		if( _time_till_next_order <= 0.0 )
		{
			_needs_orders = true; //TODO: just get orders here???
			_time_till_next_order = _order_duration;
		}
		
		_location_boredom_timer += dt;
		
		
	}
	
	override void draw(RenderTarget renderTarget, RenderStates renderStates) 
	{
		if(!_is_dead)
		{
			super.draw(renderTarget, renderStates);
		} else {
			//draw explosion!
			_disp.position = Vector2f( _pos.x, _pos.y );
			//_disp._draw_size = _draw_size * 2.0f;
			_disp.fillColor = Color(255,128,0);
			renderTarget.draw(_disp, renderStates);
		}
		
		//draw lasers
		if(_draw_laser)
		{
			//renderTarget.draw(_laser, renderStates );
			renderTarget.draw( _laser, PrimitiveType.Lines, renderStates);
		}
		_draw_laser = ( _remaining_laser_draw_time > 0.0 );
	}
	
}



const double LIGHT_UNIT_HARD_RADIUS = square(6.0 /2.0)/2.0 ;
const double LIGHT_UNIT_SOFT_RADIUS = square(25.0 /2.0)/2.0;
const double LIGHT_UNIT_HARD_RADIUS_PUSH = 0.0;
const double LIGHT_UNIT_SOFT_RADIUS_PUSH = 0.0;

const double MEDIUM_UNIT_HARD_RADIUS = square(12.0 /2.0)/2.0; 
const double MEDIUM_UNIT_SOFT_RADIUS = square(30.0 /2.0)/2.0;
const double MEDIUM_UNIT_HARD_RADIUS_PUSH = square(24.0 /2.0)/2.0;
const double MEDIUM_UNIT_SOFT_RADIUS_PUSH = square(45.0 /2.0)/2.0;

const double HEAVY_UNIT_HARD_RADIUS = square(15.0 /2.0)/2.0;
const double HEAVY_UNIT_SOFT_RADIUS = square(40.0 /2.0)/2.0;
const double HEAVY_UNIT_HARD_RADIUS_PUSH = square(30.0 /2.0)/2.0;
const double HEAVY_UNIT_SOFT_RADIUS_PUSH = square(60.0 /2.0)/2.0;



Unit make_unit ( UnitType type, TeamObj in_team, Color in_color, double x, double y, bool player_controlled = false ) 
{
	Unit new_unit;
	final switch (type)
	{
		//////////////////////////////
		//Fighters
		//////////////////////////////
		case UnitType.Interceptor:
			new_unit = new Unit( x, y, 
								 200.0, 400.0, 2.5, ShapeType.Triangle, in_color, // speed, accel, size, color
								 LIGHT_UNIT_HARD_RADIUS, LIGHT_UNIT_SOFT_RADIUS,  LIGHT_UNIT_HARD_RADIUS_PUSH, LIGHT_UNIT_SOFT_RADIUS_PUSH, Lookahead.SHORT,  // steering params
								 in_team, type, 400.0, ArmorType.Light, 125.0, 2.0, 20.0, DamageType.Frag, 0.075, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
			
			
		case UnitType.AssaultFighter:
			new_unit = new Unit( x, y, 
								 200.0, 400.0, 2.5, ShapeType.Circle, in_color, // speed, accel, size, color
								 LIGHT_UNIT_HARD_RADIUS, LIGHT_UNIT_SOFT_RADIUS,  LIGHT_UNIT_HARD_RADIUS_PUSH, LIGHT_UNIT_SOFT_RADIUS_PUSH, Lookahead.SHORT,  // steering params
								 in_team, type, 400.0, ArmorType.Light, 125.0, 2.0, 20.0, DamageType.Explosive, 0.075, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
			
	
		case UnitType.Bomber:
			new_unit = new Unit( x, y, 
								 200.0, 400.0, 2.5, ShapeType.Square, in_color, // speed, accel, size, color
								 LIGHT_UNIT_HARD_RADIUS, LIGHT_UNIT_SOFT_RADIUS,  LIGHT_UNIT_HARD_RADIUS_PUSH, LIGHT_UNIT_SOFT_RADIUS_PUSH, Lookahead.SHORT,  // steering params
								 in_team, type, 400.0, ArmorType.Light,125.0, 1.0, 40.0, DamageType.AP, 0.100, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
			
			
		//////////////////////////////
		//Light Ships
		//////////////////////////////
		case UnitType.Corvette:
			new_unit = new Unit( x, y, 
								 150.0, 150.0, 5, ShapeType.Triangle, in_color, // speed, accel, size, color
								 MEDIUM_UNIT_HARD_RADIUS, MEDIUM_UNIT_SOFT_RADIUS,  MEDIUM_UNIT_HARD_RADIUS_PUSH, MEDIUM_UNIT_SOFT_RADIUS_PUSH, Lookahead.MEDIUM,  // steering params
								 in_team, type, 1200.0, ArmorType.Medium, 200.0, 3.0, 30.0, DamageType.Frag, 0.050, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;

			
		case UnitType.Frigate:
			new_unit = new Unit( x, y, 
								 150.0, 150.0, 5, ShapeType.Circle, in_color, // speed, accel, size, color
								 MEDIUM_UNIT_HARD_RADIUS, MEDIUM_UNIT_SOFT_RADIUS,  MEDIUM_UNIT_HARD_RADIUS_PUSH, MEDIUM_UNIT_SOFT_RADIUS_PUSH, Lookahead.MEDIUM,  // steering params
								 in_team, type, 1200.0, ArmorType.Medium, 200.0, 1.5, 60.0, DamageType.Explosive, 0.150, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
		
		
		case UnitType.Destroyer:
			new_unit = new Unit( x, y, 
								 150.0, 150.0, 5, ShapeType.Square, in_color, // speed, accel, size, color
								 MEDIUM_UNIT_HARD_RADIUS, MEDIUM_UNIT_SOFT_RADIUS,  MEDIUM_UNIT_HARD_RADIUS_PUSH, MEDIUM_UNIT_SOFT_RADIUS_PUSH, Lookahead.MEDIUM,  // steering params
								 in_team, type, 1200.0, ArmorType.Medium, 200.0, 1.5, 60.0, DamageType.AP, 0.15, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
			
		//////////////////////////////
		//Heavy Ships
		//////////////////////////////	
		case UnitType.Cruiser:   
			new_unit = new Unit( x, y, 
								 100.0,  50.0, 9, ShapeType.Triangle, in_color, // speed, accel, size, color
								 HEAVY_UNIT_HARD_RADIUS, HEAVY_UNIT_SOFT_RADIUS, HEAVY_UNIT_HARD_RADIUS_PUSH, HEAVY_UNIT_SOFT_RADIUS_PUSH, Lookahead.FAR,  // steering params
								 in_team, type, 3600.0, ArmorType.Heavy, 300.0, 1.0, 180.0, DamageType.Frag, 0.25, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
			
			
		case UnitType.BattleCruiser:
			new_unit = new Unit( x, y, 
								 100.0,  50.0, 9, ShapeType.Circle, in_color, // speed, accel, size, color
								 HEAVY_UNIT_HARD_RADIUS, HEAVY_UNIT_SOFT_RADIUS, HEAVY_UNIT_HARD_RADIUS_PUSH, HEAVY_UNIT_SOFT_RADIUS_PUSH, Lookahead.FAR,  // steering params
								 in_team, type, 3600.0, ArmorType.Heavy, 300.0, 1.0, 180.0, DamageType.Explosive, 0.25, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
			
		
		case UnitType.Battleship:
			new_unit = new Unit( x, y, 
								 100.0,  50.0, 9, ShapeType.Square, in_color, // speed, accel, size, color
								 HEAVY_UNIT_HARD_RADIUS, HEAVY_UNIT_SOFT_RADIUS, HEAVY_UNIT_HARD_RADIUS_PUSH, HEAVY_UNIT_SOFT_RADIUS_PUSH, Lookahead.FAR,  // steering params
								 in_team, type, 3600.0, ArmorType.Heavy, 300.0, 1.0, 180.0, DamageType.AP, 0.25, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
			
		//////////////////////////////
		//Utility Ships
		//////////////////////////////	
		case UnitType.Mothership:
			new_unit = new FactoryUnit( x, y, 
								  50.0,  25.0, 15*SQRT2, ShapeType.Diamond, in_color, // speed, accel, size, color
								 square(20)/2, square(40.0)/2,  square(50)/2, square(80.0)/2, Lookahead.FAR,  // steering params
								 in_team, type, 14400.0, ArmorType.Heavy, 250.0, 1.0, 120.0, DamageType.Universal, 0.25, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
			
			
		case UnitType.Miner:
			new_unit = new Unit( x, y, 
								 100.0, 100.0, 4, ShapeType.Diamond, in_color, // speed, accel, size, color
								 square(12)/2, square(30.0)/2,  square(24)/2, square(45.0)/2, Lookahead.MEDIUM,  // steering params
								 in_team, type, 600.0, ArmorType.Medium, 150.0, 1.0, 30.0, DamageType.Universal, 0.075, player_controlled ); // unit params: health, armortype, range, rof, damage, attacktype
			break;
			
			
		case UnitType.None:
			assert(0);
	
	}
	
	return new_unit;

}
	
	
	
	
	
	


