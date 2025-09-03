/=  v0  /common/tx-engine-0
/=  *  /common/zeke
/=  *  /common/zoon
|%
::  import
++  hash  hash:v0
++  schnorr-pubkey  schnorr-pubkey:v0
++  schnorr-signature  schnorr-signature:v0
++  schnorr-seckey  schnorr-seckey:v0
++  page-number  page-number:v0
++  coins  coins:v0
++  source  source:v0
++  tx-id  tx-id:v0
++  page  page:v0
++  timelock-range  timelock-range:v0
::
:: $nname
++  nname
  =<  form
  =+  nname:v0
  |%
  +$  form  $|(^form |=(* %&))
  ++  new-v1
    |=  [lock=hash =source]
    ^-  form
    =/  first-name
      (hash-hashable:tip5 [leaf+& hash+lock])
    =/  last-name
      %-  hash-hashable:tip5
      :*  leaf+&
          (hashable:^source source)
          leaf+~
      ==
    [first-name last-name ~]
  --
::
:: $nnote. A Nockchain note. A UTXO. (Version 1)
++  nnote
  =<  form
  |%
  +$  form
    $:
      version=%1
      origin-page=page-number
      name=nname
      =note-data
      assets=coins
    ==
  ++  based
    |=  =form
    ?&  (based:nname name.form)
        (based:note-data note-data.form)
        (^based assets.form)
    ==
  ++  hashable
    |=  =form
    ^-  hashable:tip5
      :-  :-  leaf+version.form
          leaf+origin-page.form
      :+  hash+(hash:nname name.form)
        hash+(hash:note-data note-data.form)
      leaf+assets.form
  ++  hash
    |=  =form
    %-  hash-hashable:tip5
    (hashable form)
  ++  lock-hash
    |=  =form
    -.name.form
  ++  source-hash
    |=  =form
    +<.name.form
  -- :: nnote
::
::  $note-data: data associated with a note
++  note-data
  =<  form
  |%
  +$  form  (z-map @tas *)
  ++  based
    |=  =form
    |^
      ^-  ?
      %-  ~(rep by form)
      |=  [[k=@tas v=*] a=?]
      ?&(a (^based k) (based-noun v))
    ++  based-noun
      |=  n=*
      ?^  n  ?&($(n -.n) $(n +.n))
      (^based n)
    --  ::  based:note-data
  ++  hashable
    |=  =form
    ^-  hashable:tip5
    |^
      ?~  form  leaf+~
      :*  leaf+p.n.form
          (hashable-noun q.n.form)
          $(form l.form)
          $(form r.form)
      ==
    ::
    ++  hashable-noun
      |=  n=*
      ?^  n  [$(n -.n) $(n +.n)]
      leaf+n
    --  ::  $hashable:note-data
  ++  hash
    |=  =form
    %-  hash-hashable:tip5
    (hashable form)
  --  ::  $note-data
::
::  $seed: carrier of value from input to output (v1)
++  seed
  =<  form
  |%
  +$  form
    $:  ::  if non-null, enforces that output note must have precisely this source
        output-source=(unit source)
        ::  merkle root of lock script
        lock-root=^hash
        ::  data to store with note
        =note-data
        ::  asset quantity
        gift=coins
        ::  check that parent hash of every seed is the hash of the parent note
        parent-hash=^hash
    ==
  ::
  ++  new
    |=  $:  output-source=(unit source)
            =lock
            gift=coins
            parent-hash=^hash
        ==
    %*  .  *form
      output-source  output-source
      lock-root  (hash:^lock lock)
      gift  gift
      parent-hash  parent-hash
    ==
  ::
  ++  based
    |=  =form
    ^-  ?
    =/  based-output-source
      ?~  output-source.form  %&
      (based:^hash p.u.output-source.form)
    ?&  based-output-source
        (based:^hash lock-root.form)
        (^based gift.form)
        (based:^hash parent-hash.form)
    ==
  ::
  ++  hashable
    |=  sed=form
    ^-  hashable:tip5
    :+  hash+lock-root.sed
      leaf+gift.sed
    hash+parent-hash.sed
  ::
  ++  sig-hashable
    |=  sed=form
    ^-  hashable:tip5
    :^    (hashable-unit:source output-source.sed)
        hash+lock-root.sed
      leaf+gift.sed
    hash+parent-hash.sed
  ::
  ++  hash
    |=  =form
    %-  hash-hashable:tip5
    (hashable form)
  --  ::  seed
