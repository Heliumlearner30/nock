use crate::form::math::base::{PRIME, PRIME_128};

#[inline(always)]
fn mont_reduction(x: u128) -> u64 {
    // x0 = bottom 32 bits of x
    let x0 = (x & 0xFFFFFFFF) as u64;
    
    // x1 = bits 32-63 of x  
    let x1 = ((x >> 32) & 0xFFFFFFFF) as u64;
    
    // x2 = top 64 bits of x
    let x2 = (x >> 64) as u64;
    
    // c = (x0 + x1) << 32
    let c = ((x0 + x1) as u128) << 32;
    
    // f = c >> 64 (top 64 bits of c)
    let f = (c >> 64) as u64;
    
    // d = c - x1 - f * PRIME
    let f_times_prime = (f as u128) * PRIME_128;
    let d = c - (x1 as u128) - f_times_prime;
    
    // Final conditional subtraction
    if x2 >= (d as u64) {
        x2 - (d as u64)
    } else {
        x2 + PRIME - (d as u64)
    }
}

#[inline(always)]
fn montiply(a: u64, b: u64) -> u64 {
    let product = (a as u128) * (b as u128);
    mont_reduction(product)
}

#[inline(always)]
fn montify(x: u64) -> u64 {
    const R2_MOD_PRIME: u64 = 0xffff_fffe_0000_0001;
    montiply(x, R2_MOD_PRIME)
}

#[inline(always)]
pub fn montgomery_mul(a: u64, b: u64) -> u64 {
    let a_mont = montify(a);
    let b_mont = montify(b);
    let result_mont = montiply(a_mont, b_mont);
    montiply(result_mont, 1)
}
