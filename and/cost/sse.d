module and.cost.sse;

import and.cost.model.icostfunction;
import and.platform;

/** Sum of Squared Error Function */

class SSE : CostFunction
{

  /** Computes the Cost, where p is the pattern in the training set

  E = ( expected_p - actual_p ) ^ 2 

  */
  
  override real f(real [] expected, real [] actual ) 
  {
    real error = 0;

    foreach ( int i, real e; expected )
      {
	
	error += ( e - actual[i] ) * ( e - actual[i] );
	
      }
    debug writefln("SSE.computeCost() == %f", error );
    //error = error / expected.length;

      return error ;
  }





}
