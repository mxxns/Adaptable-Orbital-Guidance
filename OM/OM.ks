@lazyglobal off.
sas off.

runpath("MSLA.ks").
runpath("MSUI.ks").

clearscreen.

//To set (DOApKM is 120 minimum)m
local DOApKM to 85. //Desired orbit altitude in kilometers(apoapsis in fact but its circular so Pe~=Ap)
local OINCL to 0. //Desired orbit inclination in degrees
local LiftOffAngle to 88. //Tune-in for more/less brutal gravity turn depending on your rocket

//Not to set
local THR to 1.
local STR to HEADING(90-OINCL, LiftOffAngle).

//Mathematical functions
local function evalTHRAP { //Used to cut the throttle when apoapsis gets closer to desired apoapsis
	parameter x.
	return (max(0.01, min(1, 1-CONSTANT:e^((x/10000)-DOApKM/10)))).
}

// local function evalTHRtVel {
// 	return (max(0.1, min(1, 1-CONSTANT:e^(airspeed - ADDONS:FAR:TERMVEL)))).
// }


local function findBoosters{ //Finds which engine on the craft are boosters
	local englist to list().
	list engines in englist.
	local booster to list().
	for eng in englist{
		if eng:consumedresources:values[0] = "CONSUMEDRESOURCE(SOLIDFUEL)" and eng:possiblethrust > 20 {
			booster:add(eng).
		}
	}
	return booster.
}

local function boosterJettisonInterruptRoutine{ //Activates when the boosters are to be thrown
	for booster in findBoosters(){
			when booster:flameout then {
				if not boostersJettisoned { //This variable is changed when they'll be jettisoned, so the CPU doesn't stage for no reason
					UI("Boosters jettison", "", "", "").
					MSLALogMessage("Boosters jettison").
					stage.
				}
				set boostersJettisoned to true.
			preserve.
		}
	}
}

local function stagingInterruptionRoutine{ //Activates when the whole stage is to be thrown
	when STAGE:DELTAV:VACUUM <= 0 then {
		UI("Staging", "", "", "").
		MSLALogMessage("Staging").

		//Saving throttle state right before staging and stopping throttle
		local sTHR to THROTTLE.
		set THR to 0.

		stage.

		//Reset throttle to its previous value before staging
		set THR to sTHR.
	preserve.
	}
}

local antennaD to false.

local function antennaDeploy{ //inspired by space_is_hard 's work (github)
	//Finding antennas
	local antList to list().
	for ant in ship:modulesnamed("ModuleDeployableAntenna") {
		antList:add(ant:part).
	}
	if not antennaD {
		if status = "Landed" and ship:velocity:surface:mag < 0.1 or altitude > body:atm:height {
			//Deploying antennas
			for ant in antList {
				ant:getmodule("ModuleDeployableAntenna"):doaction("extend antenna", true).
			}
			set antennaD to true.
		}
	}
	else if antennaD {
		if altitude < body:atm:height and ship:velocity:surface:mag >= 0.01 {
			//Retracting antennas
			for ant in antList {
				ant:getmodule("ModuleDeployableAntenna"):doaction("retract antenna", true).
			}
			set antennaD to false.
		}
	}
}

local fairingD to false.

local function fairingDeploy {
	if not fairingD {
		//Finding fairing
		if altitude > 0.95*body:atm:height {
			local fairList to list().
			for fair in ship:modulesnamed("ModuleProceduralFairing") {
				fair:doevent("deploy").
			}
			set fairingD to true.
		}
	}
}

local solarD to false.

local function solarDeploy {
	if not solarD {
		if status = "Landed" and ship:velocity:surface:mag < 0.1 or altitude > body:atm:height {
			panels on.
			set solarD to true.
		}
	}
	if solarD {
		if altitude < body:atm:height and ship:velocity:surface:mag >= 0.01 {
			panels off.
			set solarD to false.
		}
	}
}

local function utilitiesRoutine{
	when 1=1 then {
		if not fairingD {fairingDeploy().}
		antennaDeploy().
		solarDeploy().
		preserve.
	}
}

