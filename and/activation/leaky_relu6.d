/**

Author: Logan Freesh
Date: 2020.12.5


Leaky Rectified Linear Unit activation function

*/
module and.activation.leaky_relu6;

import and.activation.model.iactivation;
import and.platform;
  /**	
     leaky ReLU6 implementation of IActivationFunction
	 I'm not sure anyone else has felt the need to make a leaky version of ReLU6,
	 but I'm doing it here because ReLU nets can have too many synapses "drop out" 
	 and never activate if they are trained too much, and this library needs to 
	 work if the nets keep getting more training.
  */

class LeakyReLU6ActivationFunction : IActivationFunction
{

  ActivationId id() { return ActivationId.LEAKY_RELU6; } /// nessecary for serialization
    /**
  
	if 0 < val < 6, just return val. Outside of that range, it has a slope of .1.

	*/

  real f ( real val ) 
  {
	// 
	// 5.4 is 6 - (6 * .1),  so (5.4 + val * 0.1) is the same as (6 + ((val-6) * .1))
	 return val > 0 
		? (val <= 6.0 ? val : 5.4 + val * 0.1) 
		: val * 0.1;
  }
  

  real fDerivative( real val )
  {
    return (val > 0 && val < 6) ? 1.0 : 0.1;
  }

}

