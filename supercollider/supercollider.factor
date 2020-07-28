USING: io.sockets kernel namespaces osc ;

IN: supercollider

SYMBOL: sc-timeout
sc-timeout [ 1 seconds ] initialize

SYMBOL: sc-server
sc-server [ "127.0.0.1" 57110 <inet4> ] initialize
SYMBOL: sc-socket

: connect ( -- )
    sc-socket get
    [ f 0 <inet4> <datagram> sc-socket set
      sc-timeout get sc-socket get set-timeout
    ] unless ;

: (send-msg) ( addr params -- )
    osc-message sc-server get sc-socket get send ;

: from-sc-server? ( addr-spec -- ? )
    sc-server get = ;

: send-msg ( addr params -- addr params )
    (send-msg)
    sc-socket get receive from-sc-server? [ osc> ] [ drop f f ] if ;
