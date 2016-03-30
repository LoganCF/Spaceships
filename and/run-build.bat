build -I.. -allobj -clean -debug -profile -version=VERBOSE all.d -Tandd.lib

build -I.. -allobj -clean -release -O all.d -Tand.lib

build -version=TRAIN -version=VERBOSE -I.. test_game_controller.d  andd.lib -Xand -clean -Ttrain_controller.exe
build -version=LOAD -version=VERBOSE -I.. test_game_controller.d  andd.lib -Xand -clean -Tload_controller.exe
build -version=VERBOSE -I.. test_xor.d  andd.lib -Xand -clean 