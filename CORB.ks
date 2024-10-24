//To set
local DOApKM to 75. //km, Desired orbit altitude in kilometers(apoapsis in fact but its circular so Pe~=Ap)
local OINCL to 0. //degrees, Desired orbit inclination in degrees
local LiftOffAngle to 86. //degrees, Tune-in for more/less brutal launch, before gravity turn initiation. Works with Reach45At.
local Reach45At to 18. //km, Reach a pitch of 45° at <insert desired altitude> (agressivity of your gravity turn)
global lowerStage to false. //To differentiate who goes to orbit and who doesn't

//Not to set
global startT to missiontime.



//Mathematical functions
local function evalTHRAP { //Used to cut the throttle when apoapsis gets closer to desired apoapsis
	parameter x.
	return (max(0.01, min(1, 1-CONSTANT:e^((x/10000)-DOApKM/10)))).
}

global function preLaunchRoutine{
	sas off.
	global THR to 0.
	global STR to HEADING(90-OINCL, LiftOffAngle).
	lock throttle to THR.
	lock steering to STR.
}

global function Launch { //Initialisation and launch. As the name suggests
	if status="PRELAUNCH"{ //In case of CPU reboot in space or whatever situation that isn't prelaunch

		MSLAInit().
		//MSUIInit().

		preLaunchRoutine().

		UI("Liftoff!", "", "", "").
		MSLALogMessage("Liftoff").
 
		stage. set THR to 1.
		
		boosterJettisonInterruptRoutine().
		stagingInterruptionRoutine().
		utilitiesRoutine().

		Ascent().
	}

	else{
		UI("Not in prelaunch, launch sequence aborted", "", "", "").
		MSLALogMessage("Computer has been rebooted").
	}
}

local function AscentBurn{ //There's probably a more efficient way to do it, by for example coding that in the actual ascent function
	parameter epsilon.
	until apoapsis >= DOApKM*1000 - epsilon {
		set STR to heading(90-OINCL, min(LiftOffAngle, 90-vAng(up:vector, srfprograde:vector))).
		// if altitude > body:atm:height {set THR to evalTHRAP(apoapsis)*evalTHRtVel().}
		// else {set THR to evalTHRAP(apoapsis).}
		set THR to evalTHRAP(apoapsis).

		UI("Ascent in progress", "", "", "").
		wait 0.01.
	}
	set THR to 0.
}

local function AscentKeep {
	local altPID to pidLoop(0.01, 5, 0, 0, 0.2).
	set altPID:setpoint to DOApKM*1000.
	until altitude >= body:atm:height { //keeps the apoapsis at desired altitude if the burn ended while still in atmosphere
		// set STR to heading(90-OINCL, 90-vAng(up:vector, prograde:vector)).
		set STR to prograde.
		set THR to altPID:update(time:seconds, apoapsis).
		UI("Waiting atmospheric exit", "", "Angle : ", round(90-vAng(up:vector, prograde:vector), 1)).
		wait 0.1.
	}
}

local function Ascent { //Gravity turn ascent function

	//Parameters to tune
	until altitude > 12000 {
		UI("Initiating gravity turn", "", "", "").
		set STR to heading(90-OINCL, min(LiftOffAngle, 90-(45/(Reach45At*1000))*altitude)).
		wait 0.1.
	}
	MSLALogMessage("Gravity turn begins").

	AscentBurn(1000).

	if not lowerStage AscentKeep().
	
	set THR to 0.
}

local function OrbSpeedforAnyAltitude{
	parameter A.
	return sqrt(body:mu*(2/(body:radius+A) - 1/orbit:semimajoraxis)).
}

local function targetCircularOrbitSpeed{
	return sqrt(body:mu/(body:radius+DOApKM*1000)).
}

local function Circularisation{
	local dV to targetCircularOrbitSpeed()-OrbSpeedforAnyAltitude(apoapsis).
	MSLALogMessage("Executing burn maneuver").
	local CircNode to NODE(time:seconds + eta:apoapsis, 0, 0, dV).
	add CircNode.

	NodeExecute(CircNode).

	set THR to 0.
	set maneuvering to false.

	if status = "orbiting" {
		set THR to 0.
		UI("WARNING : AUTOPILOT OFF", "", "", "").
		print("Orbit acheived").
		print("Standby").
		MSLALogMessage("Orbit acheived.").
		if not hasnode {
			Idle().
		}
	}
}