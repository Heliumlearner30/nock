use super::tip5::R2;
use crate::based;
use crate::form::tip5::RP;

pub const fn montify(x: u64) -> u64 {
    // transform to Montgomery space, i.e. compute x•r = xr mod p
    montiply(x, R2)
}

pub const fn montiply(a: u64, b: u64) -> u64 {
    // computes a*b = (abr^{-1} mod p)
    based!(a);
    based!(b);
    mont_reduction((a as u128) * (b as u128))
}

pub const fn mont_reduction(x: u128) -> u64 {
    // mont-reduction: computes x•r^{-1} = (xr^{-1} mod p).
    assert!(x < RP);

    let x1 = x as u64;
    let x2 = (x >> 64) as u64;

    let (a, e) = x1.overflowing_add(x1 << 32);
    let b = a.wrapping_sub(a >> 32).wrapping_sub(e as u64);

    let (r, c) = x2.overflowing_sub(b);
    r.wrapping_sub((u32::MAX as u64) * c as u64)
}
