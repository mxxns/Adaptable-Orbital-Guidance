//To set when calling Launch()
global DOPeKM to 0. //[km], desired periapsis
global DOApKM to 0. //[km], desired apoapsis
local OINCL to 0. //[deg], Desired orbit inclination in degrees, 0 being north, 90 east, 180 south and 270 west
local LiftOffAngle to 0. //[deg], Tune-in for more/less brutal launch, before gravity turn initiation. Works with Reach45At.
local Reach45At to 0. //[km], Reach a pitch of 45° at <insert desired altitude>

//Not to set
global startT to missiontime.

global function preLaunchRoutine{
	sas off.
	global THR to 0.
	global STR to HEADING(90-OINCL, LiftOffAngle).
	global DWL to true.
	lock throttle to THR.
	lock steering to STR.
}

global function Launch { //Initialisation and launch. As the name suggests
	parameter doWeprL, doWeLog, doWeUtil, CustomFairing, Ap is 75, Pe is 75, Incl is 0, LOA is 86, R45 is 14.  
	if status="PRELAUNCH"{ //In case of CPU reboot in space or whatever situation that isn't prelaunch
		set DWL to doWeLog.
		set DOApKM to Ap.
		set DOPeKM to Pe.
		set OINCL to 90-Incl.
		set LiftOffAngle to LOA.
		set Reach45At to R45.

		if DWL MSLAInit().
		//MSUIInit().

		if doWeprL preLaunchRoutine().

		UI("Liftoff!", "", "", "").
		if DWL MSLALogMessage("Liftoff").
 
		stage. set THR to 1.
		
		boosterJettisonInterruptRoutine().
		stagingInterruptionRoutine().	
		if doWeUtil utilitiesRoutine(CustomFairing).

		Ascent().
	}

	else{
		UI("Not in prelaunch, launch sequence aborted", "", "", "").
		if DWL MSLALogMessage("Computer has been rebooted").
	}
}

local function AscentBurn{ //There's probably a more efficient way to do it, by for example coding that in the actual ascent function
	parameter epsilon.
	local THRPid to pidLoop(0.001, 0, 0, 0, 1).
	set THRPid:setpoint to DOApKM*1000.
	until apoapsis >= DOApKM*1000 - epsilon {
		set STR to heading(OINCL, min(LiftOffAngle, 90-vAng(up:vector, srfprograde:vector))).
		set THR to THRPid:update(time:seconds, apoapsis).

		UI("Ascent in progress", "", "", "").
		wait 0.01.
	}
	set THR to 0.
}

global function AscentKeep {
	local altPID to pidLoop(0.001, 5, 0, 0, 0.2).
	set altPID:setpoint to DOApKM*1000.
	until altitude >= body:atm:height { //keeps the apoapsis at desired altitude if the burn ended while still in atmosphere
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
		set STR to heading(OINCL, min(LiftOffAngle, 90-(45/(Reach45At*1000))*altitude)).
		wait 0.1.
	}
	if DWL MSLALogMessage("Gravity turn begins").

	AscentBurn(1000).
	
	set THR to 0.
}

local function OrbSpeedforAnyAltitude{
	parameter A.
	return sqrt(body:mu*(2/(body:radius+A) - 1/orbit:semimajoraxis)).
}

local function targetOrbitSpeed{
	return sqrt(body:mu/(body:radius+DOPeKM*1000)).
}

global function Circularisation{
	local dV to targetOrbitSpeed()-OrbSpeedforAnyAltitude(apoapsis).
	if DWL MSLALogMessage("Executing burn maneuver").
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
		if DWL MSLALogMessage("Orbit acheived.").
		if not hasnode {
			Idle().
		}
	}
}