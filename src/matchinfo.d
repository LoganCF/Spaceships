module matchinfo;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import team;    // for INCOME_PER_POINT
import steering; // for Vector2d

import std.math;



//used for making information about the match available to the team AIs
struct MatchInfo
{
	double _battlefield_width;
	double _battlefield_height;
	double _battlefield_diagonal;
	double _timer_max;
	double _tickets_max;
	double _total_income_from_points;
	
	this( Vector2d battlefield_size, double in_timer_max, double in_max_tickets, int num_points )
	{
		_battlefield_width = battlefield_size.x;
		_battlefield_height = battlefield_size.x;
		_battlefield_diagonal = sqrt( square(battlefield_size.x) + square(battlefield_size.y)  );
		
		_timer_max   = in_timer_max;
		_tickets_max = in_max_tickets;
		
		_total_income_from_points = num_points * INCOME_PER_POINT;
	}
	
}