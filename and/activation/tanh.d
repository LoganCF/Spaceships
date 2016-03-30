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
    return tanh(val);
  }

  /** 1 - x^2 */
  real fDerivative( real val )
  {
    return ( 1.0 - (val * val) );
  }

}

