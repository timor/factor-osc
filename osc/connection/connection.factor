USING: accessors calendar concurrency.mailboxes io.sockets kernel locals
namespaces osc sets threads ;

IN: osc.connection

SYMBOL: all-osc-connections
all-osc-connections [ V{  } clone ] initialize

TUPLE: osc-connection
    server
    reader
    responses
    socket
    timeout
    ;

: from-server? ( addr-spec conn -- ? )
    server>> = ;

:: make-reader-thread ( conn -- quot )
    [ [ conn
      [ socket>> get receive ]
      [ from-server? ] bi
      [ conn responses>> mailbox-put ]
      [ drop yield ] if t ] loop
    ] ;

: <osc-connection> ( addr port -- obj )
    [ osc-connection new ] 2dip
    <inet4> >>server
    f 0 <inet4> <datagram> >>socket
    <mailbox> >>responses
    dup make-reader-thread "OSC Reader" <thread> >>reader
    1 seconds >>timeout
    ;

: start-osc-connection ( conn -- )
    [ reader>> (spawn) ]
    [ all-osc-connections get adjoin ] bi
    ;

: stop-osc-connection ( conn -- )
    reader>> stop ;

: send-osc-bytes ( bytes conn -- )
    [ server>> ] [ socket>> ] bi send ;

: send-osc ( addr params conn -- )
    [ osc-message ] dip send-osc-bytes ;

: make-osc-bundle ( elts timestamp -- bytes )
    swap [ first2 osc-message ] map osc-bundle ;

! elts are { addr params } pairs
! can use f for timestamp for iimmediately
: send-osc-bundle ( elts timestamp conn -- )
    [ immediately or ] dip
    [ make-osc-bundle ] dip send-osc-bytes ;

: osc-reply ( conn -- addr/timestamp/f args/seq/f )
    [ responses>> ]
    [ timeout>> ] bi
    over mailbox-empty?
    [ 2drop f f ]
    [ mailbox-get-timeout osc> ] if ;
