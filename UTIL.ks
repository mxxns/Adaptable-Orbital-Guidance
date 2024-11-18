global KSCLaunchPad is LATLNG(-0.0972098829757138, -74.557676687929).

local antennaD to false.
global fairingD to false.
local solarD to false.
if stage:number = 0 global stageable to false.
else global stageable to true.
local boostersJettisoned to false.
global maneuvering to true.

global function g {
    return body:mu/(altitude + body:radius)^2.
}

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

global function reusableBoosterSeparation {
	return "To be written".
}

global function boosterJettisonInterruptRoutine{ //Activates when the boosters are to be thrown
	for booster in findBoosters(){
		when booster:flameout then {
			if not boostersJettisoned { //This variable is changed when they'll be jettisoned, so the CPU doesn't stage for no reason
				UI("Boosters jettison", "", "", "").
				if DWL MSLALogMessage("Boosters jettison").
				stage.
			}
			set boostersJettisoned to true.
			if not boostersJettisoned preserve.
		}
	}
}

global function stagingInterruptionRoutine{ //Activates when the whole stage is to be thrown
	when STAGE:DELTAV:VACUUM <= 0 and stageable then {
		UI("Staging", "", "", "").
		if DWL MSLALogMessage("Staging").

		//Saving throttle state right before staging and stopping throttle
		local sTHR to THROTTLE.
		set THR to 0.

		if maneuvering stage.

		//Reset throttle to its previous value before staging
		set THR to sTHR.

		//We want the loop to run only if the vessel is stageable (= not the last stage) to save energy.
		if stage:number = 0 set stageable to false.
		if stageable preserve.
	}
}

global function antennaDeploy{ //inspired by space_is_hard 's work (github)
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

global function fairingDeploy {
	if not fairingD {
		//Finding fairing
		if altitude > 0.95*body:atm:height {
			// local fairList to list().
			// for fair in ship:modulesnamed("ModuleProceduralFairing") {
			// 	fairList:add(fair:part).
			// }
			// fairList[0]:getmodule("ModuleProceduralFairing"):doevent("deploy").
			for fair in ship:modulesnamed("ModuleProceduralFairing") {
				fair:doevent("deploy").
			}
			set fairingD to true.
		}
	}
}

global function solarDeploy {
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

local function gearDeploy {
	if alt:radar < 100 gear on.
	else gear off.
}

local function rcsAcc {
	if alt:radar > 0.60*body:atm:height rcs on.
	else rcs off.
}

global function utilitiesRoutine{
	when 1=1 then {
		if not fairingD {fairingDeploy().}
		if status = "SUB_ORBITAL" or status = "FLYING" {
			antennaDeploy().
			solarDeploy().
			gearDeploy().
			rcsAcc().
		}
		preserve.
	}
}

global function NodeRemoveAll {
	local NDS to list().
		set NDS to allnodes.
		for nd in NDS {
			remove nd.
		}
}

global function rebootInterruptionRoutine{
	if status = "FLYING" {
		if DWL MSLALogMessage("/!\ MISSION COMPROMISED : CPU reboot during ascent phase. Attempt to save the mission").
		AscentBurn().
	}
	if status = "SUB_ORBITAL" {
		if DWL MSLALogMessage("/!\ MISSION COMPROMISED : CPU reboot during circularisation phase. Attempt to save the mission").
		NodeRemoveAll().
		Circularisation().
	}
	if status = "ESCAPING" { //Escaping orbit means you are in a transfer to another body and/or simply leaving Earth's SOI
		if DWL MSLALogMessage("/!\ CPU Reboot during escape phase. Mission may be compromised.").
		Idle().
	}

	else {
		if DWL MSLALogMessage("CPU reboot during vessel status : landed, splashed, orbiting or docked. ").
		if hasnode {if DWL MSLALogMessage("/!\ Vehicle had nodes active after a reboot, may have compromised mission.").}
		Idle().
	}
}