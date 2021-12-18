//====================================================================================================
// NinjaTracker V2.04 gamemusic playroutine - Definitions and utility macros
//====================================================================================================

#importonce

//----------------------------------------------------------------------------------------------------
// Song table
//----------------------------------------------------------------------------------------------------

.struct nt_entry { 
    left, 
    right 
}

.struct nt_table {
    items,
    labels,
    refs
}

.function tableNew() {
    .return nt_table(List(), Hashtable(), Hashtable())
}

.function tableAdd(t, item) {
    .eval t.items.add(item)
}

.function tableSetPos(t, name) { 
    .if (t.labels.containsKey(name)) {
        .eval error("Table position '" + name + "' already defined")
    }
    .eval t.labels.put(name, 1 + t.items.size())
} 

.function tableGetPos(t, name) { 
    .var pos = t.labels.get(name) 
    .if (pos == null) {
        .eval error("Table position '" + name + "' not defined") 
    }
    .return pos
}

.function tableRef(t, name) {
    .var pos = t.items.size() + 1
    .eval t.refs.put(pos, name)
    .eval t.items.add(nt_entry($ff, $00))
}

.function tableFixRefs(t) { 
    .var posRefs = t.refs.keys() 
    .for (var i=0; i<posRefs.size(); i++) {
        .var pos = posRefs.get(i).asNumber()
        .var name = t.refs.get(pos)
        .var refPos = tableGetPos(t, name)
        .eval t.items.get(pos-1).right = refPos 
    }
} 

//----------------------------------------------------------------------------------------------------
// Song book
//----------------------------------------------------------------------------------------------------

.struct nt_songbook {
    wave,
    pulse,
    filter,
    commands,
    patterns,
    songs
}

.function songBookCreate() {
    .return nt_songbook(
        tableNew(), 
        tableNew(), 
        tableNew(), 
        tableNew(),
        tableNew(),
        List()
    )
}

.function songBookEnd(sb) {
    .eval tableFixRefs(sb.wave)
    .eval tableFixRefs(sb.pulse)
    .eval tableFixRefs(sb.filter)
    .for (var i=0; i<sb.songs.size(); i++) {
        .eval songFixRefs(sb.songs.get(i))
    }
}

.function songFixRefs(s) { 
    .var posRefs = s.refs.keys() 
    .for (var i=0; i<posRefs.size(); i++) {
        .var pos = posRefs.get(i).asNumber()
        .var name = s.refs.get(pos)
        .var refPos = tableGetPos(s, name)
        .eval s.items.set(pos, refPos) 
    }
} 

.macro songBookDump(sb) {
    .var startAddr = *
    .var waveSize = sb.wave.items.size()
    .var pulseSize = sb.pulse.items.size()
    .var filterSize = sb.filter.items.size()
    .var commandsSize = sb.commands.items.size()
    .var patternsSize = sb.patterns.items.size()
    .var songsSize = sb.songs.size()
    .var legatoCommands = 0
    .for (var i=0; i<sb.commands.items.size(); i++) {
        .var cmd = sb.commands.items.get(i)
        .if (sb.commands.refs.containsKey(cmd.name)) {
            .eval legatoCommands = 0
        } else {
            .eval legatoCommands++
        }
    }
    .byte waveSize, pulseSize, filterSize, commandsSize-legatoCommands, commandsSize, patternsSize
    .fill waveSize, sb.wave.items.get(i).left
    .fill waveSize, sb.wave.items.get(i).right
    .fill pulseSize, sb.pulse.items.get(i).left
    .fill pulseSize, sb.pulse.items.get(i).right
    .fill filterSize, sb.filter.items.get(i).left
    .fill filterSize, sb.filter.items.get(i).right
    .fill commandsSize - legatoCommands, (sb.commands.items.get(i).adsr >> 8)
    .fill commandsSize - legatoCommands, (sb.commands.items.get(i).adsr >> 0) 
    .fill commandsSize, sb.commands.items.get(i).wave
    .fill commandsSize, sb.commands.items.get(i).pulse
    .fill commandsSize, sb.commands.items.get(i).filter
    
    .var patternAddr = * + (2 * patternsSize) + (5 * songsSize)
    .var patternAddrTable = List()
    .for (var i=0; i<patternsSize; i++) {
        .eval patternAddrTable.add(patternAddr)
        .eval patternAddr += sb.patterns.items.get(i).size()
    }    
    
    .fill patternsSize, <patternAddrTable.get(i)
    .fill patternsSize, >patternAddrTable.get(i)
    
    .var songAddr = patternAddr
    .for (var i=0; i<songsSize; i++) {
        .var song = sb.songs.get(i)
        .word songAddr
        .byte song.start1 == -1 ? error("Track 1 unset for song " + i) : song.start1
        .byte song.start2 == -1 ? error("Track 2 unset for song " + i) : song.start2
        .byte song.start3 == -1 ? error("Track 3 unset for song " + i) : song.start3
        .eval songAddr += song.items.size()
    }    

    .for (var i=0; i<patternsSize; i++) {
        .var pattern = sb.patterns.items.get(i)
        .fill pattern.size(), pattern.get(i)
    }
    
    .for (var i=0; i<songsSize; i++) {
        .var song = sb.songs.get(i)
        .fill song.items.size(), song.items.get(i)
    }
}

