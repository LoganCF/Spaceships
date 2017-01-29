/**

Author: Logan Freesh
Date: 2017.1.19


Leaky Rectified Liner Unit activation function

*/
module and.activation.leaky_relu;

import and.activation.model.iactivation;
import and.platform;
  /**b	
     leaky ReLU implementation of IActivationFunction
  */

class LeakyReLUActivationFunction : IActivationFunction
{

  ActivationId id() { return ActivationId.LEAKY_RELU; } /// nessecary for serialization
    /**
  

	if (x >0)
		x 
	else
		x * 0.1

  */

  real f ( real val ) 
  {
	 return val > 0 ? val : val * 0.1; //TODO: "leakyness" should be customizable
  }
  /**
	if( x > 0 )
		1
	else
		0.1
  */

  real fDerivative( real val )
  {
    return val > 0 ? 1.0 : 0.1;
  }

}

