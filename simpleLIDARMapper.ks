local LIDARInitState to false.

local nP to 8. //Must be 2*n, set n. 2*n+1 doesn't work. Sorry I always mix up odd and even hence the strange explaining.
local initialPixOffset to -10. //Is set to choose if the rover is looking far away or quite close.

local function LIDARInit{
    global pxList to list().
    global servoControl to ship:partstagged("lidarServo")[0]:getmodule("ModuleRoboticRotationServo").
    from{local i is 1.} until i = nP+1 step {set i to i+1.} do {
        pxList:add(ship:partstagged("pix"+i)[0]:getmodule("LaserDistModule")).
    }
    from{local i is 0.} until i = nP step {set i to i+1.} do {
        if (i < nP/2) pxList[i]:setfield("bend x", -initialPixOffset+i).
        else if (i <= nP and i >= nP/2) and pxList[i]:setfield("bend x", initialPixOffset-i+nP/2).
    }
    set LIDARInitState to true.
}

local function LIDARSingleImageMapping{ //Kinda takes a single picture at the desired angle.
    local pic to list().
    pic:add(servoControl:getfield("current angle")).
    from{local i is 0.} until i = nP step {set i to i+1.} do {
        pic:add(pxList[i]:getfield("distance")).
    }
    return pic.
}

local function LIDARScanMappingDoubleSweep{
    if not LIDARInitState LIDARInit().

    local OldAng to 0.
    local fullFovPic to list().
    servoControl:setfield("target angle", 45).
    wait until servoControl:getfield("current angle") >= 45 - 3.

    from{local setAng to -45.} until setAng = 45 step {set setAng to setAng+90.} do {
        servoControl:setfield("target angle", setAng).
        until abs(OldAng-setAng) <= 3 {
            set OldAng to servoControl:getfield("current angle").
            //if not (oldAng = servoControl:getfield("current angle")) fullFovPic:add(LIDARSingleImageMapping()).
            fullFovPic:add(LIDARSingleImageMapping()).
        }
    }
    
    return fullFovPic.
}

local function LIDARStatisticSafestWay {//extremely primal
    local upperMeanDist to 0.
    local tempMeanD to 0.
    local upperSafestDist to 0.
    local upperSafestAngle to 0.

    local fullFovPic to LIDARScanMappingDoubleSweep().

    for ang in fullFovPic {
        set upperMeanDist to upperMeanDist + ang[1].
        set tempMeanD to tempMeanD + 1.

        if ang[1] > upperSafestDist {
            set upperSafestDist to ang[1].
            set upperSafestAngle to ang[0].
        }
    }
    set upperMeanDist to upperMeanDist/tempMeanD.


    print "Safest angle : " + upperSafestAngle.
    print "Farthest dist : " + upperSafestDist.
}

LIDARStatisticSafestWay().



// set oldVal to 0.
// set offset to 0.0001.

// set laserModule to ship:partstagged("frLas")[0]:getmodule("LaserDistModule").
// set counter to time:seconds.

// log "BENDX" + ";" + "DIST" + ";" + ";" to "0:/Logs/mapper.csv".
// from {local width is -15.} until width = 15 step {set width to width+1.} do {
//     laserModule:setfield("bend x", width).
//     set crashKeep to time:seconds.
//     wait until abs(laserModule:getfield("distance") - oldVal) >= offset or time:seconds - crashKeep >= 1.
//     log laserModule:getfield("bend x") + ";" + laserModule:getfield("distance") + ";" to "0:/Logs/mapper.csv".
//     set oldVal to laserModule:getfield("distance").
// }
// set counter to time:seconds - counter.
// log counter to "0:/Logs/mapper.csv".