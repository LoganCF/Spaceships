module mathutil;

import std.math;
import std.conv;

import dsfml.graphics;
import dsfml.system;

alias Vector2!double Vector2d;


// scalar stuff


T clamp(T)(T x, T min, T max )
{
	if( x < min) return min;
	if( x > max) return max;
	return x;
}

T square(T)(T x)
{
	return x * x;
}

alias easing_function = double function(double);
// x should be between 0.0 and 1.0
// easing functions should return something in the same range
double easing_linear(double x)
{
	return x;
}

T interpolate(T)(T start, T end, double x, easing_function easing = &easing_linear )
{
	double ratio = easing(x);
	return to!(T)((1.0 - ratio) * start  + ratio * end);
}

// Vectors


T magnitude_sq(T) (Vector2!(T) v) 
{
	return square(v.x) + square(v.y);
}

T magnitude(T)(Vector2!(T) vec)
{
	return sqrt(magnitude_sq(vec));
}

Vector2!(T) to_unit_vector(T)(Vector2!(T) vec)
{
	T magn = magnitude(vec);
	return Vector2!(T)(vec.x / magn, vec.y / magn);
}

Vector2!(T)[2] orthagonals(T)(Vector2!(T) vec)
{
	return [Vector2!(T)(-vec.y, vec.x), Vector2!(T)(vec.y, -vec.x)];
}

Vector2!(T)[2] unit_orthagonals(T)(Vector2!(T) vec)
{
	return orthagonals(to_unit_vector(vec));
}