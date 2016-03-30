module and.util;

alias void delegate ( uint currentEpoch, real currentError ) trainingProgressCallback;

int nodeWinner( real [] ins )
{
  int n = 0;
  real temp = 0.0;
  for ( int i  = 0 ; i < ins.length; i++ )
    {
      if ( ins[i] > temp ) 
	{
	  n = i;
	  temp = ins[i];
	}

    }

  return n;

}
