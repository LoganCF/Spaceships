/**

Author: Charles Sanders
Date: 2006.4.28


Sigmoid activation function

*/
module and.activation.sigmoid;

import and.activation.model.iactivation;
import and.platform;
  /**
     Sigmoid implemntation of IActivationFunction
  */

class SigmoidActivationFunction : IActivationFunction
{

  ActivationId id() { return ActivationId.SIGMOID; } /// nessecary for serialization
    /**
  


1  / (1 + e^x )

  */

  real f ( real val ) 
  {
	 assert(!isNaN(val),"sigmoid. garbage in");
	 real retval = ( 1.0 / ( 1.0 + exp( -val ) ) );
	 assert(!isNaN(retval),"sigmoid. garbage out");
	 if(retval > 1.0){ // debug
		writeln("sigmoid too bigmoid.");
	 }
    return retval;

  }
  /**
     x ( 1 - x )

  */

  real fDerivative( real val )
  {
    return ( val * ( 1.0 - val ) );
  }

}

