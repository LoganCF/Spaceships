module steering;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.math;
import std.random;	
import std.stdio;
import std.conv;

import spaceships;
import collision;
import unit;
import mathutil;

import dsfml.graphics;
import dsfml.system;

const int window_height= 1000;
const int window_width = 1500;





enum Lookahead {SHORT=0, MEDIUM=1, FAR=2}

enum ShapeType {Circle, Triangle, Square, Diamond}

const double[] lookahead_times = [0.25, 0.5, 1.0];

class Dot
: Drawable
{
	// do steering stuff
	//void notifyColission
	//CircleShape _disp; 
	Shape _disp;
	
	Vector2d _pos;
	Vector2d[Lookahead.sizeof] _projected_pos;
	Vector2d _vel;
	double _max_vel;
	double _max_vel_sq;
	double _max_accel;
	double _max_accel_sq;
	
	//double _steering_lookahead_seconds = .25;
	Lookahead _steering_lookahead_type = Lookahead.SHORT;
	
	// TODO: make this its own object (steering behavior)
	double _steering_too_close = 200.0; // distance 20    // these two will be looked up based on type at some point
	double _steering_dont_care = 1250.0; // distance 50         // 5000.0; // distance 100
	
	double _steering_too_close_push = 200.0; // distance 20    // these two will be looked up based on type at some point
	double _steering_dont_care_push = 1250.0; // distance 50         // 5000.0; // distance 100
	
	double _steering_run_away = 2000.0;
	double _steering_constant_factor = 10.0;
	double _steering_destination = 1000.0;
	
	bool _destination_set = true;
	Vector2d _destination = Vector2d(window_width/2,window_height/2);
	
	Color _color;
	float _draw_size;
	
	this(double x, double y, 
		 double in_max_vel = 400.0, double in_max_accel = 800.0, float size = 2, ShapeType in_shape = ShapeType.Circle, Color in_color = Color.Red,
		 double in_st_too_close = 200.0, double in_st_dont_care = 1250.0,  double in_st_too_close_push = 0.0, double in_st_dont_care_push = 0.0,
		 Lookahead in_st_lookahead = Lookahead.SHORT )
	{
		//writefln("%f,%f",x,y);
		_pos = Vector2d( x, y );
		_projected_pos = _pos;
		_vel = Vector2d( 0, 0 );
		_max_vel = in_max_vel;
		_max_vel_sq = square(_max_vel);
		_max_accel = in_max_accel;
		_max_accel_sq = square(_max_accel);
		
		_destination = _pos;
		
		_steering_too_close = in_st_too_close;
	   _steering_dont_care = in_st_dont_care;
		
		_steering_too_close_push = (in_st_too_close_push != 0.0) ? in_st_too_close_push : in_st_too_close;
		_steering_dont_care_push = (in_st_dont_care_push != 0.0) ? in_st_dont_care_push : in_st_dont_care;
		
		//_steering_lookahead_seconds = in_st_lookahead;
		_steering_lookahead_type = in_st_lookahead;
		
		//_disp = new CircleShape(size);
		_disp = make_shape(in_shape, size);
		_disp.fillColor = in_color;
		_color = in_color;
		_draw_size = size;
	}
	
	/+this(double x, double y)
	{
		
	}+/
	
	void update( CollisionGrid grid /+Dot[] dots+/, double dt )
	{
		foreach (type ; [Lookahead.SHORT, Lookahead.MEDIUM, Lookahead.FAR])
		{
			_projected_pos[type] = _pos + _vel * lookahead_times[type];
		}
		//_projected_pos[Lookahead.SHORT] = _pos + _vel * lookahead_times[Lookahead.SHORT];
		
		//writefln("updatin'. I'm at %f, %f", _pos.x , _pos.y);
		Vector2d desired_vel = Vector2d(0,0);
		scope void delegate (Unit u) do_steering_delegate = delegate void(Unit u) 
		{
			Dot otherdot = cast(Dot) u;
			if (otherdot != this)
			{
				Vector2d pos_diff = _projected_pos[_steering_lookahead_type] - otherdot._projected_pos[_steering_lookahead_type];
				double dist_sq = square(pos_diff.x) + square(pos_diff.y);
				// do steering
				desired_vel += pos_diff * get_steering_factor(dist_sq, otherdot);	
				
				//writefln("pos_diff:%f,%f dist_sq:%f desired_vel:%f,%f",pos_diff.x,pos_diff.y, dist_sq, desired_vel.x, desired_vel.y);
				//sleep( seconds(1.0) );
			}
		};
		
		const double MAX_OTHER_STEERING_RANGE = square(60.0)/2;
		double query_radius = _steering_dont_care_push + MAX_OTHER_STEERING_RANGE;
		
		grid.collision_query_grid_only( _pos , query_radius , do_steering_delegate );
		
		/+foreach(otherdot ; dots)
		{
			if (otherdot != this)
			{
				Vector2d pos_diff = _projected_pos[_steering_lookahead_type] - otherdot._projected_pos[_steering_lookahead_type];
				double dist_sq = square(pos_diff.x) + square(pos_diff.y);
				// do steering
				desired_vel += pos_diff * get_steering_factor(dist_sq, otherdot);	
				
				//writefln("pos_diff:%f,%f dist_sq:%f desired_vel:%f,%f",pos_diff.x,pos_diff.y, dist_sq, desired_vel.x, desired_vel.y);
				//sleep( seconds(1.0) );
			}
		}+/
		
		assert ( !( isNaN( desired_vel.x) || isNaN(desired_vel.y) ), "Desired Velocity is NAN!"); 
		
		desired_vel += get_destination_steering();
		if( isNaN( desired_vel.x) || isNaN(desired_vel.y) ) 
		{
			return; // not an error here, can happen if destination == pos
		}
		//desired_vel += get_homesick_steering();
		if (isNaN(_pos.x) || isNaN(_pos.y))
		{
			throw new Error("Pos is NaN!");
		}
		
		Vector2d desired_accel = desired_vel - _vel;
		Vector2d accel;
		double mag_sq_accel = magnitude_sq(desired_accel);
		if( mag_sq_accel > _max_accel_sq ) 
		{
			Vector2d desired_accel_unit = desired_accel / sqrt(mag_sq_accel);
			accel = desired_accel_unit * _max_accel;
			if (isNaN(accel.x) || isNaN(accel.y))
			{
				writefln("desired_accel = %s, desired_vel %s ", desired_accel, desired_vel);
				throw new Error("accel is NaN!");
			}
		} else {
			accel = desired_accel;
		}
		_vel += accel * dt;
		
		if( magnitude_sq(_vel) > _max_vel_sq )
		{
			_vel = _vel/sqrt(magnitude_sq(_vel)) * _max_vel;
		}
		
		// and then move
		_pos += _vel * dt;
		
		if (isNaN(_pos.x) || isNaN(_pos.y))
		{
			throw new Error("Pos is NaN!");
		}
		
		//TODO: null out velocity if this happens
		//_pos.x = clamp(_pos.x, 0.0f, 400.0f);
		//_pos.y = clamp(_pos.y, 0.0f, 400.0f);
		//do_edge_collision_detection();
	}
	
	
	double get_steering_factor (double dist_sq, inout Dot other_dot) 
	{
		double too_close = _steering_too_close + other_dot._steering_too_close_push;
		double dont_care = _steering_dont_care + other_dot._steering_dont_care_push;
		
		
		if(dist_sq < too_close)
		{
			return _steering_run_away;
		} else 
		if( dist_sq < dont_care )
		{
			return _steering_constant_factor * (dont_care - too_close)/(dist_sq - too_close);
		} else {
			return 0.0; // too far, don't care.
		}
	}
	
	void draw(RenderTarget renderTarget, RenderStates renderStates) 
	{
		//writeln("drawin'");
		_disp.position = Vector2f( _pos.x - _draw_size , _pos.y - _draw_size);
		renderTarget.draw(_disp, renderStates);
	}
	
	void do_edge_collision_detection()
	{
		if ( _pos.x < 0.0 ) 
		{
			_pos.x = 0.0;
			_vel.x = 5.0;
		}
		if ( _pos.y < 0.0 ) 
		{
			_pos.y = 0.0;
			_vel.y = 5.0;
		}
		if ( _pos.x > 400.0 ) 
		{
			_pos.x = 400.0;
			_vel.x = -5.0;
		}
		if ( _pos.y > 400.0 ) 
		{
			_pos.y = 400.0;
			_vel.y = -5.0;
		}
	} 
	
	Vector2d get_homesick_steering()
	{
		Vector2d center = Vector2d(750,550);
		double homesick_range = 300.0f;
		double homesick_range_sq = square(homesick_range); 
		double scale = 100000.0f/homesick_range; 
		double dist_sq = square(_pos.x - center.x) + square(_pos.y - center.y);
		
		if (isNaN(_pos.x) || isNaN(_pos.y))
		{
			throw new Error("Pos is NaN!");
		}
		if (isNaN(dist_sq))
		{
			throw new Error("Shit be NaN.");
		}
		
		if(dist_sq > homesick_range_sq)
		{
			writef("diff is %s , scale is %f ",center - _pos, scale);
			writefln("multiplied: %s",(center - _pos) * scale);
			return (center - _pos) * scale;
		} else {
			return Vector2d( 0, 0 );
		}
	}
	
	Vector2d get_destination_steering()
	{
		if(!_destination_set)
		{
			return Vector2d(0.0, 0.0);
		}
		Vector2d diff = _destination - _projected_pos[_steering_lookahead_type];
		diff /= magnitude(diff);
		diff *= _steering_destination;
		return diff;
	}
}