//----------------------------------------------------------------------------------------------------
// Wave table
//----------------------------------------------------------------------------------------------------

.function waveRaw(sb, left, right) {
    .eval tableAdd(sb.wave, nt_entry(left, right))
}

.function waveArpeggio(arpeggioStr) {
    .var first = arpeggioStr.charAt(0);
    .if (first == '-' || first == '+') {
        .var arpeggio = arpeggioStr.asNumber()
        .if (arpeggio < -64 || arpeggio > 63) {
            .eval error("Invalid relative arpeggio value" + arpeggioStr) 
        }
        .return arpeggio >= 0 ? arpeggio : arpeggio + $80
    } else {
        .return getNote(arpeggioStr) + $8c;
    }
}

.function wavePos(sb, name) {
    .eval tableSetPos(sb.wave, name)
}

.function waveSet(sb, value) {
    .eval waveSet(sb, value, "+0")
}

.function waveSet(sb, value, arpeggio) {
    .if (value < 0 || value > $8f) {
        .eval error("Invalid value " + value)
    }
    .eval waveRaw(sb, value, waveArpeggio(arpeggio))
}

.function waveDelay(sb, delay) {
    .return waveDelay(sb, delay, "+0")
}

.function waveDelay(sb, delay, arpeggio) {
    .eval checkRange(delay, 0, $2f, "Invalid delay " + delay)
    .return waveRaw(sb, $90 + delay, waveArpeggio(arpeggio))
}

.function waveVibrato(sb, speed, depth) {
    .eval checkRange(speed, 0, $1f, "Invalid vibrato speed " + speed)
    .eval checkRange(depth, 0, $ff, "Invalid vibrato depth " + depth)
    .return waveRaw(sb, $c0 + speed, depth)
}

.function waveSlide(sb, speed) {
    .eval checkRange(speed, 0, $1eff, "Invalid slide speed " + speed)
    .var hi = (speed >> 8) & $ff
    .var lo = (speed >> 0) & $ff
    .return waveRaw(sb, $e0 + hi, lo)
}

.function waveJump(sb, name) {
    .return tableRef(sb.wave, name)
}

.function waveStop(sb) {
    .return waveRaw(sb, $ff, $00)
}

.function waveTableAdd(sb, entries) {
    .for (var i=0; i<entries.size(); i++) {
        .eval waveTableAddEntry(sb, entries.get(i))
    }
}

.function waveTableAddEntry(sb, entry) {
    .var items = tokenize(entry)
    .var size = items.size()
    .eval checkNotEquals(size, 0, "Empty wave entry") 
    
    .var cmd = items.get(0).toLowerCase()
    .if (cmd == "end") {
        .eval checkEquals(size, 1, "Invalid wave end entry " + entry)
        .return waveStop(sb)
    }
    .if (cmd == "jmp") {
        .eval checkEquals(size, 2, "Invalid wave jump entry " + entry)
        .return waveJump(sb, items.get(1))
    }
    .if (cmd == "sli") {
        .eval checkEquals(size, 2, "Invalid wave slide entry " + entry)
        .return waveSlide(sb, parseNum(items.get(1)))
    }
    .if (cmd == "vib") {
        .eval checkEquals(size, 3, "Invalid wave vibrato entry " + entry)
        .return waveVibrato(sb, parseNum(items.get(1)), parseNum(items.get(2)))
    }
    .if (cmd == "del") {
        .if (size == 2) {
            .return waveDelay(sb, parseNum(items.get(1)))
        }
        .if (size == 3) {
            .return waveDelay(sb, parseNum(items.get(1)), items.get(2))
        }
        .eval error("Invalid wave delay entry " + entry)
    }
    .if (cmd == "set") {
        .if (size == 2) {
            .return waveSet(sb, parseNum(items.get(1)))
        }
        .if (size == 3) {
            .return waveSet(sb, parseNum(items.get(1)), items.get(2))
        }
        .eval error("Invalid wave set entry " + entry)
    }
    
    .var cmdLen = cmd.size()
    .if (cmd.charAt(cmdLen-1) == ':' && cmdLen >= 2) {
        .return wavePos(sb, cmd.substring(0, cmdLen-1))
    }

    .eval error("Invalid wave entry " + entry) 
}

