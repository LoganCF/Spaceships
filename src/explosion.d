module explosion;

import mathutil;

import std.conv;
import std.stdio;
import std.format;

import dsfml.graphics;
import dsfml.system;


// visual effect
class Explosion : Drawable
{
	double _duration;
	double _lifetime = 0.0;
	
	double _base_radius;
	double _final_size_factor;
	Vector2d _pos;
	CircleShape _disp; 
	
	static Color[128] s_colors;
	static bool s_colors_inited = false;
	
	this (Vector2d in_pos, double in_radius, double in_duration, double in_final_size_factor)
	{
		_pos = in_pos;
		_base_radius = in_radius;
		_final_size_factor = in_final_size_factor;
		_duration = in_duration;
		
		_disp = new CircleShape(_base_radius);
	}
	
	void update(double dt)
	{
		_lifetime += dt;
	}
	
	bool is_dead()
	{
		return _lifetime > _duration;
	}
	
	void draw(RenderTarget renderTarget, RenderStates renderStates) 
	{
		double radius = _base_radius * (1.0 + (_final_size_factor - 1.0) * (_lifetime / _duration));
		
		_disp.radius = radius;
		_disp.position = Vector2f( _pos.x - radius , _pos.y - radius);
		_disp.fillColor = calc_color(_lifetime / _duration);
		renderTarget.draw(_disp, renderStates);
	}
	
	// t is between 0.0 and 1.0
	static Color calc_color(double t)
	{
		if (!s_colors_inited)
		{
			init_colors();
		}
		int color_index = cast(int)(t * s_colors.length);
		if (color_index >= s_colors.length) { color_index = s_colors.length - 1; }
		if (color_index < 0) { color_index = 0; }
		return s_colors[ color_index ];
	}
	
	static void init_colors()
	{
		static const double gradient_stop = 3.0/8.0;
		Color color1 = Color.White;
		Color color2 = Color(255,128,0);
		Color color3 = Color.Black;
		
		Color blend(Color first, Color second, double ratio)
		{
			ubyte r = interpolate(first.r, second.r, ratio );
			ubyte g = interpolate(first.g, second.g, ratio );;
			ubyte b = interpolate(first.b, second.b, ratio );;
			/+ubyte r = to!ubyte( (1.0 - ratio) * first.r  + ratio * second.r );
			ubyte g = to!ubyte( (1.0 - ratio) * first.g  + ratio * second.g );
			ubyte b = to!ubyte( (1.0 - ratio) * first.b  + ratio * second.b );
			+/
			return Color(r,g,b);
		}
		
		for(int i = 0 ; i < s_colors.length; ++i)
		{
			double shade = cast(double)(i+1) / cast(double)s_colors.length; 
			
			if (shade < gradient_stop)
			{
				s_colors[i] = blend(color1, color2, shade / gradient_stop);
			} else {
				s_colors[i] = blend(color2, color3, (shade - gradient_stop) / (1.0 - gradient_stop));
			}
		}
	}

}