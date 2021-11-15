pub const ExpressionTag = enum {
    atom,
    cons,
};

pub const Expression = union(ExpressionTag) { atom: f64, cons: struct {
    head: u8,
    rest: []Expression,
} };
