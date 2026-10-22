extends "res://tools/maintenance_run.gd"
## Genuine campus six -> live rescue -> atomic optional scene -> unchanged safe seven.
const SCENE:="res://scenes/presentation/slice/rescue_return.tscn"

func phase_wait(wanted: String) -> bool:
	var deadline:=Time.get_ticks_msec()+45000
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		if tree.current_scene.phase==wanted:return true
	check(false,"return scene did not reach "+wanted);return false

func _run() -> void:
	if "--replay-only" not in OS.get_cmdline_user_args():await super._run();return
	tree=get_tree();tree.current_scene=null
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",true)
	check(ProfileRuntime.get_profile().maintenance_rescued and ProfileRuntime.get_profile().successful_sorties==_expected_returns(7),"portable preview is an actual seven-return rescue, not edited progress")
	if not failures.is_empty():finish();return
	var saved:=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):finish();return
	await _click(tree.current_scene.find_child("NavRest",true,false));await _frames(5)
	await _click(tree.current_scene.find_child("OpenRescueMoment",true,false))
	if not await _wait_scene(SCENE):check(false,"normal portable replay entry");finish();return
	if not await phase_wait("intro"):finish();return
	await _capture("portable_rescue_replay")
	await _click(tree.current_scene.screen.find_child("SkipRescueMoment",true,false))
	check(await _wait_scene("res://scenes/presentation/slice/hideout.tscn") and saved==FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH),"portable replay and skip preserve real profile bytes")
	finish()

func return_from_debrief() -> bool:
	var entry:=tree.current_scene.find_child("RescueDoorReturn",true,false) as Button
	check(entry!=null and not ProfileRuntime.get_profile().maintenance_rescued,"optional door entry appears before actual rescue settlement")
	if not entry:return false
	await _capture("rescue_debrief_entry");await _click(entry)
	if not await _wait_scene(SCENE):check(false,"normal optional return transition");return false
	check(ProfileRuntime.get_profile().maintenance_rescued and ProfileRuntime.get_profile().successful_sorties==_expected_returns(7) and ProfileRuntime.get_profile().sortie_checkpoint.is_empty(),"safe seventh return is durable before presentation begins")
	var saved:=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	if not await phase_wait("intro"):return false
	await _capture("rescue_waiting_outside")
	var room=tree.current_scene
	for i in room.FIRST.size():await _click(room.next_button)
	if not await phase_wait("crossing"):return false
	check(room.grip==1 and room.guest.position.z>3,"real opened door is held before the survivor crosses")
	await _capture("rescue_holding_door")
	if not await phase_wait("inside"):return false
	check(room.guest_walked>3.1 and room.grip==1,"physical guest crossing, not teleport or dialogue-only claim")
	for i in room.INSIDE.size():await _click(room.next_button)
	if not await phase_wait("ending"):return false
	check(room.latched and room.grip==0 and room.actor.position.distance_to(Vector3(2.9,0,.6))<.04,"heroine latches the door open, lets go and actually comes back")
	await _capture("rescue_back_beside_her")
	for i in room.LAST.size():await _click(room.next_button)
	check(room.phase=="done" and room.dialogue.text==tr(room.LAST[-1]),"final promise remains visible")
	await _click(room.exits.get_node("ReplayRescue"))
	check(room.phase=="arrival" and not room.latched,"replay resets the performance, not rewards")
	await _click(room.screen.find_child("SkipRescueMoment",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):return false
	check(saved==FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH),"replay and early skip preserve earned profile bytes")
	await _click(tree.current_scene.find_child("OpenRescueMoment",true,false))
	if not await _wait_scene(SCENE):return false
	await _click(tree.current_scene.screen.find_child("SkipRescueMoment",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):return false
	check(saved==FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH) and FinaleStory.next_mission(ProfileRuntime.get_profile())==WaterworksStory.MISSION,"ordinary Rest replay grants nothing and leaves next main operation at water")
	return failures.is_empty()

func finish() -> void:
	release()
	if "--read" not in OS.get_cmdline_user_args():check(ProfileRuntime.get_profile().successful_sorties==_expected_returns(7) and ProfileRuntime.get_profile().maintenance_rescued,"complete real earned rescue return required")
	evidence["checks"]=checks;evidence["failures"]=failures
	var file:=FileAccess.open(out.path_join("rescue_return_earned.json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"\t"));file.close()
	AudioDirector.shutdown_for_test();print("RESCUE_RETURN_RUN: %s (%d checks, %d shots)"%["PASS" if failures.is_empty() else "FAIL",checks,fired]);tree.quit(0 if failures.is_empty() else 1)
