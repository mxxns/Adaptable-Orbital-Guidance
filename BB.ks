local function haversine {
    parameter latD1, latD2, lngD1, lngD2.
    local latR1 to latD1*(constant:pi/180).
    local latR2 to latD2*(constant:pi/180).
    local lngR1 to lngD1*(constant:pi/180).
    local lngR2 to lngD2*(constant:pi/180).
    return 2*body:radius*arcsin(sqrt(0.5*(1-cos(latR2-latR1)+cos(latR1)*cos(latR2)*(1-cos(lngR2-lngR1))))).
}


local function boostBackSteering {
    parameter LandCoord.

    local BBPid to pidLoop(100, 1, 0, -10, 10).
    set BBPid:setpoint to 0.

    local latBBError to LandCoord:lat - addons:tr:impactpos:lat.
    if vAng(prograde:vector, LandCoord:position) < 90 {
        return R(-BBPid:update(time:seconds, latBBError), 0, 0).
    }
    else return R(BBPid:update(time:seconds, latBBError), 0, 0).
}

global function boostBack {
    parameter LandCoord.

    local LandOffset to offsetCoord(LandCoord).
    local retroBBV to retrograde.

    if vAng(prograde:vector, LandCoord:position) > 90 {
        set retroBBV to vXcl(up:vector, LandCoord:position).
    }
    else set retroBBV to vXcl(up:vector, -LandCoord:position).

    if addons:tr:available until addons:tr:hasimpact {
        set STR to retroBBV.
        wait until vAng(retroBBV, ship:facing:vector) < 10.
        set THR to 1.
        wait 0.1.
    }
    
    local hav to haversine(LandCoord:lat, addons:tr:impactpos:lat, LandCoord:lng, addons:tr:impactpos:lng).
    local havMin to hav.
    local BrC to false.
    if addons:tr:available and addons:tr:hasimpact until BrC {
        set LandOffset to offsetCoord(LandCoord).
        set STR to retroBBV + boostBackSteering(LandOffset).
        if hav <= havMin set havMin to hav.
        else if hav > havMin and havMin < 300 set BrC to true.
        set hav to haversine(LandOffset:lat, addons:tr:impactpos:lat, LandOffset:lng, addons:tr:impactpos:lng).
        set THR to (1/10000)*hav.
        wait 0.1.
    }
    set THR to 0.
}