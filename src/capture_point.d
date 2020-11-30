module capture_point;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import spaceships;
import steering;
import collision;
import unit;
import factory_unit;
import team;
import mathutil;


import dsfml.graphics;

import std.stdio;




class CapturePoint : Drawable
{
	Vector2d _pos;
	TeamID _team_id = TeamID.Neutral;
	Color  _color = Color.White;
	
	double _cap_status = 0.0;
	double _points_to_cap = 5.0;
	
	double _cap_radius;
	double _cap_radius_sq;
	
	double _threat_radius;
	double _thread_radius_sq;
	
	double _team1_threat = 0.0;
	double _team2_threat = 0.0;
	
	
	RectangleShape[2] _disp;
	
	int _zone_number = -1;
	
	
	//int[NUM_UNIT_TYPES] _team1_unit_counts;
	//int[NUM_UNIT_TYPES] _team2_unit_counts;
	int _team1_num_units;
	int _team2_num_units;
	
	static const double THREAT_RADIUS_UNDEFINED = 0.0;
	
	this(double x, double y, double radius, int in_number, double threat_radius = THREAT_RADIUS_UNDEFINED)
	{
		_pos = Vector2d(x,y);
		_cap_radius = radius;
		_cap_radius_sq = square(radius);
		_zone_number = in_number;
		
		if (threat_radius == THREAT_RADIUS_UNDEFINED)
			threat_radius = radius * 3.0;
		_threat_radius = threat_radius;
		_thread_radius_sq = square(threat_radius);
	}
	
	void update( CollisionGrid grid /+Unit[] units+/, double dt)
	{
		// count units;
		//_team1_unit_counts[] = 0;
		//_team2_unit_counts[] = 0;
		_team1_num_units = 0;
		_team2_num_units = 0;
		
		_team1_threat = 0.0;
		_team2_threat = 0.0;
		
		/+foreach(unit ; units)+/
		grid.collision_query
		(
			_pos, _cap_radius,
			delegate void(Unit unit)
			{
				//double dist_sq = get_dist_sq(_pos, unit._pos);
				//if(dist_sq <= _cap_radius_sq)
				//{
				
				//writefln("Zone num: %d, type: %d",_zone_number, unit._type);
				//writefln("unit counts has %d elements", unit._team._unit_counts.length);
				//writefln("this zone's unit counts has %d elements", unit._team._unit_counts[_zone_number].length);
				unit._team._unit_counts[_zone_number][unit._type]++;
				unit._team._unit_total_cost_at_points[_zone_number] += get_unit_build_cost(unit._type);// /UNIT_COST_BASE;
				if( unit._team._id == TeamID.One )
				{
					//_team1_unit_counts[unit._type] ++;
					_team1_num_units++;
				} else {
					//_team2_unit_counts[unit._type] ++;
					_team2_num_units++;
				}
				//}
			}
		);
		
		
		grid.collision_query
		(
			_pos, _threat_radius,
			delegate void (Unit unit)
			{
				if( unit._team._id == TeamID.One )
				{
					_team1_threat += get_unit_build_cost(unit._type);
				} else {
					_team2_threat += get_unit_build_cost(unit._type);
				}
			}
		);
		
		
		// gross
		if( _team1_num_units > 0 && _team2_num_units == 0 && _cap_status < _points_to_cap )
		{
			//writefln("cap status: %f, dt %f, points_to_cap = %f",_cap_status, dt, _points_to_cap);
			_cap_status += dt;
			//writefln("cap status: %f, dt %f",_cap_status, dt);
			if( _cap_status >= _points_to_cap )
			{
				_team_id = TeamID.One;
				_color = g_teams[0]._color;
				_cap_status = _points_to_cap;
			} else if( _cap_status >= 0.0 )
			{
				_team_id = TeamID.Neutral;
				_color = Color.White;
			}
		} else if (_team2_num_units > 0 && _team1_num_units == 0 && _cap_status > -1.0 * _points_to_cap )
		{
			_cap_status -= dt;
			if( _cap_status <= -1.0 * _points_to_cap )
			{
				_team_id = TeamID.Two;
				_color = g_teams[1]._color;
				_cap_status = -1.0 * _points_to_cap;
			} else if( _cap_status <= 0.0 )
			{
				_team_id = TeamID.Neutral;
				_color = Color.White;
			}
		}
		
		//if( _cap_status > -1.0 * _points_to_cap && _cap_status < _points_to_cap)
			//writefln("cap status: %f, dt %f",_cap_status, dt);
		
	}
	
	
	/+void adjust_cap_status(double dt, double sign)
	{
		sign = sign > 0.0 ? 1.0 : -1.0;
		
		
	}+/
	
	void set_team(TeamID in_team)
	{
		_team_id = in_team;
		if(in_team == TeamID.One)
		{
			_color = g_teams[0]._color;
			_cap_status = _points_to_cap;
		} else if(in_team == TeamID.Two)
		{
			_color = g_teams[1]._color;
			_cap_status = -1.0 * _points_to_cap;
		} else {
			_color = Color.White;
			_cap_status = 0.0;
		}
	}
	
	
	void draw(RenderTarget renderTarget, RenderStates renderStates)
	{
		
		if (_disp[0] is null)
		{
			//writefln("initing %s",_pos);
			_disp[0] = new RectangleShape(Vector2f(16, 4));
			//_disp[0].position = Vector2f(_pos.x, _pos.y);
			_disp[0].position = Vector2f(_pos.x + 2.0f, _pos.y + 8.0f );
			//_disp[0].position.x = _pos.x - 2.0f; 
			//_disp[0].position.y = _pos.y - 6.0f;
			_disp[1] = new RectangleShape(Vector2f(4 ,16));
			//_disp[1].position = Vector2f(_pos.x , _pos.y);
			_disp[1].position = Vector2f(_pos.x + 8.0f, _pos.y + 2.0f );
			//_disp[1].position.x = _pos.x - 6.0f;
			//_disp[1].position.y = _pos.y - 2.0f;
		}
		
		_disp[0].fillColor = _color;
		_disp[1].fillColor = _color;
		
		renderTarget.draw(_disp[0], renderStates);
		renderTarget.draw(_disp[1], renderStates);
		
	}
	
	double getThreatDiffForTeam(TeamID in_team)
	{
		//TODO: what if we pass neutral
		if (in_team == TeamID.One)
		{
			return _team1_threat - _team2_threat;
		} else {
			return _team2_threat - _team1_threat;
		}
	}
	
	double getThreatAmountForTeam(TeamID in_team)
	{
		if (in_team == TeamID.One)
		{
			return _team1_threat;
		} else {
			return _team2_threat;
		}
	}
	
}