//----------------------------------------------------------------------------------------------------
// Pulse table
//----------------------------------------------------------------------------------------------------

.function pulseRaw(sb, left, right) {
    .eval tableAdd(sb.pulse, nt_entry(left, right))
}

.function pulsePos(sb, name) {
    .eval tableSetPos(sb.pulse, name)
}

.function pulseSet(sb, width) {
    .eval checkRange(width, 0, $ff, "Invalid pulse width " + width)
    .eval pulseRaw(sb, $80, width)
}

.function pulseModulate(sb, time, speed) {
    .eval checkRange(time, 1, $7f, "Invalid modulation time " + time)
    .eval checkRange(speed, -128, 127, "Invalid modulation speed " + speed)
    .eval pulseRaw(sb, time, speed & $ff)
}

.function pulseJump(sb, name) {
    .eval tableRef(sb.pulse, name)
}

.function pulseStop(sb) {
    .eval pulseRaw(sb, $ff, $00)
}

.function pulseTableAdd(sb, entries) {
    .for (var i=0; i<entries.size(); i++) {
        .eval pulseTableAddEntry(sb, entries.get(i))
    }
}

.function pulseTableAddEntry(sb, entry) {
    .var items = tokenize(entry)
    .var size = items.size()
    .eval checkNotEquals(size, 0, "Empty pulse entry") 
    
    .var cmd = items.get(0).toLowerCase()
    .if (cmd == "end") {
        .eval checkEquals(size, 1, "Invalid pulse end entry " + entry)
        .return pulseStop(sb)
    }
    .if (cmd == "jmp") {
        .eval checkEquals(size, 2, "Invalid pulse jump entry " + entry)
        .return pulseJump(sb, items.get(1))
    }
    .if (cmd == "mod") {
        .eval checkEquals(size, 3, "Invalid pulse modulate entry " + entry)
        .return pulseModulate(sb, parseNum(items.get(1)), parseNum(items.get(2)))
    }
    .if (cmd == "set") {
        .eval checkEquals(size, 2, "Invalid pulse set entry " + entry)
        .return pulseSet(sb, parseNum(items.get(1)))
    }
    .var cmdLen = cmd.size()
    .if (cmd.charAt(cmdLen-1) == ':' && cmdLen >= 2) {
        .return pulsePos(sb, cmd.substring(0, cmdLen-1))
    }

    .eval error("Invalid pulse entry " + entry) 
}

//----------------------------------------------------------------------------------------------------
// Filter table
//----------------------------------------------------------------------------------------------------

.function filterRaw(sb, left, right) {
    .eval tableAdd(sb.filter, nt_entry(left, right))
}

.function filterPos(sb, name) {
    .eval tableSetPos(sb.filter, name)
}

.function filterSet(sb, mode, channels, cutoff) {                              
    .eval checkRange(mode, $0, $f, "Invalid filter mode " + mode)
    .eval checkRange(channels, $0, $f, "Invalid filter channels " + channels)
    .eval checkRange(cutoff, $0, $ff, "Invalid filter cutoff frequency" + cutoff)
    .eval filterRaw(sb, ((mode+8) << 4) | channels, cutoff)
}

.function filterModulate(sb, time, speed) {
    .eval checkRange(time, 1, $7f, "Invalid modulation time " + time)
    .eval checkRange(speed, -128, 127, "Invalid modulation speed " + speed)
    .eval filterRaw(sb, time, speed & $ff)
}

.function filterJump(sb, name) {
    .eval tableRef(sb.filter, name)
}

.function filterStop(sb) {
    .eval filterRaw(sb, $ff, $00)
}

.function filterTableAdd(sb, entries) {
    .for (var i=0; i<entries.size(); i++) {
        .eval filterTableAddEntry(sb, entries.get(i))
    }
}

