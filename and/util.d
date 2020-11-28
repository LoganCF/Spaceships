module and.util;

alias void delegate ( uint currentEpoch, real currentError, real correct_value, real nn_result ) trainingProgressCallback;

int nodeWinner( real [] ins )
{
  int n = 0;
  real temp = real.infinity * -1;
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
