global function MSUIInit{
    // startAnimation().
    UI("SYSTEM READY", "", "", "").
    wait 2.
}

local function METClock{ //borrowed from u/Farsyte 
    parameter mT.
    local s to floor(mT).
    local m to floor(s/60). set s to mod(s, 60).
    local h to floor(m/60). set m to mod(m, 60).
    local d to floor(h/24). set h to mod(h, 24).
    local y to floor(d/365). set d to mod(d, 365).
    return y + " y, " + d + " d, " + h + " h, " + m + " m, "+ s + " s.".
}

global function UI{
    parameter msgL1.
	parameter msgL2.
	parameter msgL3.
	parameter param3.
    clearScreen.
    print("___________________________________________").
    print("|                  MoonSys                |").
    print("| Your vehicle is guided to circular orbit|").
    print("|_________________________________________|").
    print(" Running on : ") + ship:name.
    print(" MET : ") + METClock(missiontime).
    print(" CSMET : ") + METClock(missiontime - startT). //shows the time elapsed since last CPU reboot.
    print(" Status : " + status).
    print("                                           ").
    print("                  AVIONICS :").
    print("                                           ").
	print("                  Ship :").
	print("                                           ").
    print(" Velocity : ") + round(velocity:orbit:mag, 1) + (" m/s").
    print(" Altitude : ") + round(altitude) + (" m").
    print("                                           ").
    print(" Stage number : ") + stage:number.
    print(" Stage's deltaV : ") + round(stage:deltav:current, 1).
    print("                                           ").
    print("                   Orbital :                ").
	print("                                           ").
    print(" Periapsis : ") + round(periapsis) + (" m").
    print(" Apoapsis : ") + round(apoapsis) + (" m").
    print("___________________________________________").
	print("                                           ").
    print msgL1.
	print msgL2.
	print msgL3 + param3.
    print("___________________________________________").
    
}


local function startAnimation{
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .'     `.").
    print("              :         :").
    print("              :         :").
    print("              `.       .'").
    print("                `-...-'").
    wait 1/5.
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .'   `::.").
    print("              :       :::").
    print("              :       :::").
    print("              `.     .::'").
    print("                `-..:''").
    wait 1/5.
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .'  ::::.").
    print("              :    ::::::").
    print("              :    ::::::").
    print("              `.   :::::'").
    print("                `-.::''").
    wait 1/5.
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .' .::::.").
    print("              :  ::::::::").
    print("              :  ::::::::").
    print("              `. '::::::'").
    print("                `-.::''").
    wait 1/5.
    clearscreen.
    print("").
    print("").
    print("").
    print("").
    print("                 _..._").
    print("               .:::::::.").
    print("              ::MoonSys::").
    print("              :Interface:").
    print("              `:::::::::'").
    print("                `':::''").
    print("").
    print("Flight data displayed in real time").
    wait 2.
    clearscreen.
}