.function filterTableAddEntry(sb, entry) {
    .var items = tokenize(entry)
    .var size = items.size()
    .eval checkNotEquals(size, 0, "Empty filter entry") 
    
    .var cmd = items.get(0).toLowerCase()
    .if (cmd == "end") {
        .eval checkEquals(size, 1, "Invalid filter end entry " + entry)
        .return filterStop(sb)
    }
    .if (cmd == "jmp") {
        .eval checkEquals(size, 2, "Invalid filter jump entry " + entry)
        .return filterJump(sb, items.get(1))
    }
    .if (cmd == "mod") {
        .eval checkEquals(size, 3, "Invalid filter modulate entry " + entry)
        .return filterModulate(sb, parseNum(items.get(1)), parseNum(items.get(2)))
    }
    .if (cmd == "set") {
        .eval checkEquals(size, 4, "Invalid filter set entry " + entry)
        .return filterSet(sb, parseNum(items.get(1)), parseNum(items.get(2)), parseNum(items.get(3)))
    }
    .var cmdLen = cmd.size()
    .if (cmd.charAt(cmdLen-1) == ':' && cmdLen >= 2) {
        .return filterPos(sb, cmd.substring(0, cmdLen-1))
    }

    .eval error("Invalid filter entry " + entry) 
}

//----------------------------------------------------------------------------------------------------
// Commands
//----------------------------------------------------------------------------------------------------

.struct nt_command {
    name,
    adsr,
    wave,
    pulse,
    filter
}

.function commandAdd(sb, name, adsr, wave, pulse, filter) {
    .eval tableSetPos(sb.commands, name)
    .eval tableAdd(sb.commands, nt_command(
        name,
        adsr, 
        wave == 0 ? 0 : tableGetPos(sb.wave, wave),
        pulse == 0 ? 0 : tableGetPos(sb.pulse, pulse),
        filter == 0 ? 0 : tableGetPos(sb.filter, filter)
    ))
}

.function commandRef(sb, name) {
    .eval sb.commands.refs.put(name, true)
}

//----------------------------------------------------------------------------------------------------
// Patterns
//----------------------------------------------------------------------------------------------------

.function patternAdd(sb, name, entries) {
    .eval tableSetPos(sb.patterns, name)
    .var pattern = List()
    .eval tableAdd(sb.patterns, pattern)
    .for (var i=0; i<entries.size(); i++) {
        .eval patternAddEntry(sb, pattern, entries.get(i))
    }
    .eval pattern.add(0)
}

.function patternAddEntry(sb, pattern, entry) {
    .var items = tokenize(entry)
    .var size = items.size()
    .eval checkRange(size, 1, 3, "Invalid pattern entry") 
    
    .var value = null
    .var noteStr = items.get(0)
    .var durStr = (size >= 2) ? items.get(1) : null
    .var cmdStr = (size == 3) ? items.get(2) : null
    .if (noteStr == "---") {
        .eval value = (cmdStr != null) ? $08 : $0A
    }
    .if (noteStr == "+++") {
        .eval value = (cmdStr != null) ? $04 : $06
    }
    .if (value == null) {
        .eval value = $18 + (getNote(noteStr) << 1) + (cmdStr != null ? 1 : 0)
    }
    .eval checkNotEquals(value, null, "Invalid pattern note " + noteStr)
    .eval pattern.add(value)
    .if (cmdStr != null) {
        .eval pattern.add(patternGetCmd(sb, cmdStr))
    }
    .if (durStr != null && durStr != "-" && durStr != "--") { 
        .var dur = parseNum(durStr)
        .eval checkRange(dur, 2, 65, "Invalid pattern note duration " + durStr)
        .eval pattern.add(($102 - dur) & $ff)
    }
}

.function patternGetCmd(sb, cmdStr) {
    .var cmdStrSize = cmdStr.size()
    .var legatoMask = $00
    .if (cmdStr.charAt(cmdStrSize - 1) == '!' && cmdStrSize >= 2) {
        .eval cmdStr = cmdStr.substring(0, cmdStrSize-1)
        .eval legatoMask = $80
    } else {    
        .eval commandRef(sb, cmdStr)
    }
    .return tableGetPos(sb.commands, cmdStr) | legatoMask
}

//----------------------------------------------------------------------------------------------------
// Songs
//----------------------------------------------------------------------------------------------------

.struct nt_song {
    items,
    labels,
    refs,
    start1,
    start2,
    start3
}

.function songGetPos(song, name) { 
    .return tableGetPos(song, name) 
} 

