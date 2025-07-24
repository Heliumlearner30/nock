use std::ops::{Add, Div, Mul, Neg, Sub};

use nockvm::noun::Noun;
use num_traits::Pow;

use crate::form::math::base::*;
use crate::form::math::mont::*;
use crate::form::poly::{Belt, Melt};

impl Melt {
    pub fn inv(self) -> Self {
        self.pow(PRIME - 2)
    }

    pub const fn from_u64(v: u64) -> Self {
        Self(montify(v))
    }

    pub const fn pow(self, exp: u64) -> Self {
        let mut acc = Melt::from_u64(1).0;
        let bit_length = u64::BITS - exp.leading_zeros();
        let mut i = 0;
        while i < bit_length {
            acc = montiply(acc, acc);
            if exp & (1 << (bit_length - 1 - i)) != 0 {
                acc = montiply(acc, self.0);
            }
            i += 1;
        }

        Melt(acc)
    }

    pub fn from_belt_vec(mut v: Vec<Belt>) -> Vec<Self> {
        const _: [(); core::mem::size_of::<Melt>()] = [(); core::mem::size_of::<Belt>()];
        v.iter_mut().for_each(|v| *v = Belt(Melt::from(*v).0));
        // SAFETY: Melt and Belt have the same size and bit representation
        unsafe { core::mem::transmute(v) }
    }
}

impl From<Melt> for Belt {
    #[inline(always)]
    fn from(value: Melt) -> Self {
        Belt(mont_reduction(value.0 as _))
    }
}

impl From<Belt> for Melt {
    #[inline(always)]
    fn from(value: Belt) -> Self {
        Melt::from_u64(value.0)
    }
}

impl Add for Melt {
    type Output = Self;

    #[inline(always)]
    fn add(self, rhs: Self) -> Self::Output {
        let a = self.0;
        let b = rhs.0;
        Melt(badd(a, b))
    }
}

impl Sub for Melt {
    type Output = Self;

    #[inline(always)]
    fn sub(self, rhs: Self) -> Self::Output {
        Self(bsub(self.0, rhs.0))
    }
}

impl Neg for Melt {
    type Output = Self;

    #[inline(always)]
    fn neg(self) -> Self::Output {
        Self(bneg(self.0))
    }
}

impl Mul for Melt {
    type Output = Self;

    #[inline(always)]
    fn mul(self, rhs: Self) -> Self::Output {
        let a = self.0;
        let b = rhs.0;
        Melt(montiply(a, b))
    }
}

impl Pow<u64> for Melt {
    type Output = Self;

    #[inline(always)]
    fn pow(self, exp: u64) -> Self::Output {
        Melt::pow(self, exp)
    }
}

impl Pow<usize> for Melt {
    type Output = Self;

    #[inline(always)]
    fn pow(self, rhs: usize) -> Self::Output {
        self.pow(rhs as u64).into()
    }
}

impl Div for Melt {
    type Output = Self;

    #[inline(always)]
    #[allow(clippy::suspicious_arithmetic_impl)]
    fn div(self, rhs: Self) -> Self::Output {
        rhs.inv() * self
    }
}

impl TryFrom<Noun> for Melt {
    type Error = ();

    #[inline(always)]
    fn try_from(n: Noun) -> std::result::Result<Self, Self::Error> {
        if !n.is_atom() {
            Err(())
        } else {
            Belt::try_from(&n.as_atom()?.as_u64()?).map(|v| v.into())
        }
    }
}
