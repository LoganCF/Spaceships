/**

Author: Charles Sanders
Date: 2006.4.28


ILearningFunction interface

*/
module and.learning.model.ilearning;


/**
The interface for the learning part of the neural network

*/
interface ILearningFunction
{
  /**
     Parameters: 2d array of inputs , 2d array of expected outputs
  */
  void train (real [] [] inputs , real [] [] expectedOutputs );
  /**
     Parameters: array of inputs
     Returns: the computed output
  */
  real [] computeOutput( real [] ins) ;

  /** Parameters: trainingProgressCalback ( see util.d ), when to call the callbacks */


}


