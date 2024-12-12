local SBSI to false.
global retroSBV to srfRetrograde.
global pidMinBound to -45. global pidMaxBound to 45. global pidSBK to 1000.
global BrkC to false.

local function suicideBurnSteerInit {
    parameter LandCoord.

    global STRPitchPid to pidLoop(pidSBK, 5, 10, pidMinBound, pidMaxBound).
    set STRPitchPid:setpoint to 0.

    global STRYawPid to pidLoop(pidSBK, 5, 10, pidMinBound, pidMaxBound).
    set STRYawPid:setpoint to 0.

    global lngError to LandCoord:lng-addons:tr:impactpos:lng.
    global latError to LandCoord:lat-addons:tr:impactpos:lat.

    set SBSI to true.
}

local function SBDataUpdate {
    parameter LandCoord.

    if not SBSI suicideBurnSteerInit(LandCoord).

    set lngError to LandCoord:lng-addons:tr:impactpos:lng.
    set latError to LandCoord:lat-addons:tr:impactpos:lat.
}

local function freefallSuicideBurnSteering{
    parameter LandCoord.
    set retroSBV to srfRetrograde.
    if addons:tr:available and addons:tr:hasimpact {
        set pidSBK to 3000. set pidMaxBound to 45. set pidMinBound to -45. set SBSI to false.
        SBDataUpdate(LandCoord).
        if alt:radar < 10 return up:vector.
        else return retroSBV + R(STRPitchPid:update(time:seconds, -latError), STRYawPid:update(time:seconds, -lngError), 0).
    }
    else{
        if DWL MSLALogMission("Trajectories unavailable.").
        return retroSBV.
    }
}

global function suicideBurnSteering { //Steers the rocket during the suicide burn maneuver to land on target.
    parameter LandCoord.
    set retroSBV to srfRetrograde.
    if addons:tr:available and addons:tr:hasimpact { 
        set pidSBK to 1000*g(). set pidMaxBound to 30. set pidMinBound to -30. set SBSI to false.
        SBDataUpdate(LandCoord).
        if velocity:surface:mag < 5 return up:vector.
        else return retroSBV + R(STRPitchPid:update(time:seconds, latError), STRYawPid:update(time:seconds, lngError), 0).
    }
    else{
        if DWL MSLALogMission("Trajectories unavailable.").
        return retroSBV.
    }
}

global function suicideBurn {
    parameter LandCoord.
    parameter DLandingSpeed is -0.5.
    parameter hoveringAlt is 0.

    local THRPid to pidLoop(1+(mass*g())/(maxThrust+0.01), 0, 0, 0, 1).
    set THRPid:setpoint to DLandingSpeed.
    local sBurnT to 0. local distSB to 0. local BND to ship:bounds.

    until BrkC {
        set sBurnT to -(DLandingSpeed - velocity:surface:mag)/(-g()+maxThrust/mass).
        set distSB to hoveringAlt + 0.5*(velocity:surface:mag - DLandingSpeed)*sBurnT.
        if body:atm:exists {
            set THRPid:setpoint to -2*(bnd:bottomaltradar-distSB)/addons:tr:timetillimpact + DLandingSpeed.
            set THR to THRPid:update(time:seconds, verticalSpeed).
            if alt:radar > body:atm:height*0.2 {
                if THR >= 0.81 set STR to suicideBurnSteering(LandCoord).
                else set STR to freefallSuicideBurnSteering(LandCoord).
            }
            else {
                if THR >= 0.51 set STR to suicideBurnSteering(LandCoord).
                else set STR to freefallSuicideBurnSteering(LandCoord).
            } 
        }
        else {
            if bnd:bottomaltradar > distSB {
                set STR to suicideBurnSteering(LandCoord).
                set THR to 0.
                UI("Waiting for suicide burn", "", "DistSB : ", distSB).
            }
            else {
                set STR to suicideBurnSteering(LandCoord).
                set THR to THRPid:update(time:seconds, verticalSpeed).
                UI("Suicide Burn", "", "Time to impact : ", addons:tr:timetillimpact).
            }
        }
        wait 0.01.
    }
    set THR to 0.
}