.function songSetPos(song, name) { 
    .if (song.labels.containsKey(name)) {
        .eval error("Song position '" + name + "' already defined")
    }
    .eval song.labels.put(name, song.items.size())
} 

.function songAdd(sb, start1, start2, start3, entries) {
    .var song = nt_song(List(), Hashtable(), Hashtable(), -1, -1, -1)
    .eval sb.songs.add(song)
    .for (var i=0; i<entries.size(); i++) {
        .eval songAddEntry(sb, song, entries.get(i))
    }
    .eval song.start1 = songGetPos(song, start1)
    .eval song.start2 = songGetPos(song, start2)
    .eval song.start3 = songGetPos(song, start3)
}

.function songAddEntry(sb, song, entry) {
    .var items = tokenize(entry)
    .var size = items.size()
    .eval checkNotEquals(size, 0, "Empty song entry")    

    .var cmd = items.get(0).toLowerCase()
    .if (cmd == "jmp") {
        .eval checkEquals(size, 2, "Invalid song jump entry " + entry)
        .eval song.refs.put(song.items.size() + 1, items.get(1)) 
        .return song.items.add(0, 0)
    }
    .if (cmd == "tra") {
        .eval checkEquals(size, 2, "Invalid song transpose entry " + entry)
        .var transpose = parseNum(items.get(1))
        .eval checkRange(transpose, -64, 63, "Invalid song transpose value " + transpose)
        .return song.items.add(transpose > 0 ? $7f + transpose : $ff + transpose)
    }
    .if (cmd == "pat") {
        .eval checkEquals(size, 2, "Invalid song pattern entry " + entry)
        .return song.items.add(songGetPos(sb.patterns, items.get(1)))
    }
    .var cmdLen = cmd.size()
    .if (cmd.charAt(cmdLen-1) == ':' && cmdLen >= 2) {
        .return songSetPos(song, cmd.substring(0, cmdLen-1))
    }

    .eval error("Invalid song entry " + entry)
}

//----------------------------------------------------------------------------------------------------
// Note constants
//----------------------------------------------------------------------------------------------------

.define notes {
    .var notes = Hashtable()
    .eval notes.put(
        "C-", 0,
        "C#", 1, "Db", 1,
        "D-", 2,
        "D#", 3, "Eb", 3,
        "E-", 4,
        "F-", 5,
        "F#", 6, "Gb", 6,
        "G-", 7,
        "G#", 8, "Ab", 8,
        "A-", 9,
        "A#", 10, "Bb", 10,
        "B-", 11
    )
}

.function getNote(noteStr) {
    .if (noteStr.size() != 3) {
        .eval error("Invalid note definition " + noteStr)
    }

    .if (noteStr == "xxx") {
        .eval noteStr = "C-4"
    }

    .var toneStr = noteStr.substring(0,2)
    .var tone = notes.get(toneStr)
    .if (tone == null) {
        .eval error("Invalid tone " + toneStr)
    }

    .var octaveStr = noteStr.substring(2,3) 
    .var octave = octaveStr.asNumber()
    .if (octave < 1 || octave > 7) {
        .eval error("Invalid octave " + octaveStr)
    }

    .return ((octave-1) * 12) + tone
}

//----------------------------------------------------------------------------------------------------
// General functions
//----------------------------------------------------------------------------------------------------

.function tokenize(str) {
    .var result = List()
    .var size = str.size()
    .var start = 0
    .var pos = 0
    .while (start < size) {
        .while (pos < size && str.charAt(pos) != ' ') {
            .eval pos++
        }
        .if (pos != start) {
            .eval result.add(str.substring(start, pos))
        }
        .while (pos < size && str.charAt(pos) == ' ') {
            .eval pos++
        }
        .eval start = pos
    }
    .return result
}

.function parseNum(str) {
    .var size = str.size()
    .var first = str.charAt(0)      
    .if (first == '$') {
        .return str.substring(1, size).asNumber(16)
    }
    .if (first == '%') {
        .return str.substring(1, size).asNumber(2)
    }

    .return str.asNumber()
}

.function error(message) {
    .printnow message
    .error message
}
                                                                                                                                  
.function checkRange(actual, min, max, msg) {
    .if (actual < min || actual > max) {
        .eval error(msg)
    }
}

.function checkNotEquals(actual, unexpected, msg) {
    .if (actual == unexpected) {
        .eval error(msg)
    }
}

.function checkEquals(actual, expected, msg) {
    .if (actual != expected) {
        .eval error(msg)
    }
}
