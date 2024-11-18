function sign {
    parameter x.
    if x < 0 {
        return -1.
    } else {
        return 1.
    }
}
 
function tradmod {
    parameter x, y.
    return x - y * floor(x / y).
}
 
set KSCLaunchPad to LATLNG(-0.0972098829757138, -74.557676687929).

set launchPosition to KSCLaunchPad:position. // landing target location, TODO rename this
// set chopstickPos to ship:partstagged("chopsticks")[0]:position.
set neutralVec to -launchPosition - (vdot(-launchPosition, ship:up:vector) * ship:up:vector).
 
set targetAltitude to 75000.   // Target apoapsis for orbit.
 
lock steering to heading(90, 90). // Point straight up initially.
lock throttle to 1.               // Full throttle for launch.


stage.  // Activate the first stage.
 
// Main ascent loop.
print "Starting gravity turn.".
until apoapsis >= targetAltitude {
    // equation that gives pitch based on altitude: y=10.73485+(89.75962-10.73485)/(1+(x/11504.65))
    set pitch to 10.73485+(89.75962-10.73485)/(1+(ALTITUDE/11504.65)).
 
    // make sure we can never pitch down
    if pitch < 0 {
        set pitch to 0.
    }
    lock steering to heading(90, pitch).
    wait 0.04.
}
 
lock throttle to 0.3. // throttle down for separation
wait 1.
 
// Stage separation and booster control.
stage.  // Stage separation.
print "Hotstaging.".
 
// Activate RCS for the booster turn.
wait 0.5.
rcs on.
print "Reaction control systems online.".
 
print "Turnaround for boostback burn.".
lock steering to heading(90, -60).  // start to turn retrograde for
wait 2.
 
// gradual change of heading to make the flip direction more predictable
lock throttle to 0.2.
wait 1.5.
lock steering to heading(90, -89).
wait 1.
lock steering to heading(270, -45).
wait 1.
lock steering to heading(270, 0).
wait 2.
 
print "Booster turnaround complete.".
wait until vang(ship:facing:forevector, heading(270, 0):forevector) < 30.  // Wait until properly aligned.

// set boostbackOffset to 0.015. // (working value: 0.015)
 
// Perform boostback burn with dynamic adjustment to minimize perpendicular velocity.
print "Boostback burn initiated.".
lock throttle to 1.
if addons:tr:available {
    addons:tr:settarget(KSCLaunchPad).  // Set the launch location as the target.
    until addons:tr:hasimpact and (addons:tr:impactpos:lng < KSCLaunchPad:lng){ // + boostbackOffset) {
 
        // boostback burn control loop

        if addons:tr:hasimpact {
            set targetBearing to KSCLaunchPad:heading.
            set horizontalVelocityVec to ship:velocity:surface - (ship:verticalspeed * ship:up:vector).
            set toTargetVector to (KSCLaunchPad:position - ship:position):normalized. // Vector pointing from the ship to the target
 
            set sidewaysDirVector to vcrs(toTargetVector, ship:up:vector):normalized.
            set sidewaysVelocity to vdot(horizontalVelocityVec, sidewaysDirVector).
 
            // Use sidewaysVelocity to adjust the heading
            set Kp to 0.2.
            set headingCorrection to sidewaysVelocity * Kp.
 
            // Limit the correction angle
            set maxCorrectionAngle to 10.
            if abs(headingCorrection) > maxCorrectionAngle {
                set headingCorrection to maxCorrectionAngle * sign(headingCorrection).
            }
 
            // Adjust throttle for finer control as we approach the target impact point
            set impactLongitudeError to abs(addons:tr:impactpos:lng - KSCLaunchPad:lng).
            if impactLongitudeError < 0.15 {
                set headingCorrection to (KSCLaunchPad:lat - addons:tr:impactpos:lat) * 100 .//+ sidewaysVelocity * Kp.
                lock throttle to 0.4. // throttle down for final adjustment
            } else if impactLongitudeError < 0.6 {
                set headingCorrection to (KSCLaunchPad:lat - addons:tr:impactpos:lat) * 100 .//+ sidewaysVelocity * Kp.
            }
 
            // Adjust the desired heading, normalizing it to 0-360
            set desiredHeading to tradmod(targetBearing + headingCorrection, 360).
            lock steering to heading(desiredHeading, 0).
        }
        wait 0.05.
    }
    set ship:control:pilotmainthrottle to 0.
    print "Boostback burn complete.".
} else {
    print "Trajectories mod not available. Cannot perform boostback.".
}
 
lock throttle to 0.
brakes on. // toggle grid fins
 
print "Starting entry reorientation.".
 
set initialFacing to ship:facing. // initial facing after boostback burn
set targetYaw to tradmod(ship:facing:yaw + 180, 360).
 
// slow precise reorientation for entry
print "WATCH".
wait 2.
until (ship:facing:yaw > targetYaw - 15 and ship:facing:yaw < targetYaw + 10) {
    lock steering to R(initialFacing:pitch, ship:facing:yaw + 20, initialFacing:roll).
}
lock steering to retrograde.
print "Reorientation for entry complete.".
 
set targetAltitude to 1. // (working value: 300)
set targetSpeed to 50.
set landingBurnMultiplier to 0.9. // planned throttle level (working value: 0.9)
 