class AntiDot : Dot
{
	this(double x, double y)
	{
		super(x, y);
		_disp.fillColor = Color.Blue;
	}
	
	override double get_steering_factor (double dist_sq, inout Dot other_dot) 
	{
		double factor = super.get_steering_factor(dist_sq, other_dot);
		
		return factor * -1;
	}
	
}

class FlockDot : Dot
{
	this(double x, double y)
	{
		super(x, y);
		_steering_constant_factor = -10.0;
		_disp.fillColor = Color.Green;
	}
	


	
}


/+float sqrt(float x)
{
	return pow(x, 0.5);
}+/

double get_dist_sq(Vector2d first, Vector2d second)
{
	Vector2d pos_diff = first - second;
	return square(pos_diff.x) + square(pos_diff.y);
}



Shape make_shape(ShapeType in_shape, float size)
{
	Shape retval;
	final switch(in_shape)
	{
		case ShapeType.Circle:
			retval = new CircleShape();
			(cast(CircleShape)retval).radius = size;
			break;
		case ShapeType.Square:
			retval = new RectangleShape(Vector2f(size*2.0f, size*2.0f));
			break;
		case ShapeType.Triangle:
			retval = new ConvexShape();
			(cast(ConvexShape)retval).addPoint( Vector2f(size     , 0.0f     ));
			(cast(ConvexShape)retval).addPoint( Vector2f(size*2.0f, size*2.0f));
			(cast(ConvexShape)retval).addPoint( Vector2f(0.0f     , size*2.0f));
			break;
		case ShapeType.Diamond:
			//retval = new RectangleShape(Vector2f(size*2.0f/SQRT2, size*2.0f/SQRT2));
			//(cast(RectangleShape)retval).rotation = 45;
			
			retval = new ConvexShape();
			(cast(ConvexShape)retval).addPoint( Vector2f(size     , 0.0f     ));
			(cast(ConvexShape)retval).addPoint( Vector2f(size*2.0f, size     ));
			(cast(ConvexShape)retval).addPoint( Vector2f(size     , size*2.0f));
			(cast(ConvexShape)retval).addPoint( Vector2f(0.0f     , size     ));
			break;
	}
	return retval;
}
