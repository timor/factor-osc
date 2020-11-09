USING: arrays byte-arrays calendar endian kernel lists math math.functions pack
sequences strings ;

IN: osc

! * Encoding
GENERIC: >osc* ( obj -- data type-tag )

: pad-osc-string ( str -- bytes )
    write-c-string dup length 4 align 0 pad-tail ;
M: object >osc* >byte-array "b" ;
M: string >osc* pad-osc-string "s" ;
M: fixnum >osc* 1array "i" pack-be "i" ;
! M: float >osc* write-float "f" ;
! M: float >osc* big-endian [ write-double ] with-endianness "d" ;
M: float >osc* 1array "d" pack-be "d" ;
M: boolean >osc* "T" "F" ? B{ } swap ;
M: +nil+ >osc* drop B{ } "N" ;
CONSTANT: reftime T{ timestamp
                    { year 1900 }
                    { month 1 }
                    { day 1 }
                    { gmt-offset T{ duration } } }
M: timestamp >osc*
    reftime time- duration>seconds 1 /mod
    [ >fixnum ] [ >float 32 2^ * round >fixnum ] bi*
    2array "II" pack-be "t" ;
SINGLETON: immediately

M: immediately >osc*
    drop B{ 1 } clone 8 0 pad-head "t" ;

! TODO: arrays
! M: sequence >osc*

: >osc ( seq -- bytes tag-str )
    [ B{  } "," ]
    [ [ >osc* ] [ swapd [ append ] 2dip append ] map-reduce "," prepend ]
    if-empty
    ;

: osc-message ( pattern args -- bytes )
    [ >osc* drop ] [ >osc >osc* drop ] bi* swap append append ;

: osc-bundle ( timestamp elts -- bytes )
    [ "#bundle" >osc* drop ] 2dip
    [ >osc* drop ] dip
    [ [ length 1array "I" pack-be ] keep append ] map concat append append ;

! * Decoding
: unclip-osc-string ( data -- data' string/f )
    0 over index [ 1 + 4 align cut swap [ zero? ] trim-tail >string ] [ f ] if* ;

ERROR: unknown-osc-type-tag tag ;

: unclip-tag ( data tag -- data' elt )
    { { CHAR: s [ unclip-osc-string ] }
      { CHAR: i [ 4 cut swap "i" unpack-be first ] }
      { CHAR: f [ 4 cut swap "f" unpack-be first ] }
      { CHAR: d [ 8 cut swap "d" unpack-be first ] }
      { CHAR: t [ 8 cut swap "II" unpack-be first2 32 2^ / + seconds reftime time+ ] }
      [ unknown-osc-type-tag ]
    } case ;

: unpack-osc ( bytes tag-str -- seq )
    [ CHAR: , = ] trim-head [ unclip-tag ] { } map-as nip ;

: decode-osc-message ( data -- addr args )
    unclip-osc-string swap unclip-osc-string
    unpack-osc ;

: osc> ( data -- addr/timestamp args/seq )
    dup first 47 = [ decode-osc-message ] [ drop f f ] if ;