lock distanceLeft to max(1, ship:bounds:bottomaltradar - targetAltitude). // distance left to target altitude
lock slowDownLeft to ship:verticalspeed + targetSpeed. // vertical speed left to slow down to target speed
lock deceleration to landingBurnMultiplier * ship:availablethrust / ship:mass. // planned deceleration (m/s^2)
lock stopDistance to (slowDownLeft * slowDownLeft) / (2 * deceleration). // distance needed to stop with planned deceleration
set gAcc to constant:g * body:mass / body:radius^2.
 
// Descent loops with GUI updates
if addons:tr:available {
 
    print "Waiting for landing burn conditions to be met.".
    // First loop: wait until landing burn conditions are met
    until (stopDistance > distanceLeft) {
        wait 0.02.
    }
 
    lock steering to addons:tr:plannedvec.
    lock toTargetVector to addons:tr:gettarget:position - addons:tr:impactpos:position.
 
    // Second loop: stage of the large positional corrections and most of the deceleration
    print "Landing burn startup.".
    set steeringStrength to 0.
    until (-ship:verticalspeed < targetSpeed + 3) {
 
        if steeringStrength < 0.0025 {
            set steeringStrength to steeringStrength + 0.00005. // increases to full strength over 1 second
        }
 
        if (-ship:verticalspeed > targetSpeed + 50) {
            lock steering to addons:tr:plannedvec + steeringStrength * toTargetVector.
        } else {    
            lock steering to R(ship:up:pitch, ship:up:yaw, -90).
        }
 
        // adjust throttle for planned deceleration
        set necessaryDeceleration to gAcc - (targetSpeed*targetSpeed - ship:verticalspeed*ship:verticalspeed)/(2 * distanceLeft).
        set necessaryThrust to necessaryDeceleration * SHIP:MASS.
        lock throttle to necessaryThrust / ship:availablethrust.
 
        wait 0.02.
    }
 
    // Third loop: final descent phase
    set stationaryCounter to 0.
    set finalDescent to false.
    set steeringStrength to 0.005.
    set targetTWR to 1.0.
    until (stationaryCounter > 20) {
        if addons:tr:hasimpact {
 
            set horizontalVelocityVec to ship:velocity:surface - (ship:verticalspeed * ship:up:vector).
            set steeringVector to ship:up:vector + steeringStrength * toTargetVector.
            set steeringVectorDir to steeringVector:direction.
 
            set thrustAngleMultiplier to 1 / (steeringVector:normalized * ship:up:vector).
 
            if (ship:bounds:bottomaltradar > 43 and ship:bounds:bottomaltradar < 120) {
                set activeLoc to latlng(ship:geoposition:lat, ship:geoposition:lng):position.
                set directedVec to - activeLoc - (vdot(- activeLoc, ship:up:vector) * ship:up:vector).
                set directionSign to sign(vdot(vcrs(neutralVec, directedVec), ship:up:vector)).
                set movingAngle to vang(neutralVec, directedVec).
 
                // vessel("Mechazilla"):connection:sendmessage(directionSign * movingAngle).
            }
 
            // original steering strength: 0.003
            if (-ship:verticalspeed > 15) { // if we're still going too fast at the start of the final descent
                set targetTWR to 2.0.
                set steeringStrength to 0.003.
            } else if (ship:bounds:bottomaltradar > 100) { // move towards chopsticks with a constant velocity
                set targetTWR to 1.0.
                set steeringStrength to 0.005.
 
                if (not finalDescent) {
                    toggle ag5. // switch to 3 engine mode
                    set finalDescent to true.
                    print "Cut back to 3 engines.".
                }
            } else if (-ship:verticalspeed > 4) { // slow down towards the second phase, arriving at the chopsticks (slower, but not final descent)
                set targetTWR to 2.0.
                set steeringStrength to 0.005.
                //set KSCLaunchPad to originalKSCLaunchPad.
            } else if (ship:bounds:bottomaltradar > 46) { // second phase, slow descent into the chopsticks almost until the end
                set targetTWR to 1.0.
                set steeringStrength to 0.005.
 
                set steeringVector to ship:up:vector - (0.03 * horizontalVelocityVec).
                set steeringVectorDir to steeringVector:direction.
            } else if (-ship:verticalspeed > 1.1) {
                set targetTWR to 1.5.
                set steeringStrength to 0.005.
            } else if (-ship:verticalspeed < 0.8) {
                set targetTWR to 0.75.
                set steeringStrength to 0.005.
            } else { // third and final phase, slow descent into the chopsticks
                set targetTWR to 1.0.
                set steeringStrength to 0.003.
 
                set steeringVector to ship:up:vector - (0.03 * horizontalVelocityVec).
                set steeringVectorDir to steeringVector:direction.
            }
 
            lock steering to R(steeringVectorDir:pitch, steeringVectorDir:yaw, -90).
            lock throttle to targetTWR * thrustAngleMultiplier * ship:mass / (ship:availablethrust / 9.80665)..
 
            // Update GUI
            UpdateAllGUI().
        }
 
        if (ship:status = "LANDED" and ship:bounds:bottomaltradar < 42.5) {
            set stationaryCounter to stationaryCounter + 1.
        } else {
            set stationaryCounter to 0.
        }
        wait 0.02.
    }
 
    set ship:control:pilotmainthrottle to 0.
    print "landing successful.".
}