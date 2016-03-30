module and.cost.mse;

import and.cost.model.icostfunction;
import and.platform;

/** Mean Squared Error CostFunction , only difference from SSE is MSE is normalized with the size of training pattern */
class MSE : CostFunction
{



  /** Computes the Cost, where p is the pattern in the training set, and M is the length of patterns

  E = 1/M ( expected_p - actual_p ) ^ 2 

  */


  override real f(real [] expected, real [] actual )
  {
    real error = 0;

    foreach ( int i, real e; expected )
      {
	
	error += ( e - actual[i] ) * ( e - actual[i] );
	
      }

      error = error / expected.length;

      debug writefln("MSE.computeCost() == %f", error );
      return error;
  }





}
