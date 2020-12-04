/**

Author: Charles Sanders
Date: 2006.4.28


Save or load a network to a file

*/
module and.network.serialize;


import and.network.neuralnetwork;
import and.network.layer;
import and.network.neuron;
import and.activation.model.iactivation;
import and.activation.sigmoid;
import and.activation.tanh;
import and.activation.linear;
import and.activation.leaky_relu;
import and.platform;


/// this supports only one hidden layer at the moment
/// also only supports networks whose layers use the same activation function

/**
   
Save the trained network to a file to load later

   Parameters: fullPathToFile, neuralNetworkInstance
   Returns: true or false depending on success or failure
*/

bool saveNetwork(NeuralNetwork nn , char [] path)
{
	bool reported = false;

	bool ret = true;
	string dup_path = path.dup;
	try 
	{
		//TODO: std.stream is obsolete.
		stdstream.File f = new stdstream.File(dup_path, stdstream.FileMode.Out );
		f.writeString( /+std.string.+/to!string(nn.input.neurons.length) ~ "\t" ~ to!string(nn.hidden.length) ~ "\t");
		foreach (layer; nn.hidden)
		{
			f.writeString(/+std.string.+/to!string(layer.neurons.length) ~ "\t");
		}
		f.writeLine( /+std.string.+/to!string(nn.output.neurons.length) ~ "\t" ~ /+std.string.+/to!string(cast(int)nn.output.activationFunction.id() ) );

		foreach (layer ; nn.hidden)
		{
			foreach ( Neuron n; layer.neurons ) //TODO: support multi hidden layers
			{
				for ( int i = 0 ; i < n.synapses.length;i++ )
				{
					f.writeLine(/+std.string.+/to!string( n.synapses[i] ));
					if(isNaN(n.synapses[i]) && !reported ) {writefln("weight is %f",n.synapses[i]);  reported = true;} 
					// write last weight change
					f.writeLine(to!string( n.lastWeightChange[i] ));
				}

				f.writeLine(/+std.string.+/to!string( n.bias ) );
				if( isNaN(n.bias) && !reported ) {writefln("weight is %f",n.bias); reported = true;}
				// write last bias change
				f.writeLine(to!string( n.lastBiasChange ));
			}
		}


		foreach ( Neuron n; nn.output.neurons )
		{
			for ( int i = 0 ; i < n.synapses.length;i++ )
			{
				f.writeLine(/+std.string.+/to!string(n.synapses[i]) );
				//write last wieght change
				f.writeLine(to!string( n.lastWeightChange[i] ));
			}

			f.writeLine(/+std.string.+/to!string(n.bias ) );
			// write last bias change
			f.writeLine(to!string( n.lastBiasChange ));

		}

		f.close();

	}
	catch ( Exception e )
	{
		ret = false;
	}

	return ret;

}


/**
   
Load a trained network from a previously saved file

   Parameters: fullPathToFile
   Returns: the neural network instance
*/

NeuralNetwork loadNetwork(char [] path )
{
	bool reported = false;

   NeuralNetwork nn = null;
      
	string dup_path = path.dup;
	stdstream.File f = new stdstream.File(dup_path, stdstream.FileMode.In );
	char [] l = f.readLine();
	char [] [] data = l.split("\t");

	int data_iter = 0;
	
	int ni = to!int(data[data_iter++]);
	int num_hidden_layers = to!int(data[data_iter++]);
	int [] nh = [];
	foreach (int i; 0..num_hidden_layers)
	{
		debug writefln("loading alayer size. %d", num_hidden_layers);
		nh ~= to!int(data[data_iter++]);
	}
	int no = to!int(data[data_iter++]);
	int af = to!int(data[data_iter++]);

	IActivationFunction afunc;

	final switch ( af )
	{
		case ActivationId.SIGMOID    : afunc = new SigmoidActivationFunction;   break;
		case ActivationId.TANH       : afunc = new TanhActivationFunction;      break;
		case ActivationId.LINEAR     : afunc = new LinearActivationFunction;    break;
		case ActivationId.LEAKY_RELU : afunc = new LeakyReLUActivationFunction; break;
		
		
	}

	writeln("sure am loading");
	
	Layer input = new Layer( ni, 0 );
	Layer [] hidden = [];
	hidden ~= new Layer( nh[0], ni, afunc);
	foreach (num; 1..nh.length)
	{
		hidden ~= new Layer( nh[num], nh[num-1], afunc);
	}
	Layer output = new Layer( no, nh[$-1], afunc ) ;
	
	
	nn = new NeuralNetwork(input, hidden, output, true);

	foreach (layer ; nn.hidden)
	{
		foreach ( Neuron n; layer.neurons )
		{
			for ( int i = 0 ; i < n.synapses.length;i ++ )
			{
				char [] line = f.readLine();

				n.synapses[i] = line.to!real();
				if(isNaN(n.synapses[i]) && !reported ) {writefln("weight is %f",n.synapses[i]); reported = true;}
				n.lastWeightChange[i] = to!real( f.readLine());
			}

			n.bias = to!real(f.readLine() );
			if(isNaN(n.bias) && !reported ) {writefln("bias is %f",n.bias); reported = true; }
			// read last bias change
			n.lastBiasChange = to!real(f.readLine() );
		}
	}



	foreach ( Neuron n;nn.output.neurons )
	{
		for ( int i = 0 ; i < n.synapses.length;i ++ )
		{
			char [] line = f.readLine();
			n.synapses[i] = line.to!real();
			n.lastWeightChange[i] = to!real( f.readLine());
		}

		n.bias = to!real(f.readLine() );
		// read last bias change
		n.lastBiasChange = to!real(f.readLine() );
	}

   return nn;
}
