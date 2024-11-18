clearscreen.
set oldVal to 0.
set offset to 0.0001.

set laserModule to ship:partstagged("frLas")[0]:getmodule("LaserDistModule").
set counter to time:seconds.

log "BENDX" + ";" + "DIST" + ";" + ";" to "0:/Logs/mapper.csv".
from {local width is -15.} until width = 15 step {set width to width+1.} do {
    laserModule:setfield("bend x", width).
    set crashKeep to time:seconds.
    wait until abs(laserModule:getfield("distance") - oldVal) >= offset or time:seconds - crashKeep >= 1.
    log laserModule:getfield("bend x") + ";" + laserModule:getfield("distance") + ";" to "0:/Logs/mapper.csv".
    set oldVal to laserModule:getfield("distance").
}
set counter to time:seconds - counter.
log counter to "0:/Logs/mapper.csv".