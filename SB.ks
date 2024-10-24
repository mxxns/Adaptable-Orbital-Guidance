local SBSI to false.
global retroSBV to srfRetrograde.
global pidMinBound to -45. global pidMaxBound to 45. global pidSBK to 1000.

local function lngOffset{
    parameter LandCoord.

    local X to 10*10*tan((constant:pi/180)*vAng(-up:vector, velocityAt(ship, addons:tr:timetillimpact):surface)).
    clearscreen. print X.
    return (180/constant:pi)*(X/(body:radius*cos(constant:pi*LandCoord:lat/180))).
}

global function offsetCoord{
    parameter LandCoord.

    if addons:tr:available return latlng(LandCoord:lat, LandCoord:lng - lngOffset(LandCoord)).
    else return latlng(LandCoord:lat, LandCoord:lng).
}

local function suicideBurnSteerInit {
    parameter LandCoord.

    global STRPitchPid to pidLoop(pidSBK, 0.01, 0, pidMinBound, pidMaxBound).
    set STRPitchPid:setpoint to 0.

    global STRYawPid to pidLoop(pidSBK, 0.01, 0, pidMinBound, pidMaxBound).
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
        set pidSBK to 2000. set pidMaxBound to 45. set pidMinBound to -45. set SBSI to false.
        SBDataUpdate(LandCoord).
        if velocity:surface:mag < 5 return up:vector.
        else return retroSBV + R(STRPitchPid:update(time:seconds, -latError), STRYawPid:update(time:seconds, -lngError), 0).
    }
    else{
        // MSLALogMission("Trajectories unavailable.").
        return retroSBV.
    }
}

global function suicideBurnSteering { //Steers the rocket during the suicide burn maneuver to land on target.
    parameter LandCoord.
    set retroSBV to srfRetrograde.
    if addons:tr:available and addons:tr:hasimpact { 
        set pidSBK to 3000. set pidMaxBound to 20. set pidMinBound to -20. set SBSI to false.
        SBDataUpdate(LandCoord).
        if velocity:surface:mag < 5 return up:vector.
        else return retroSBV + R(STRPitchPid:update(time:seconds, latError), STRYawPid:update(time:seconds, lngError), 0).
    }
    else{
        // MSLALogMission("Trajectories unavailable.").
        return retroSBV.
    }
}

global function suicideBurn {
    parameter LandCoord.
    local LandOffset to offsetCoord(LandCoord).

    local DLandingSpeed to -0.5.

    local THRPid to pidLoop(0.1, 0.01, 0, 0, 1).
    set THRPid:setpoint to DLandingSpeed.
    local sBurnT to 0. local distSB to 0. local BND to ship:bounds.

    until status = "LANDED" {
        set LandOffset to offsetCoord(LandCoord).
        set sBurnT to -(DLandingSpeed - velocity:surface:mag)/(-g()+maxThrust/mass).
        set distSB to 0.5*(velocity:surface:mag - DLandingSpeed)*sBurnT.
        set THRPid:setpoint to -2*(bnd:bottomaltradar-distSB)/addons:tr:timetillimpact + DLandingSpeed.
        set THR to THRPid:update(time:seconds, verticalspeed).
        if THR >= 0.51 set STR to suicideBurnSteering(LandOffset).
        else set STR to freefallSuicideBurnSteering(LandOffset).
        wait 0.1.
    }
    set THR to 0.
}