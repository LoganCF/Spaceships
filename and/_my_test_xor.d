/** A simple XOR test.  */


import and.api;
import and.platform;


real [] [] inputs  = [
							 [ 0,0 ],
							 [ 0,1 ],
							 [ 1,0 ],
							 [ 1,1 ]			    
										];


real [] [] outputs = [ 
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
		Layer [] hidden = [ new Layer(144,2,f)  ];
		Layer output = new Layer(1,144,f) ;

		NeuralNetwork nn = new NeuralNetwork(input,hidden,output );
		CostFunction cost = new SSE();
		BackPropagation bp = new BackPropagation(nn,cost);

		bp.epochs = 1000; //1_000_000; 
		bp.learningRate = .05;
		bp.momentum = 0.5;
		bp.errorThreshold = 0.000001;

		void callback( uint currentEpoch, real currentError, real dummy, real dummy2  )
		{
			writefln("Epoch: [ %s ] | Error [ %f ] ",currentEpoch, currentError );
		}

		bp.setProgressCallback(&callback, 1000 );

		for(int i = 0; i < 40; i++)
		{
			bp.train(inputs,outputs);
			bp.epochs += 1000;
			
			writefln("%d",bp.actualEpochs);
			writefln("%.3f" ,bp.computeOutput(inputs[0])[0]);
			writefln("%.3f" ,bp.computeOutput(inputs[1])[0]);
			writefln("%.3f" ,bp.computeOutput(inputs[2])[0]);
			writefln("%.3f" ,bp.computeOutput(inputs[3])[0]);
		}
	}
	catch ( Exception e )
	{
		writefln("Exception: %s",e.toString() );
	}

}





