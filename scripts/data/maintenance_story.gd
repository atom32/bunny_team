class_name MaintenanceStory
extends RefCounted
## First playable sealed-zone rescue. Progress is earned only on a safe return.
const AREA:=&"maintenance_zone"
const MISSION:=&"maintenance_rescue"
const ORDER:=[&"maintenance_bypass",&"maintenance_release",&"maintenance_gate",&"maintenance_rescue"]
const SAFE:=Vector3(0,0,-36)
const INTRO:="Su Mi: Hello? Do not hang up. We are outside.\nWoman: I did not hang up. You keep disappearing.\nShen: Leave the south door open.\nTang Kui: Then stop talking through the door and go get her."
const RELEASE:="Woman: My name is Xu Tang. I cannot run very fast.\nSu Mi: I can hear you just fine now.\nXu Tang: Then... do not close the door on me."
const GATE:="Shen: Keep working. I have the outside handle.\nTang Kui: She is not asking you to hurry. She has been holding it since you arrived.\nShen: Tang Kui.\nTang Kui: All right, all right. I am coming too."
const END:="[Someone on the other side takes Xu Tang's hand.]\nXu Tang: I thought you had gone.\nSu Mi: I kept calling.\nXu Tang: I know. I was angry at the radio.\nTang Kui: Good. You can be angry at me over dinner.\nShen: Everyone is through. Now close the door."
static func done(session: SortieSession,id: StringName) -> bool:return WaterworksStory.done(session,id)
static func available(profile: ProfileState) -> bool:return profile and profile.first_mission_completed and profile.campus_chapter.finished
static func valid_objectives(area: StringName,mission: StringName,summaries: Array) -> bool:
 if (area==AREA)!=(mission==MISSION):return false
 if area!=AREA:return true
 var completed:={}
 for raw in summaries:
  if int(raw.get("status",-1))==ObjectiveState.Status.COMPLETED:completed[StringName(raw.objective_id)]=true
 for i in range(1,ORDER.size()):
  if completed.has(ORDER[i]) and not completed.has(ORDER[i-1]):return false
 return true
static func returned(outcome: SortieOutcome) -> bool:
 return outcome and outcome.result_type==SortieOutcome.ResultType.COMPLETED and outcome.area_id==AREA and outcome.mission_id==MISSION and outcome.mission_completed
static func ending(outcome: SortieOutcome) -> String:return TranslationServer.translate(END) if returned(outcome) else ""
static func guide(session: SortieSession) -> Array:
 if session and not session.maintenance.is_empty():return MaintenanceJourney.guide(session)
 var detail:="West pressure station / 6s close work; damage interrupts. South retreat remains open."
 if done(session,ORDER[0]):detail="Ward door / release Xu Tang. Watch for infected in the corridor."
 if done(session,ORDER[1]):detail="North shutter / 8s close work. Xu Tang follows within 12m; interact with her to wait or follow."
 if done(session,ORDER[2]):detail="Bring Xu Tang through the north shutter. Stay near her; she will not teleport to you."
 if done(session,ORDER[3]):detail="Xu Tang is at the north exit. Extract safely to bring this rescue home."
 return [TranslationServer.translate("SEALED MAINTENANCE / THE VOICE BEHIND THE DOOR"),TranslationServer.translate(detail)]
