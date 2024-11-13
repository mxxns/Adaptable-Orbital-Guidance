global drawList to lexicon().

global function drawVec { //Name, vector, label + optional : colour, scale, width, startVec.
    parameter vname, vV, l, c is RGB(1, 1, 1), s is 1.0, w is 0.2, sV is V(0,0,0).

    if drawList:haskey(vname) {
        set drawList[vname]:vec to vV.
        set drawList[vname]:label to l.
        set drawList[vname]:colour to c.
        set drawList[vname]:scale to s.
        set drawList[vname]:width to w.
        set drawList[vname]:start to sV.
        set drawList[vname]:show to true.
    }
    else drawList:add(vname, vecDraw(sV, vV, c, l, s, true, w)).
}

global function wipeVectors{
    drawList:clear().
    clearVecDraws().
}