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
	LEAKY_RELU /+++/
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

