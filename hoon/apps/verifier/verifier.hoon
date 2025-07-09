/=  mine  /common/pow
/=  nv  /common/nock-verifier
/=  *  /common/zoon
/=  *  /common/zeke
/=  *  /common/wrapper
::
=<  ((moat |) inner)
=>
|%
+$  kernel-state  ~
::  $cause: possible pokes
::
::    %share:
::      .share: result from a miner
::      .claimed-target: whether the miner claims they hit network or pool target. network is
::          processed more urgently, so sending a share that does not meet the network target is
::          a potentially bannable offense.
::      .network-target: current target needed to find a block on the network
::      .pool-target: current target needed to get a share in the pool
::      .pow-len: the length of the powork puzzle. always 64 on livenet.
::      .valid-commitments: acceptable commitments
+$  cause
  $%  $:  %share
          share=[eny=@ commit=noun-digest:tip5 prf=proof dig=tip5-hash-atom]
          ::  we can just send in one target, the target we want, rather than
          ::  distinguishing between the two with a @tas
          ::
          ::  we should ban someone who sends us a non-network share at the
          ::  network verifier
          ::  claimed-target=?(%network %pool)
          ::  network-target=@
          ::  pool-target=@
          target=@
          pow-len=@
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
    =/  cause  ((soft cause) dat)
    ?~  cause
      ~>  %slog.[0 [%leaf "error: bad cause"]]
      `k
    =/  cause  u.cause
    ::
    ?>  ?=([%share *] cause)
    ::
    =/  prf=proof  prf.share.cause
    ::
    ::  validate that the correct powork puzzle was solved
    =/  check-pow-puzzle=?
      ?:  =((lent objects.prf) 0)  %.n
      =/  puzzle  (snag 0 objects.prf)
      ?.  ?=([%puzzle *] puzzle)  %.n
      =(pow-len.cause len.puzzle)
    ?.  check-pow-puzzle
      ::TODO should this just be a straight up ban?
      :_  k
      [%bad-share ~]~
    ::
    ::  validate the proof
    =/  valid=?
      (verify:nv prf ~ eny.share.cause)
    ?.  valid
      ::TODO ban?
      :_  k
      [%bad-share ~]~
    ::
    ?:  (check-target-atom:mine dig.share.cause network-target.cause)
      ::  if it hit the network target, we don't actually care whether the miner claimed it
      ::  was or not in .claimed-target - if they somehow accidentally called it a pool share,
      ::  it seems wrong to punish them when its still a good block.
      ::
      ::  we met the network target, emit block
      :_  k
      ::TODO  i think we do both %good-share and %send-to-network because the components
      :: tracking shares and interfacing with the network are separate
      ~[[%good-share ~] [%send-to-network ~]]
    ::
    ?:  =(%network claimed-target.cause)
      ::  they claimed to hit the network target, but didn't. this consumed valuable time on the
      ::  network verifier, so they are punished
      :_  k
      [%bad-share ~]~
    ::
    ?:  (check-target-atom:mine dig.share.cause pool-target.cause)
      ::  we did not meet the network target, but we did meet the pool target
      :_  k
      [%good-share ~]~
    ::  valid proof submitted that did not meet the pool or network difficulty. therefore
    ::  it should not have been submitted by the miner at all.
    :_  k
    [%bad-share ~]~
  --
--
