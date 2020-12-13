/**

Author: Charles Sanders
Date: 2006.4.28

Activation function interface
*/

module and.activation.model.iactivation;
/**
   The ID's are neccessary for saving the network to file
*/
enum ActivationId
  {
    SIGMOID,
    TANH,
	LINEAR, /+++/
	LEAKY_RELU, /+++/
	LEAKY_RELU6 /+++/
  }

  /**
     The main activation function 
     f: for forward pass calculations
     fDerivative: for backward pass learning
  */

interface IActivationFunction 
{
  real f( real x); /// forward pass
  real fDerivative( real x); /// backward pass
  ActivationId id(); /// neccessary for serializing
}


string ActivationIdToStr(ActivationId id)
{
	final switch(id)
	{
		case ActivationId.SIGMOID:
			return "Sigmoid";
		case ActivationId.TANH:
			return "Tanh";
		case ActivationId.LINEAR:
			return "Linear";
		case ActivationId.LEAKY_RELU:
			return "Leaky ReLU";
		case ActivationId.LEAKY_RELU6:
			return "Leaky ReLU6";
	}
}