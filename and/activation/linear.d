/**

Author: Logan Freesh
Date: 2017.1.18


Linear activation function (for outputs)

*/
module and.activation.linear;

import and.activation.model.iactivation;
import and.platform;
  /**b	
     Linear implementation of IActivationFunction
  */

class LinearActivationFunction : IActivationFunction
{

  ActivationId id() { return ActivationId.LINEAR; } /// nessecary for serialization
    /**
  


    x

  */

  real f ( real val ) 
  {
	 return val;
  }
  /**
     1

  */

  real fDerivative( real val )
  {
    return 1.0;
  }

}

