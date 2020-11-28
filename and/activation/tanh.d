/**

Author: Charles Sanders
Date: 2006.4.28


Tanh activation function

*/
module and.activation.tanh;

import and.activation.model.iactivation;
import and.platform;
  /**
     Tanh implemntation of IActivationFunction
  */

class TanhActivationFunction : IActivationFunction
{

  ActivationId id() { return ActivationId.TANH; } /// nessecary for serialization

  /** (e^x - e^-x) / (e^x + e^-x) */
  real f ( real val ) 
  {
	if(tanh(val) > 1.0 )
	  write("tanh of %+#.3f is %+#.3f ;", val, tanh(val) );//debug
    return tanh(val);
  }

  /** 1 - x^2 */
  real fDerivative( real val )
  {
    return ( 1.0 - (tanh(val) * tanh(val)) );
  }

}

