/=  v0  /common/tx-engine-0
/=  v1  /common/tx-engine-1
/=  *  /common/zoon
|%
++  coins  coins:v0
++  nname  nname:v0
++  page-number  page-number:v0
++  size  size:v0
++  timelock-range  timelock-range:v0
++  tx-id  tx-id:v0
::
::  $nnote: a nockchain note (v0 or v1)
++  nnote
  =<  form
  |%
  +$  form  $^(nnote:v0 nnote:v1)
  --
::
::  $raw-tx: a raw transaction (v0 or v1)
++  raw-tx
  =<  form
  |%
  +$  form  $^(raw-tx:v0 raw-tx:v1)
  --
::
::  $output: a note together with the seeds that spent into it
++  output
  =<  form
  |%
  +$  form
    $%  [%0 output:v0]
        [%1 output:v1]
    ==
  --
::
::  $outputs: a set of outputs
++  outputs
  =<  form
  |%
  +$  form  (z-set output)
  --
::
::  $tx: internally-validate transaction with external validation information
++  tx
  =<  form
  |%
  +$  form
    $:  =raw-tx
        =timelock-range
        total-size=size
        =outputs
    ==
  --
::
::  $txs: hash-addressed transactions
++  txs
  =<  form
  |%
  +$  form  (z-map tx-id tx)
  --
::
::  $tx-acc: accumulate transactions against a balance to create a new balance
++  tx-acc
  =<  form
  |%
  +$  form
    $:  balance=(z-map nname nnote)
        height=page-number
        fees=coins
        =size
        =txs
    ==
  ++  new
    |=  balance=(z-map nname nnote)
    ^-  form
    %*  .  *form
      balance  balance
    ==
  ::
  ::  fully validate a transaction and update the balance
  ++  process
    |=  [=form tx=raw-tx]
    ^-  ^form
    ~|  %todo  !!
  --
--