::
::  $seeds: Collection of seeds used in a $spend
++  seeds
  =<  form
  |%
  +$  form  (z-set seed)
  ::
  ++  new
    |=  seds=(list seed)
    ^-  form
    (~(gas z-in *form) seds)
  ::
  ++  based
    |=  =form
    ^-  ?
    %-  ~(rep z-in form)
    |=  [s=seed a=?]
    ?&(a (based:seed s))
  ::
  ++  hashable
    |=  =form
    ^-  hashable:tip5
    ?~  form  leaf+~
    :+  (hashable:seed n.form)
      $(form l.form)
    $(form r.form)
  ::
  ++  sig-hashable
    |=  =form
    ^-  hashable:tip5
    ?~  form  leaf+form
    :+  (sig-hashable:seed n.form)
      $(form l.form)
    $(form r.form)
  ::
  ++  hash
    |=  =form
    %-  hash-hashable:tip5
    (hashable form)
  --  ::  seeds
::
::  $spend: Spend a note into v1 notes
++  spend
  =<  form
  |%
  +$  form  $%([%0 spend-0] [%1 spend-1])
  ++  hash  ~|  %todo  !!
  ++  sig-hash
    |=  =form
    ^-  ^hash
    ?-  -.form
      %0  (sig-hash:spend-0 +.form)
      %1  (sig-hash:spend-1 +.form)
    ==
  --
::
::  $spend-0: Spend a v0 note into v1 notes
++  spend-0
  =<  form
  |%
  +$  form
    $:  signature=signature:v0
        =seeds
        fee=coins
    ==
  ++  hash  ~|  %todo  !!
  ++  sig-hash
    |=  =form
    ^-  ^hash
    ~|  %todo  !!
  --
::
::  $spend-1: Spend a v1 note
++  spend-1
  =<  form
  |%
  +$  form
    $:  =witness
        =seeds
        fee=coins
    ==
  ::
  ++  new
    |=  [=seeds fee=coins]
    %*  .  *form
      seeds  seeds
      fee  fee
    ==
  ::
  ++  sign
  |=  [sen=form sk=schnorr-seckey]
  ^+  sen
  =/  pk=schnorr-pubkey
    %-  ch-scal:affine:curve:cheetah
    :*  (t8-to-atom:belt-schnorr:cheetah sk)
        a-gen:curve:cheetah
    ==
  =/  sig=schnorr-signature
    %+  sign:affine:belt-schnorr:cheetah
      sk
    (leaf-sequence:shape (sig-hash sen))
    ::%_  sen
    ::  sig.witness  (~(put z-by sig.witness.sen) pk sig)
    ::==
    ~|  %todo  !!
  :: TODO check basedness of preimage
  ++  hash-unlock
    |=  pre=*
    ~|  %todo  !!
  ++  signatures
    |=  sen=form
    ^-  (list [schnorr-pubkey (list belt) schnorr-signature])
    ~|  %todo  !!
    ::%+  turn
    ::  ::~(tap z-by sig.witness.sen)
    ::  ^-  (list [schnorr-pubkey schnorr-signature])
    ::  ~|  %todo  !!
    ::|=  [pk=schnorr-pubkey sig=schnorr-signature]
    :::+    pk
    ::  (leaf-sequence:shape (sig-hash:spend sen))
    ::sig
  ::  a bit more expansive since it also needs to verify the hash locks
  ++  verify  ~|  %todo  !!
  ::
  ++  verify-signatures  ~|  %todo  !!
  ::
  ++  verify-hashes  ~|  %todo  !!
  ::
  ++  verify-without-signatures  ~|  %todo  !!
  ::
  ++  based  ~|  %todo  !!
  ::
  ++  hashable  ~|  %todo  !!
  ::
  ++  sig-hash
    |=  =form
    ^-  hash
    ~|  %todo  !!
  --  ::  spend
::
::  $spends: associate spends with their input note names
++  spends
  =<  form
  |%
  +$  form  (z-map nname spend)
  ++  based
    |=  =form
    ^-  ?
    ~|  %todo  !!
  ++  hashable
    |=  =form
    ^-  hashable:tip5
    ~|  %todo  !!
  ++  hash
    |=  =form
    %-  hash-hashable:tip5
    (hashable form)
  --
