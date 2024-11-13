local function haversine {
    parameter latD1, latD2, lngD1, lngD2.
    local latR1 to latD1*(constant:pi/180).
    local latR2 to latD2*(constant:pi/180).
    local lngR1 to lngD1*(constant:pi/180).
    local lngR2 to lngD2*(constant:pi/180).
    return 2*body:radius*arcsin(sqrt(0.5*(1-cos(latR2-latR1)+cos(latR1)*cos(latR2)*(1-cos(lngR2-lngR1))))).
}

local BBPid to pidLoop(100, 1, 0, -10, 10).
set BBPid:setpoint to 0.
local latBBError to 0.

local function boostBackSteering {
    parameter LandCoord.
    set latBBError to LandCoord:lat - addons:tr:impactpos:lat.
    if vAng(prograde:vector, LandCoord:position) < 90 {
        return R(-BBPid:update(time:seconds, latBBError), 0, 0).
    }
    else return R(-BBPid:update(time:seconds, latBBError), 0, 0).//touche plus
}

local function lngOvershootDetection {
    parameter LandCoord. parameter dir.

    if dir {
        if addons:tr:impactpos:lng > LandCoord:lng return false.
        else return true.
    }
    else{
        if addons:tr:impactpos:lng < LandCoord:lng return false.
        else return true.
    }
}

global function boostBack {
    parameter LandCoord.

    local retroBBV to retrograde.

    if vAng(prograde:vector, LandCoord:position) > 90 {
        set retroBBV to vXcl(up:vector, LandCoord:position).
    }
    else set retroBBV to vXcl(up:vector, -LandCoord:position).

    until abs(vAng(retroBBV, ship:facing:forevector)) < 0.1 {
        set STR to retroBBV.
        wait 0.2.
    }

    if addons:tr:available until addons:tr:hasimpact {
        set STR to retroBBV.
        until abs(vAng(retroBBV, ship:facing:forevector)) < 1{
            clearscreen.
            print abs(vAng(retroBBV, ship:facing:forevector)).
            set THR to 0.
            wait 0.1.
        }
        set THR to 1.
        wait 0.1.
    }
    
    local hav to haversine(LandCoord:lat, addons:tr:impactpos:lat, LandCoord:lng, addons:tr:impactpos:lng).
    local havMin to hav.
    local BrC to false.
    if addons:tr:available and addons:tr:hasimpact {
        if addons:tr:impactpos:lng < LandCoord:lng local lngOvershootDirection to false.
        else local lngOvershootDirection to true.  //True means impact:pos:lng > LandCoord:lng
    
        until BrC or lngOvershootDetection(LandCoord, lngOvershootDirection) {
            set STR to retroBBV + boostBackSteering(LandCoord).
            if hav <= havMin set havMin to hav.
            else if hav > havMin and havMin < 300 set BrC to true.
            set hav to haversine(LandCoord:lat, addons:tr:impactpos:lat, LandCoord:lng, addons:tr:impactpos:lng).
            set THR to (1/10000)*hav.
            wait 0.1.
        }
    }      
    set THR to 0.
}