local function Launch { //Initialisation and launch. As the name suggests
	if status="PRELAUNCH"{ //In case of CPU reboot in space or whatever situation that isn't prelaunch

		MSLAInit().
		//MSUIInit().

		lock throttle to THR.
		lock steering to STR.

		UI("Liftoff!", "", "", "").
		MSLALogMessage("Liftoff").
 
		stage.
		global boostersJettisoned to false.
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

local function Ascent { //Gravity turn ascent function

	//Parameters to tune
	until altitude > 500 and airspeed>100 {
		UI("Waiting for gravity turn window", "", "", "").
		wait 0.01.
	}

	MSLALogMessage("Gravity turn begins").

	AscentBurn(1000).

	local altPID to pidLoop(0.01, 5, 0, 0, 0.2).
	set altPID:setpoint to DOApKM*1000.

	until altitude >= body:atm:height { //keeps the apoapsis at desired altitude if the burn ended while still in atmosphere
		// set STR to heading(90-OINCL, 90-vAng(up:vector, prograde:vector)).
		set STR to prograde.
		set THR to altPID:update(time:seconds, apoapsis).
		UI("Waiting atmospheric exit", "", "Angle : ", round(90-vAng(up:vector, prograde:vector), 1)).
		wait 0.01.
	}
	set THR to 0.
	Circularisation().
}

local function OrbSpeedforAnyAltitude{
	parameter A.
	return sqrt(body:mu*(2/(body:radius+A) - 1/orbit:semimajoraxis)).
}

local function targetCircularOrbitSpeed{
	return sqrt(body:mu/(body:radius+DOApKM*1000)).
}

local function NodeExecute{
	parameter Nd.

	local sumISP to 0.
	local sumMMFR to 0. //Max Mass Flow Rate, summed for all the engines selected
	local sumMT to 0. //Max TThrust, summed for all the engines selected
	local englist to list().
	list engines in englist.
	for eng in englist {
		if eng:isp > 0 { //We select only this stage's engines - they must be activated
			set sumMMFR to sumMMFR + eng:maxmassflow.
			set sumMT to sumMT + eng:maxthrust.
  		}
	}
	set sumISP to sumMT/(CONSTANT:g0*sumMMFR).

	local HalfBurnT to (mass/sumMMFR)*(1-constant:e^(-Nd:deltaV:mag/(2*sumISP*constant:g0))).
	local burnVS to Nd:burnvector.

	until vAng(ship:facing:vector, Nd:burnvector) < 1{
		set STR to Nd:burnvector.
		UI("Turning to node burn vector", "", "Angle :", round(vAng(ship:facing:vector, STR), 1) + "°").
		wait 0.1.
	}
	until Nd:eta <= HalfBurnT {
		UI("Nd:eta : " + round(Nd:eta, 2), "burnT/2 : " + round(HalfBurnT, 2), "ISP : ", round(sumISP, 2)).
		wait 0.1.
	}
	until vDot(burnVS, Nd:burnvector) < 0.1 {
		set THR to max((1-constant:e^(-Nd:burnvector:mag*40/burnVS:mag)), 0.01).
		// set THR to max(Nd:deltaV:mag/(maxThrust/mass), 0.01).
		set STR to Nd:burnvector.
		UI("Executing node maneuver", "", "", "").
		wait 0.1.
	}
	set THR to 0.
	remove Nd.
}

local function Circularisation{
	local dV to targetCircularOrbitSpeed()-OrbSpeedforAnyAltitude(apoapsis).
	MSLALogMessage("Executing burn maneuver").
	if stage:deltaV:current < dV {stage.}
	local CircNode to NODE(time:seconds + eta:apoapsis, 0, 0, dV).
	add CircNode.

	NodeExecute(CircNode).

	set THR to 0.

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

Launch().

local function NodeRemoveAll {
	local NDS to list().
		set NDS to allnodes.
		for nd in NDS {
			remove nd.
		}
}

global function rebootInterruptionRoutine{
	if status = "FLYING" {
		MSLALogMessage("/!\ MISSION COMPROMISED : CPU reboot during ascent phase. Attempt to save the mission").
		Ascent().
	}
	if status = "SUB_ORBITAL" {
		MSLALogMessage("/!\ MISSION COMPROMISED : CPU reboot during circularisation phase. Attempt to save the mission").
		NodeRemoveAll().
		Circularisation().
	}
	if status = "ESCAPING" {
		MSLALogMessage("/!\ CPU Reboot during escape phase. Mission may be compromised.").
		//Needs to be finished when an "escaping function" is coded.
	}

	else {
		MSLALogMessage("CPU reboot, no danger for mission (vessel landed, splashed, orbiting or docked)").
		Idle().
	}
}

local function instructionsGiven {
	local NDS to list().
	set NDS to allnodes.
	local dvS to 0.
	for nd in NDS {
		set dvS to dvS + nd:burnvector:mag.
	}
	if ship:deltaV:current < dvS {
		UI("The ship can't perform the maneuvers", "Required deltaV : " + round(dvs, 1), "Ship deltaV : " + round(ship:deltav:current, 1), "").
		wait 3.
		Idle().
	}
	until not hasnode {
		for nd in NDS {
			NodeExecute(nd).
		}
	}
	Idle().
}

local function Idle {
	local idl to true.
	unlock throttle. unlock steering.
	set STR to prograde.
	set THR to 0.
	sas on. set sasmode to "radialin".
	local instSent to false.
	if status = "ORBITING" {
		until not idl {
			if not instSent {
				UI("Waiting for flight instructions", "Press [H] to send node maneuvers", "", "").
			}
			if not instSent and ship:control:pilotfore > 0 {
				set instSent to true.
			}
			if hasnode and instSent {
				sas off. lock throttle to THR. lock steering to STR.
				set idl to false.
			}
		wait 1.
		}
		instructionsGiven().
	}
}