::
::  $input: inputs to a v1 transaction
::
::  Note that .note can be a v0 or v1 note,
::  and that witness.spend can be a v0 witness (just signatures)
::  or a v1 witness (a segwit witness), so validity checking must first ensure
::  matching versions between note and witness before checking the witness itself
++  input
  =<  form
  |%
  +$  form  [note=nnote =spend]
  ++  new  ~|  %todo  !!
  ++  validate  ~|  %todo  !!
  ++  based  ~|  %todo  !!
  ++  hashable  ~|  %todo  !!
  ++  hash  ~|  %todo  !!
  --
::
::  $inputs: map of names to inputs (version 1)
++  inputs
  =<  form
  |%
  +$  form  (z-map nname input)
  ++  new
    =<  from-spends
    |%
    ++  from-spends
      |=  [=spends notes=(z-map nname nnote)]
      ^-  (unit form)
      %-  ~(rep z-by spends)
      |=  [[=nname =spend] i=(unit form)]
      ^-  (unit form)
      ?~  i  ~
      =/  note  (~(get z-by notes) nname)
      ?~  note  ~
      `(~(put z-by u.i) nname [u.note spend])
    --
  ++  names  ~|  %todo  !!
  ++  roll-fees  ~|  %todo  !!
  ++  roll-timelocks  ~|  %todo  !!
  ++  validate  ~|  %todo  !!
  ++  verify-signatures  ~|  %todo  !!
  ++  signatures  ~|  %todo  !!
  ++  based  ~|  %todo  !!
  ++  hashable  ~|  %todo  !!
  ++  hash  ~|  %todo  !!
  --
::
::
++  output
  =<  form
  |%
  +$  form  [note=nnote =seeds]
  --
::
::  $raw-tx: version 1 transaction
::
::  Transactions were not initially versioned which was a mistake.
::  Fortunately we can disambiguate carefully.
::  The head of a v0 transaction will be a cell (the tx-id)
::  The head of a v >0 transaction will be the version atom
++  raw-tx
  =<  form
  |%
  +$  form
    $:  version=%1
        id=tx-id
        =spends
    ==
  ++  new  ~|  %todo  !!
  ++  compute-id  ~|  %todo  !!
  ++  based  ~|  %todo  !!
  ++  validate  ~|  %todo  !!
  ++  inputs-names  ~|  %todo  !!
  ++  compute-size  ~|  %todo  !!
  --
::
::  $lock-primitive: lock script primitive
++  lock-primitive
  =<  form
  |%
  +$  form
    $%  [%pkh pkh]
        [%tim tim]
        [%hax hax]
    ::  it's important that this be the default to break a type loop in the compiler
        [%brn ~]
    ==
  ++  based
    |=  =form
    ?-  -.form
        %tim  (based:tim +.form)
        %hax  (based:hax +.form)
        %pkh  (based:pkh +.form)
        %brn  %&
    ==
  ++  hashable
    |=  =form
    ?-  -.form
        %tim  [leaf+%tim (hashable:tim +.form)]
        %hax  [leaf+%hax (hashable:hax +.form)]
        %pkh  [leaf+%pkh (hashable:pkh +.form)]
        %brn  leaf+%brn
    ==
  ++  hash
    |=  =form
    %-  hash-hashable:tip5
    (hashable form)
  --
::
::  $spend-condition: AND-list of lock-primitives: all must be satisfied to spend
++  spend-condition
  =<  form
  |%
  +$  form  (list lock-primitive)
  --  ::  spend-condition
::
::  $lock: OR-list of $spend-condition: a choice of spend conditions
++  lock
  =<  form
  |%
  +$  form  (list spend-condition)
  --  ::  lock
::
::  $witness: version 1 witness for spend conditions
++  witness
  =<  form
  |%
  +$  form
    $:  lok=lock-merkle-proof
        pkh=pkh-signature
        hax=(z-map ^hash *)
        tim=~
    ==
  ++  hash  ~|  %todo  !!
  --
::
::  $lock-merkle-proof: merkle-proof for a branch of a lock script
++  lock-merkle-proof
  =<  form
  |%
  +$  form  [rest=^hash this=spend-condition pred=(list ^hash)]
  ++  hash  ~|  %todo  !!
  ::  note that the hash comes from the nname and thus must be
  ::  the hash of the merkle proof, paired with & (see v1-name:nname)
  ++  check
    |=  [=form firstname=^hash]
    ^-  ?
    ~&  %todo  !!
  --
::
::  $pkh: pay to public key hash
++  pkh
  =<  form
  |%
  +$  form  [m=@ h=(z-set ^hash)]
  ++  based
    |=  =form
    ^-  ?
    ~|  %todo  !!
  ++  hashable
    |=  =form
    ^-  hashable:tip5
    ~|  %todo  !!
  ++  hash  ~|  %todo  !!
  ++  check
    |=  [=form ctx=check-context]
    ^-  ?
    ?&
    ::  correct number of signatures
      =(m.form ~(wyt z-by pkh.witness.ctx))
    ::  permissible public key hashes
      =(~ (~(dif z-in ~(key z-by pkh.witness.ctx)) h.form))
    ::  hashes match
      %-  ~(rep z-by pkh.witness.ctx)
      |=  [[h=^hash pk=schnorr-pubkey sig=schnorr-signature] a=?]
      ?&  a
          =(h (hash:schnorr-pubkey pk))
      ==
    ::  signatures valid
      %-  batch-verify:affine:belt-schnorr:cheetah
      (signatures:pkh-signature pkh.witness.ctx sig-hash.ctx)
    ==
  --
::
::  $hax: Hashlock
++  hax
  =<  form
  |%
  +$  form  (z-set ^hash)
  ++  based
    |=  =form
    %-  ~(all z-in form)
    based:^hash
  ++  hashable
    |=  =form
    ?~  form  leaf+~
    :*  hash+n.form
        $(form l.form)
        $(form r.form)
    ==
  ++  hash
    |=  =form
    %-  hash-hashable:tip5
    (hashable form)
  ++  hash-noun
    |=  n=*
    ^-  ^hash
    %-  hash-hashable:tip5
    |-  ^-  hashable:tip5
    ?^  n  [$(n -.n) $(n +.n)]
    leaf+n
  ++  check
    |=  [=form ctx=check-context]
    ^-  ?
    %-  ~(all z-in form)
    |=  =^hash
    =/  preimage  (~(get z-by hax.witness.ctx) hash)
    ?~  preimage  %|
    =(hash (hash-noun u.preimage))
  --  :: hax
::
::  $tim: timelock for lockscripts
++  tim
  =<  form
  =+  timelock:v0
  |%
  ++  form  $|(^form |=(* %&))  :: hack to let us extend the core
  ++  check
    |=  [=form ctx=check-context]
    ^-  ?
    (check:timelock-range (fix-absolute form since.ctx) now.ctx)
  --
::
::  $pkh-signature: pubkeys and signatures witnessing a spend of a %pkh $end
++  pkh-signature
  =<  form
  |%
  +$  form  (z-map ^hash [pk=schnorr-pubkey sig=schnorr-signature])
  ++  based
    |=  =form
    ^-  ?
    ~|  %todo  !!
  ++  hashable  ~|  %todo  !!
  ++  hash  ~|  %todo  !!
  ::
  ::  all the signatures in a form suitable for batch verification
  ++  signatures
    |=  [=form sig-hash=(list belt)]
    ^-  (list [schnorr-pubkey (list belt) schnorr-signature])
    %-  ~(rep z-by form)
    |=  $:  [* pk=schnorr-pubkey sig=schnorr-signature]
            sigs=(list [schnorr-pubkey (list belt) schnorr-signature])
        ==
    ^-  (list [schnorr-pubkey (list belt) schnorr-signature])
    :_  sigs
    [pk sig-hash sig]
  --
::
::  $check-context: Context provided for validating locks
::
::    .now: current page height
::    .since: page height of the note
::    .sig-hash: signature to be hashed for a spend
::    .witness: witness to spend conditions
++  check-context
  =<  form
  |%
  +$  form  [now=page-number since=page-number sig-hash=(list belt) =witness]
  ::
  ::  have to do this here because we get infinite bunts if we pass this to
  ::  included types
  ++  check
    |=  [=form lock=hash]
    ^-  ?
    ?&
    ::  check the merkle proof for the lock script
      (check:lock-merkle-proof lok.witness.form lock)
    ::  check each primitive
      %+  levy  this.lok.witness.form
      |=  p=lock-primitive
      ^-  ?
      ?-  -.p
        %tim  (check:tim +.p form)
        %hax  (check:hax +.p form)
        %pkh  (check:pkh +.p form)
        %brn  %|
      ==
    ==
  ++  check-spend-1
    |=  [=nname =spend=spend-1 now=page-number since=page-number]
    ^-  ?
    ~|  %todo  !!
  --
--
