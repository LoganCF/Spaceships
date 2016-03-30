/** A simple XOR test.  */


import and.api;
import and.platform;


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

  try 
    {


      IActivationFunction f = new SigmoidActivationFunction;


      Layer input = new Layer(2,0);
      Layer [] hidden = [ new Layer(2,2,f)  ];
      Layer output = new Layer(1,2,f) ;

      NeuralNetwork nn = new NeuralNetwork(input,hidden,output );
      CostFunction cost = new SSE();
      BackPropagation bp = new BackPropagation(nn,cost);

      bp.epochs = 1_000_000; 
      bp.learningRate = 0.5;
      bp.momentum = 0.5;
      bp.errorThreshold = 0.00001;

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
  catch ( Exception e )
    {
      writefln("Exception: %s",e.toString() );
    }

}





