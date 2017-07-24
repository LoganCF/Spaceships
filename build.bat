
setlocal
set dmd=X:\"Program Files (x86)"\Dlang\D_programs\Dcompiler\dmd2\windows\bin\dmd


cd and
call _my_build.bat
cd..




%dmd% src\spaceships.d src\steering.d src\collision.d src\unit.d src\factory_unit.d src\capture_point.d ^
src\team.d src\team_manual.d src\team_random.d src\team_scripted_capper.d src\team_scripted_defender.d src\team_mod_reinforcement.d ^
src\ai_base.d src\ai_command.d src\ai_build.d  ^
src\record_keeper.d src\nn_manager.d src\nn_manager_classifier.d src\nn_manager_mod_reinforcement.d src\nn_manager_copycat.d src\network_input_display.d src\matchinfo.d ^
-profile=gc -debug -gc -unittest -IDSFML_2.1_DMD_2.086.2_32bits\import\ -Iand\ -L+DSFML_2.1_DMD_2.086.2_32bits\lib\ -L+DSFML_2.1_DMD_2.086.2_32bits\lib\ dsfml-graphics.lib dsfml-window.lib dsfml-system.lib dsfmlc-graphics.lib dsfmlc-window.lib dsfmlc-system.lib and\api.lib and\neuralnetwork.lib


endlocal
echo "Build Complete!"
