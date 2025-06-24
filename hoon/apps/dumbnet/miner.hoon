/=  mine  /common/pow
/=  sp  /common/stark/prover
/=  t  /common/tx-engine
/=  *  /common/zoon
/=  *  /common/zeke
/=  *  /common/wrapper
=<  ((moat |) inner)  :: wrapped kernel
=>
  |%
  +$  kernel-state  [%state version=%1]
  ::
  +$  pool-id    @tas
  +$  user-id-1  @tas
  +$  user-id-2  @tas
  ::
  +$  cause
    $:
      make-proof=?
      version=?(%0 %1)
      commit=@
      =pool-id
      =user-id-1
      =user-id-2
    ==
  ::
  +$  effect  
    $:
      %res
      eny=@
      commit=@
      prf=proof:sp
      dig=tip5-hash-atom
    ==
  ::
  --
|%
++  moat  (keep kernel-state) :: no state
++  inner
  |_  k=kernel-state
  ::  do-nothing load
  ++  load
    |=  =kernel-state  kernel-state
  ::  crash-only peek
  ++  peek
    |=  arg=*
    =/  pax  ((soft path) arg)
    ?~  pax  ~|(not-a-path+arg !!)
    ~|(invalid-peek+pax !!)
  ::  poke: try to prove a block
  ++  poke
    |=  [wir=wire eny=@ our=@ux now=@da dat=*]
    ^-  [(list effect) k=kernel-state]
    ~&  dat+dat
    =/  cause  ((soft cause) dat)
    ?~  cause
      ~>  %slog.[0 [%leaf "error: bad cause"]]
      `k
    =/  cause  u.cause
    ::
    =+  nonce-seed=[pool-id.cause user-id-1.cause user-id-2.cause eny]
    ~&  nonce-seed+nonce-seed
    ::
    =/  nonce=noun-digest:tip5
      (hash-noun-varlen:tip5 nonce-seed)
    ~&  nonce+nonce
    ::
    =/  commit=block-commitment:t
      ;;(block-commitment:t (cue commit.cause))
    ~&  commit+commit
    ::
    =/  input=prover-input:sp
      ?-  version.cause
        %0  [%0 commit nonce pow-len]
        %1  [%1 commit nonce pow-len]
      ==
    ~&  prover-input+input
    ::
    =/  [prf=proof:sp dig=tip5-hash-atom] 
      ?:  make-proof.cause
        (prove-block-inner:mine input)
      [*proof:sp *tip5-hash-atom]
    ~&  'proof done'
    ~&  digest+dig
    ~&  proof+proof
    :_  k
    ~[[%res eny commit.cause prf dig]]
  --
--
