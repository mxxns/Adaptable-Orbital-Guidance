local instSent to false.

global function sMMFR {
    local englist to list().
    local sumMMFR to 0. //Max Mass Flow Rate, summed for all the engines selected
	list engines in englist.
	for eng in englist {
		if eng:isp > 0 { //We select only this stage's engines - they must be activated
			set sumMMFR to sumMMFR + eng:maxmassflow.
  		}
	}
    return sumMMFR.
}

global function sMT {
	local sumMT to 0. //Max Thrust, summed for all the engines selected
	local englist to list().
	list engines in englist.
	for eng in englist {
		if eng:isp > 0 { //We select only this stage's engines - they must be activated
			set sumMT to sumMT + eng:maxthrust.
  		}
	}
    return sumMT.
}

global function sISP {
    return (sMT()/(constant:g0*sMMFR())).
}

global function Ve {
	return sISP()*constant:g0.
}

global function Idle {
	local idl to true.
	set maneuvering to false.
	unlock throttle. unlock steering.
	set STR to prograde.
	set THR to 0.
	sas on. set sasmode to "radialin".
	if status = "ORBITING" {
		until not idl {
			if not instSent {
				UI("Waiting for flight instructions", "Press [H] to send node maneuvers", "", "").
			}
			if not instSent and ship:control:pilotfore > 0 {
				set instSent to true.
			}
			if hasnode and instSent {
				sas off. lock throttle to THR. lock steering to STR. set maneuvering to true.
				set idl to false.
			}
		wait 1.
		}
		instructionsGiven().
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
	set instSent to false.
	Idle().
}

global function NodeExecute{
	parameter Nd.

	local HalfBurnT to (mass/sMMFR())*(1-constant:e^(-Nd:deltaV:mag/(2*Ve()))).
	local burnVS to Nd:burnvector.

	until Nd:eta <= HalfBurnT {
		set STR to Nd:burnvector.
		UI("Nd:eta : " + round(Nd:eta, 2), "burnT/2 : " + round(HalfBurnT, 2), "Angle to node burn vector : ", round(vAng(ship:facing:vector, STR), 1) + "°").
		wait 0.25.
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