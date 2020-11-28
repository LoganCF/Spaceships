module gamestateinfo;

import team;
import unit;
import matchinfo;
import capture_point;

// a struct for communicating game state to AIs
// a stateinfo is a team, plus points, plus unit, plus matchinfo
// it does not own any of these things, and should not change them.
struct StateInfo
{
	TeamObj _team;
	Unit _unit;
	CapturePoint[] _points;
	MatchInfo _matchinfo;
	
	this(TeamObj in_team, Unit in_unit, CapturePoint[] in_points, MatchInfo in_matchinfo)
	{
		_team = in_team;
		_unit = in_unit;
		_points = in_points;
		_matchinfo = in_matchinfo;
	}
}