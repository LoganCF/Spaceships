/**

Author: Charles Sanders
Date: 2006.4.28


Main Import File

Example:
--------------------

// xor data

const real [] [] inputs  = [
			    [ 0,0 ],
			    [ 0,1 ],
			    [ 1,0 ],
			    [ 1,1 ]			    

];


const real [] [] outputs = [ 
			    [ 0 ],
			    [ 1 ],
			    [ 1 ],
			    [ 0 ]
];


void main ()
{

      IActivationFunction f = new SigmoidActivationFunction;

      Layer input = new Layer(2,0);
      Layer [] hidden = [ new Layer(2,2,f)  ];
      Layer output = new Layer(1,2,f) ;

      NeuralNetwork nn = new NeuralNetwork(input,hidden,output );
      CostFunction cost = new SSE( 0.001 );
      BackPropagation bp = new BackPropagation(nn,cost);

      bp.epochs = 50_000; 
      bp.learningRate = 0.5;
      bp.momentum = 0.5;

      void callback( uint currentEpoch, real currentError  )
	{
	  writefln("Epoch: [ %s ] | Error [ %f ] ",currentEpoch, currentError );
	}

      bp.setProgressCallback(&callback, 1000 );
      
      bp.train(inputs,outputs);

      writefln("%d",bp.actualEpochs);
      writefln("%f" ,bp.computeOutput(inputs[0])[0]);
      writefln("%f" ,bp.computeOutput(inputs[1])[0]);
      writefln("%f" ,bp.computeOutput(inputs[2])[0]);
      writefln("%f" ,bp.computeOutput(inputs[3])[0]);

}
--------------------


*/
module and.api;

public
{
  import and.cost.model.icostfunction;
  import and.cost.mse;
  import and.cost.sse;

  import and.activation.model.iactivation;
  import and.activation.sigmoid;
  import and.activation.tanh;
  import and.activation.linear; /+++/
  import and.activation.leaky_relu; /+++/
  
  import and.learning.model.ilearning;
  import and.learning.backprop;
  import and.learning.backprop_mod_reinforcement; /+++/

  import and.network.neuralnetwork;
  import and.network.neuron;
  import and.network.serialize;
  import and.network.layer;

  import and.util;

}

const float VERSION  = 0.3; /// version

