module main

pub fn (mut e AstEvaler) binary_op(handler fn (lhs AValue, rhs AValue) !AValue) ! {
	rhs := e.stack.pop();
	lhs := e.stack.pop();

	common := higher_common(lhs, rhs) or {
		return error("Expected numeric values, got LHS = ${lhs}, RHS = ${rhs}")
	};

	lhs_c := av_into_nt(lhs, common)!;
	rhs_c := av_into_nt(rhs, common)!;

	res := handler(lhs_c, rhs_c)!;

	e.stack << res;
}

fn op_add(lhs AValue, rhs AValue) !AValue {
    if lhs.type_name() != rhs.type_name() {
        return error('Type mismatch: cannot add ${lhs.type_name()} and ${rhs.type_name()}')
    }

    return match lhs {
        int {
            return lhs + (rhs as int)
        }
        f64 {
            return lhs + (rhs as f64)
        }
        string {
            return lhs + (rhs as string)
        }
		else {
			error("Unexpected lhs value ${lhs}")
		}
    }
}

fn op_sub(lhs AValue, rhs AValue) !AValue {
    if lhs.type_name() != rhs.type_name() {
        return error('Type mismatch: cannot sub ${lhs.type_name()} and ${rhs.type_name()}')
    }

    return match lhs {
        int {
            return lhs - (rhs as int)
        }
        f64 {
            return lhs - (rhs as f64)
        }
		else {
			error("Unexpected lhs value ${lhs}")
		}
    }
}

fn op_mul(lhs AValue, rhs AValue) !AValue {
    if lhs.type_name() != rhs.type_name() {
        return error('Type mismatch: cannot multiply ${lhs.type_name()} and ${rhs.type_name()}')
    }

    return match lhs {
        int {
            return lhs * (rhs as int)
        }
        f64 {
            return lhs * (rhs as f64)
        }
		else {
			error("Unexpected lhs value ${lhs}")
		}
    }
}

fn op_div(lhs AValue, rhs AValue) !AValue {
    if lhs.type_name() != rhs.type_name() {
        return error('Type mismatch: cannot divide ${lhs.type_name()} and ${rhs.type_name()}')
    }

    return match lhs {
        int {
            return lhs / (rhs as int)
        }
        f64 {
            return lhs / (rhs as f64)
        }
		else {
			error("Unexpected lhs value ${lhs}")
		}
    }
}
