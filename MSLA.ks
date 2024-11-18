global function MSLAInit {
    global logI to true.
    local trackTime to round(missionTime, 2).
    // startAnimation().
    print("Logging Algorithm Initialisation").
    MSLALogMessage("System Initialisation").
    print("Event file initialized.").
    log "MET; ALT; LAT; LONG; VELOCITY; ACC; MASS;" to "0:/Logs/mission " + ship:name + "/data.csv".
    print("CSV Data Format : MET; ALT; LAT; LONG; VELOCITY; ACC; MASS;").
    print("Starting to log in csv file").
    when logI and round(missionTime, 2) - trackTime > 0.1 then {
        MSLACSVNode().
        set trackTime to round(missionTime, 2).
        preserve.
    }
}

global function MSLALogMessage{
    parameter message.
log timestamp(missionTime):clock + " - " + message + ", " + status to "0:/Logs/mission " + ship:name + "/events" + ".txt".
}

global function MSLACSVNode {
    log round(missionTime, 2) + ";" + altitude + ";" + latitude + ";" + longitude + ";" + velocity:surface:mag + ";" + ship:thrust/mass + ";" + mass + ";" to "0:/Logs/mission " + ship:name + "/data.csv".
}

local function startAnimation{
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .:::::::.").
    print("              :::::::::::").
    print("              :::::::::::").
    print("              `:::::::::'").
    print("                `':::''").
    wait 1/5.
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .::::. `.").
    print("              :::::::.  :").
    print("              ::::::::  :").
    print("              `::::::' .'").
    print("                `'::'-'").
    wait 1/5.
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .::::  `.").
    print("              ::::::    :").
    print("              ::::::    :").
    print("              `:::::   .'").
    print("                `'::.-'").
    wait 1/5.
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .::'   `.").
    print("              :::       :").
    print("              :::       :").
    print("              `::.     .'").
    print("                `':..-'").
    wait 1/5.
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .'     `.").
    print("              : MoonSys :").
    print("              : LogAlgo :").
    print("              `.       .'").
    print("                `-...-'").
    print("").
    print("Your flight data is being saved").
    wait 2.
    clearscreen.
}