#import "ntplay-defs.asm"

.const RASTER_LINE = $33

.pc = $02 "Zero page variables" virtual
#import "ntplay-vars.asm"

.pc = $0801 "Basic Upstart"
:BasicUpstart(start)

.pc = $0810 "Code"
start: {
        sei
        cld
        
        lda #<musicdata
        ldx #>musicdata
        jsr nt_newmusic
        lda #0
        jsr nt_playsong
        
    loop:
    !:  lda $d011
        bpl !-
    !:  lda $d011
        bmi !-
    
        lda #RASTER_LINE
    !:  cmp $d012
        bne !-
        
        inc $d020
        jsr nt_music
        dec $d020
        jmp loop
}

#import "ntplay.asm"

.pc = * "Music data"

.define sb {
    .var sb = songBookCreate()
    .eval waveTableAdd(sb, List().add(
        "wave1:",
            "set $81 C-6",
            "set $41 E-3",
            "set $41",
            "end",
        "wave2:",        
            "set $21",
            "del $08",
            "vib $1B $10",
        "wave3:",
            "set $51",
        "wave4:",
            "set $41",
            "end",
        "wave5:",
            "set $41 +0",
            "set $41 +3",
            "set $41 +7",
            "set $41 +12",
            "jmp wave5",
        "wave6:",
            "set $41 +0",
            "set $41 +4",
            "set $41 +7",
            "set $41 +12",
            "jmp wave6",
        "wave7:",
            "sli $1E00",
        "wave8:",
            "set $81 E-6",
            "set $41",
            "end",
        "wave9:",
            "set $81 E-6",
            "set $41 A#3",
            "set $41 E-3",
            "set $81 D-6",
            "set $81 A#5",
            "set $41",
            "end",
        "wave10:",
            "set $51",
            "set $41",
            "del $18",
            "vib $1B $10",
        "wave11:",
            "sli $0040"
    ))
    
    .eval pulseTableAdd(sb, List().add(
        "pulse1:",
            "set $08",
        "pulse2:",
            "set $08",
            "set $08",
        "pulse3:",
            "set $01",
        "loop1:",
            "mod $60 32",
            "mod $60 -33",
            "jmp loop1",
        "pulse4:",
            "set $01",
            "mod $08 $50",
            "jmp loop1",
        "pulse5:",
            "set $80",
        "loop2:",
            "mod $18 -128",
            "mod $18 127", 
            "jmp loop2"
    ))
        
    .eval filterTableAdd(sb, List().add(
        "filter1:",
            "set 1 2 $60",
        "loop:",
            "mod $60 1",
            "mod $60 -1",
            "jmp loop"
    ))

    // Commands
    .eval commandAdd(sb, "bs+kick",   $09BB, "wave1",   "pulse2",   0)
    .eval commandAdd(sb, "bs+hihat",  $09BB, "wave8",   "pulse3",   0)
    .eval commandAdd(sb, "bs+snare",  $09BB, "wave9",   "pulse1",   0)
    .eval commandAdd(sb, "sawtooth",  $006C, "wave2",   0,          "filter1")
    .eval commandAdd(sb, "pulselead", $068C, "wave3",   "pulse4",   0)
    .eval commandAdd(sb, "pulse-min", $074B, "wave5",   "pulse4",   "filter1")
    .eval commandAdd(sb, "pulse-maj", $074B, "wave6",   "pulse4",   "filter1")
    .eval commandAdd(sb, "quietpuls", $044B, "wave4",   "pulse5",   0)
    .eval commandAdd(sb, "pulsl+vib", $068C, "wave10",  "pulse4",   0)
    .eval commandAdd(sb, "slide-fff", $0000, "wave7",   0,          0)
    .eval commandAdd(sb, "slide-040", $0000, "wave11",  0,          0)

    // Patterns
    .eval patternAdd(sb, "01", List().add(
        "--- 40"
    ))

    .eval patternAdd(sb, "02", List().add(
        "A-1 40 bs+kick", 
        "+++",
        "+++",
        "+++",
        "G-1",
        "+++",
        "+++",
        "+++",
        "D-2",
        "+++",
        "+++",
        "+++",
        "A-1",
        "+++",
        "+++",
        "+++"
    ))

    .eval patternAdd(sb, "03", List().add(
        "C-4 40 sawtooth",
        "+++",
        "+++",
        "+++",
        "B-3",
        "+++",
        "+++",
        "A-3 20",
        "G-3",
        "C-4 40",
        "+++",
        "+++",
        "+++",
        "A-3",
        "+++",
        "+++",
        "+++"
    ))

    .eval patternAdd(sb, "04", List().add(
        "E-4 10 pulselead",
        "D-4",
        "E-4",
        "A-4 30",
        "E-4",
        "E-4",
        "D-4 20",
        "C-4",
        "D-4 10",
        "C-4",
        "D-4",
        "G-4 30",
        "D-4",
        "D-4",
        "C-4 20",
        "B-3",
        "C-4 10",
        "B-3",
        "A-3",
        "A-3 30",
        "A-3",
        "A-3",
        "G-3 20",
        "A-3",
        "E-3 40",
        "+++",
        "+++",
        "+++"
    ))
    
    .eval patternAdd(sb, "05", List().add(
        "A-4 10 sawtooth",
        "B-4",
        "C-5 60",
        "+++",
        "+++ 20",
        "B-4 10",
        "C-5",
        "D-5 60",
        "+++",
        "+++ 20",
        "E-5 10",
        "D-5",
        "C-5",
        "C-5 60",
        "+++ 30",
        "B-4 20",
        "D-4",
        "C-4 60",
        "+++",
        "+++ 40"
    ))
    
    .eval patternAdd(sb, "06", List().add(
        "A-4 40 pulse-min",
        "+++",
        "+++",
        "+++",
        "G-4 -- pulse-maj",
        "+++",
        "+++",
        "+++",
        "F-4",
        "+++",
        "+++",
        "+++",
        "A-4 -- pulse-min",
        "+++",
        "+++",
        "+++"
    ))

    .eval patternAdd(sb, "07", List().add(
        "C-5 60 quietpuls",
        "+++",
        "+++ 20",
        "D-5 10 slide-fff!",
        "E-5",
        "G-5 60 quietpuls",
        "+++",
        "+++ 20",
        "A-5 10 slide-fff!",
        "B-5",
        "C-6 -- quietpuls",
        "B-5 -- slide-fff!",
        "A-5",
        "E-5 60 quietpuls",
        "+++ 40",
        "D-5 10",
        "G-4 -- slide-fff!",
        "D-4",
        "C-4 60 quietpuls",
        "+++",
        "+++ 40"                                                        
    ))

    .eval patternAdd(sb, "08", List().add(
        "G-1 10 bs+kick",
        "A-1 -- bs+hihat",
        "+++",
        "A-1 -- bs+kick",
        "A-1 -- bs+snare",
        "+++",
        "A-1 -- bs+hihat",
        "G-1 -- bs+kick",
        "+++",
        "A-1",
        "+++",
        "A-1",
        "A-1 -- bs+snare",
        "+++",
        "A-1 -- bs+hihat",
        "A-1"    
    ))

    .eval patternAdd(sb, "09", List().add(
        "G-1 10 bs+kick",
        "A-1 -- bs+hihat",
        "+++",
        "A-1 -- bs+kick",
        "A-1 -- bs+snare",
        "+++",
        "A-1 -- bs+hihat",
        "G-1 -- bs+kick",
        "+++",
        "A-1",
        "+++",
        "A-1",
        "A-1 -- bs+snare",
        "+++",
        "A-1",
        "A-1"    
    ))

    .eval patternAdd(sb, "0A", List().add(
        "G-4 40 pulse-maj",
        "+++",
        "+++",
        "+++",
        "F-4",
        "+++",
        "+++",
        "+++",
        "A-4 -- pulse-min",
        "+++",
        "+++",
        "+++",
        "E-4",
        "+++",
        "+++",
        "+++"
    ))

    .eval patternAdd(sb, "0B", List().add(
        "G-3 60 pulsl+vib",
        "+++ 20",
        "A-3 35",
        "A#3 05 slide-fff!",
        "B-3 10",
        "+++ 30",
        "C-4 10 pulsl+vib",
        "A-3 60",
        "+++ 10",
        "--- 40",
        "G-3 30",
        "A-3 05 slide-fff!",
        "G-3",
        "E-3 60 pulsl+vib",
        "+++ 20",
        "--- 50",
        "D-3 10",
        "C-3 -- slide-fff!",
        "D-3",
        "D-3 03 pulsl+vib",
        "E-3 07 slide-040!",
        "D-3 20 slide-fff!",
        "+++ 60",
        "+++ 30",
        "--- 40"
    ))
    
    .eval patternAdd(sb, "0C", List().add(
        "G-3 60 pulsl+vib",
        "+++ 20",
        "A-3 35",
        "A#3 05 slide-fff!",
        "B-3 10",
        "+++ 30",
        "C-4 10 pulsl+vib",
        "A-3 60",
        "+++ 10",
        "--- 50",
        "A-3 10",
        "C-4 -- slide-fff!",
        "D-4",
        "D-4 03 pulsl+vib",
        "E-4 17 slide-040!",
        "+++ 60",
        "+++ 50",
        "D-4 10 slide-fff!",
        "C-4",
        "D-4",
        "D-4 03 pulsl+vib",
        "E-4 17 slide-040!",
        "+++ 46",
        "F-4 04 slide-fff!",
        "F#4",
        "G-4 16",
        "+++ 60",
        "+++ 10"
    ))
    
    .eval songAdd(sb, "loop1", "loop2", "loop3", List().add(
        "loop1:",
            "tra 0",
            "pat 02",
            "pat 02",
            "pat 02",   
            "pat 02",
            "pat 08",
            "tra -2",
            "pat 08",            
            "tra 5",
            "pat 08",            
            "tra 0",
            "pat 08",            
            "pat 08",            
            "tra -2",
            "pat 08",            
            "tra 5",
            "pat 08",            
            "tra 0",
            "pat 08",            
            "pat 08",            
            "tra -2",
            "pat 08",            
            "tra 5",
            "pat 08",            
            "tra 0",
            "pat 08",            
            "pat 08",            
            "tra -2",
            "pat 08",            
            "tra 5",
            "pat 08",            
            "tra 0",
            "pat 08",            
            "tra -2",
            "pat 08",            
            "tra -4",
            "pat 08",            
            "tra 0",
            "pat 08",            
            "tra -2",
            "pat 08",            
            "pat 08",            
            "tra -4",
            "pat 08",            
            "tra 0",
            "pat 08",            
            "tra 7",
            "pat 09",            
            "tra 2",
            "pat 08",            
            "tra 0",
            "pat 08",            
            "tra 7",
            "pat 08",            
            "tra 2",
            "pat 08",            
            "pat 08",            
            "tra 0",
            "pat 08",            
            "tra 7",
            "pat 08",            
            "tra 2",
            "pat 08",            
            "pat 08",            
            "tra 0",
            "pat 08",            
            "tra 7",
            "pat 08",            
            "tra 2",
            "pat 08",            
            "pat 08",            
            "tra 0",
            "pat 08",            
            "tra 7",
            "pat 08",            
            "tra 2",
            "pat 09",            
            "jmp loop1",
        "loop2:",
            "tra 0",
            "pat 03",            
            "pat 05",            
            "pat 06",            
            "pat 07",            
            "pat 03",            
            "pat 05",            
            "pat 06",            
            "pat 07",            
            "pat 0A",
            "pat 0A",
            "tra 2",
            "pat 03",            
            "pat 05",            
            "pat 06",            
            "pat 07",            
            "jmp loop2",
        "loop3:",
            "tra 0",
            "pat 04",            
            "pat 04",            
            "pat 04",            
            "pat 04",            
            "pat 04",            
            "pat 04",            
            "pat 04",            
            "pat 04",            
            "pat 0B",            
            "pat 0C",            
            "tra 2",
            "pat 04",            
            "pat 04",            
            "pat 04",            
            "pat 04",            
            "jmp loop3"
    ))

    .eval songAdd(sb, "loop1", "loop2", "loop3", List().add(
        "loop1:",
            "pat 01",
            "jmp loop1",
        "loop2:",
            "pat 01",
            "jmp loop2",
        "loop3:",
            "pat 01",
            "jmp loop3"
    ))
    
    .eval songBookEnd(sb)
}

musicdata:
    songBookDump(sb)
