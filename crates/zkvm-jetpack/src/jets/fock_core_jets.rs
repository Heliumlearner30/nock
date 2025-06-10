use nockvm::prelude::*;

/// Jet for `++build-tree-data`
/// Input: [t alf]
/// Output: [size dyck-pelt leaf-pelt t]
pub fn build_tree_data_jet(ctx: &mut JetContext) -> NockResult {
    // Parse input subject: must be [t alf]
    let args = ctx.subject()?
        .as_cell()
        .ok_or(NockError::TypeError("expected subject cell [t alf]"))?;

    let t = args.0.clone(); // The tree structure
    let alf = args.1.as_atom().ok_or(NockError::TypeError("expected alf as atom"))?;

    // Reconstruct shape info
    let leaf = flatten_leaf(&t);  // equivalent to leaf-sequence:shape
    let dyck = flatten_dyck(&t);  // equivalent to dyck:shape

    let len = leaf.len() as u64;

    // Compute alf^len (ppow)
    let size = alf.checked_pow(len as u32)
        .ok_or(NockError::TypeError("overflow in alf ^ len"))?;

    // Compress each list into a single pelt using reverse polynomial accumulation
    let compress_pstack = |xs: &[u128]| -> u128 {
        xs.iter().rev().fold(0, |acc, x| acc * alf + x)
    };

    let leaf_pelt = compress_pstack(&leaf);
    let dyck_pelt = compress_pstack(&dyck);

    // Construct the final return value: [size dyck-pelt leaf-pelt t]
    let tree_data = Noun::Cell(
        Box::new(Noun::Atom(size)),
        Box::new(Noun::Cell(
            Box::new(Noun::Atom(dyck_pelt)),
            Box::new(Noun::Cell(
                Box::new(Noun::Atom(leaf_pelt)),
                Box::new(t),
            )),
        )),
    );

    Ok(tree_data)
}

/// Extract leaf-sequence:shape(t)
/// Flat left-to-right walk of atoms
fn flatten_leaf(t: &Noun) -> Vec<u128> {
    match t {
        Noun::Atom(n) => vec![*n],
        Noun::Cell(head, tail) => {
            let mut out = flatten_leaf(head);
            out.extend(flatten_leaf(tail));
            out
        }
    }
}

/// Extract dyck:shape(t)
/// Structure -> balanced paren representation
fn flatten_dyck(t: &Noun) -> Vec<u128> {
    match t {
        Noun::Atom(_) => vec![],
        Noun::Cell(head, tail) => {
            let mut out = vec![1]; // '('
            out.extend(flatten_dyck(head));
            out.push(2);           // ')'
            out.extend(flatten_dyck(tail));
            out
        }
    }
}