module strategy;

/*
Copyright (c) 2020, Logan Freesh
All rights reserved.

See "License.txt"
*/


import std.conv;
import std.stdio;

import spaceships;
import steering;
import collision;
import unit;
import factory_unit;
import capture_point;
import team;
import matchinfo;
import gamestateinfo;



// there is a list of strategies.  (in strategies .d)
// strategies and behaviors are both evaluables.
// each strategy has an array of evaluables.
// to evaluate a strategy, evaluate its elements until you get a result.

// a behavior is a qualifier function, a fetch first property function, and an ascending/decending bool, plus same for secondary property
// it evaluates all the CapturePoints that match the qualifier, and returns the one with the highest/lowest first property, ties broken by second property
// returns -1 if no match for the qualifier
// qualifier takes a stateinfo, and a point index, same as prop fetchers


//TODO: properties should have their own class, with (fetcher_fcn, bool ascending, epsilon = 0), and define a compare function

static const int EVALUABLE_NO_RESULT = -1;

interface Evaluable
{
	int evaluate(StateInfo) const;
}


alias bool function(StateInfo, int) qualifier;
alias double function (StateInfo, int) propertyGetter;

class Behavior: Evaluable
{
	qualifier _qualifier;
	propertyGetter _get_prop1;
	bool _prop1_ascending;
	propertyGetter _get_prop2;
	bool _prop2_ascending;
	
	
	this (qualifier in_qual, propertyGetter in_get_prop1, bool in_prop1_ascending, propertyGetter in_get_prop2 = null, bool in_prop2_ascending = true)
	{
		_qualifier = in_qual;
		_get_prop1 = in_get_prop1;
		_prop1_ascending = in_prop1_ascending;
		_get_prop2 = in_get_prop2;
		_prop2_ascending = in_prop2_ascending;
	}
	
	int evaluate(StateInfo gamestate) const
	{
		bool first1 = true;
		bool first2 = true;
		double best1;
		double best2;
		int result = EVALUABLE_NO_RESULT;
		foreach ( int i, CapturePoint point ; gamestate._points)
		{
			if (_qualifier(gamestate, i))
			{
				double prop1 = _get_prop1(gamestate, i);
				if (first1 || (_prop1_ascending ? prop1 > best1 : prop1 < best1))
				{
					result = i;
					best1 = prop1;
					first1 = false;
				} 
				else if (!first1 && prop1 == best1 && _get_prop2 !is null) 
				{
					double prop2 = _get_prop2(gamestate, i);
					if (first2 || (_prop2_ascending ? prop2 > best2 : prop2 < best2))
					{
						result = i;
						best2 = prop2;
						first2 = false;
					}
				}
			}
		}
		return result;
	}
	
}


class Strategy: Evaluable
{
	const Evaluable[] _behaviors;
	immutable char[] _name;
	
	this( immutable char[] in_name, inout Evaluable[] in_behaviors)
	{
		_name = in_name;
		_behaviors = in_behaviors;
	}
	
	int evaluate(StateInfo gamestate) const
	{
		foreach (const Evaluable behavior ; _behaviors)
		{
			int result = behavior.evaluate(gamestate);
			if (result != EVALUABLE_NO_RESULT)
				return result;
		}
		return EVALUABLE_NO_RESULT;
	}
}