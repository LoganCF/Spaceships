build -I.. -full -g -profile  api.d -cleanup -Tandd.lib -L/Map

build -I.. -full -cleanup -release -O api.d -Tand.lib -L/Map

build -I.. test_xor.d  andd.lib -cleanup -Xand -L/Map

dmd -I../.. -I.. -c -D -Dddoc doc/candydoc/candy.ddoc doc/candydoc/modules.ddoc network/neuralnetwork.d network/neuron.d network/layer.d network/model/ilayer.d network/model/ineuralnetwork.d learning/model/ilearning.d learning/backprop.d activation/model/iactivation.d activation/sigmoid.d activation/tanh.d api.d cost/model/icostfunction.d cost/mse.d cost/sse.d