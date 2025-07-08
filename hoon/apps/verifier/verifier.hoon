/=  sv  /common/stark/verifier
/=  *  /common/zoon
/=  *  /common/zeke
/=  *  /common/wrapper
::
=<  ((moat |) inner)
=>
|%
+$  kernel-state  ~
+$  cause
  $%  $:  %share
          share=[eny=@ commit=@ prf=@ dig=tip5-hash-atom]
          network-target=@
          pool-target=@
          valid-commitments=(list noun-digest:tip5)
  ==  ==
::
::  since we are only pulling one share at a time and responding about whether it
::  verified before pulling the next, we dont need to identify the share in the effect.
::  we might want to though for more robustness and visibility into what's going on, but
::  i'm going to skip it for now.
+$  effect
  $%  [%ban-peer ~]
      [%good-share ~]  :: NATS will remember what the last share sent was so no id needed
      [%bad-share ~]
      [%send-to-network ~]
  ==
--
::
|%
++  moat  (keep kernel-state)
++  inner
  |_  k=kernel-state
  ++  load  |=(=kernel-state kernel-state)
  ::
  ++  peek
    |=  arg=*
    =/  pax  ((soft path) arg)
    ?~  pax  ~|(not-a-path+arg !!)
    ~|(invalid-peek+pax !!)
  ::
  ++  poke
    |=  [wir=wire eny=@ our=@ux now=@da dat=*]
    ^-  [(list effect) k=kernel-state]
    ::
    =/  cause  (soft cause) dat)
    ?~  cause
      ~>  %slog.[0 [%leaf "error: bad cause"]]
      `k
    ::
    ::TODO verify share and emit appropriate effect
    `k
  --
--
