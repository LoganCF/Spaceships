


rem set dmd = X:\"Program Files (x86)"\Dlang\D_programs\Dcompiler\dmd2\windows\bin\dmd
rem X:\"Program Files (x86)"\Dlang\D_programs\Dcompiler\dmd2\windows\bin\dmd -I../.. -I.. -c -lib -D -Dddoc doc/candydoc/candy.ddoc doc/candydoc/modules.ddoc network/neuralnetwork.d network/neuron.d network/layer.d network/model/ilayer.d network/model/ineuralnetwork.d learning/model/ilearning.d learning/backprop.d activation/model/iactivation.d activation/sigmoid.d activation/tanh.d api.d cost/model/icostfunction.d cost/mse.d cost/sse.d

%dmd% -lib -I.. api.d mt.d platform.d network/layer.d network/neuralnetwork.d network/neuron.d network/serialize.d learning/backprop.d learning/backprop_mod_reinforcement.d activation/sigmoid.d activation/tanh.d activation/linear.d activation/leaky_relu.d cost/mse.d cost/sse.d util.d

%dmd% -I.. _my_test_xor.d api.lib neuralnetwork.lib -L/Map
 

 