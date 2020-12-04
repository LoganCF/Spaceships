/**

Author: Charles Sanders
Date: 2006.4.28


Neuron container

*/


module and.network.neuron;

/** 
The neuron class contains weights for each of the synapses plus its bias, its error value and its actual value.
*/
class Neuron 
{
  real [] synapses; /// weights for the synapses
  real bias; /// bias

  real error = 0.0; /// current error value
  real value = 0.0; /// actual value
  real [] lastWeightChange; /// for momentum
  real lastBiasChange = 0.0; /// for momentum
}
