module main

struct AstEvaler {
mut:
    stack    []AValue
	vars     []map[string]AValue
	cur_nest int
}

pub fn vlisp_error(line int, msg string) {
	eprintln("Error at line ${line}!\n\t${msg}")
}

pub fn new_astev() AstEvaler {
	mut res := AstEvaler {};
	res.vars << map[string]AValue{};
	res.cur_nest = 0;
	return res;
}

pub fn (mut e AstEvaler) nest_vars() {
	e.vars 	 << map[string]AValue{};
	e.cur_nest += 1;
}

pub fn (mut e AstEvaler) pop_vars() {
	if e.cur_nest > 0 {
		e.vars.pop();
		e.cur_nest -= 1;
	}
}

/// Searches for var,
/// If present, returns true and nest level
/// If absent, returns false and 0
pub fn (mut e AstEvaler) is_var(name string) (bool, int) {
	for i := e.vars.len - 1; i >= 0; i-- {
		varmap := &e.vars[i]
		if name in varmap {
			return true, i
		}
	}
	return false, 0
}


/// retval bool - should_exit
pub fn (mut e AstEvaler) eval(ast_node AstNode) !bool {
	line := ast_node.line;
    match ast_node.atype {
        .intval, .floatval, .strlit {
            e.stack << ast_node.left
        }
        .addition {
            e.eval(at_as_astn(ast_node.left))!
            e.eval(at_as_astn(ast_node.right))!

			e.binary_op(op_add) or {
				vlisp_error(line, "${err.msg()}");
				return true
			};
        }
        .subtraction {
            e.eval(at_as_astn(ast_node.left))!
            e.eval(at_as_astn(ast_node.right))!

            e.binary_op(op_sub) or {
				vlisp_error(line, "${err.msg()}");
				return true
			};
        }
		.negation {
			e.eval(at_as_astn(ast_node.left))!

			left := e.stack.pop()

			match left {
				int { e.stack << 0-left } // C compilation will fail with just `-left`
				f64 { e.stack << 0-left }
				else {
					vlisp_error(line, 'Could not negate ${left}')
					return true
				}
			}
		}
        .multiply {
            e.eval(at_as_astn(ast_node.left))!
            e.eval(at_as_astn(ast_node.right))!

            e.binary_op(op_mul) or {
				vlisp_error(line, "${err.msg()}");
				return true
			};
        }
        .divide {
            e.eval(at_as_astn(ast_node.left))!
            e.eval(at_as_astn(ast_node.right))!

            e.binary_op(op_div) or {
				vlisp_error(line, "${err.msg()}");
				return true
			};
        }
        .print {
            e.eval(at_as_astn(ast_node.left))!;

            println("${e.stack.pop().as_str()}");
        }
        .exit {
            return true
        }
		.idt {
			e.stack << ast_node.left
		}
		.def, .defvar, .setf {
			e.eval(at_as_astn(ast_node.left))!;
			nm  := e.stack.pop().as_str();
			e.eval(at_as_astn(ast_node.right))!;
			val := e.stack.pop();

			present, _ := e.is_var(nm);
			if ast_node.atype == .setf && !(present) {
				vlisp_error(line, "Undefined: ${nm}");
				return true
			}
			if !(ast_node.atype == .defvar && present) {
				e.vars[e.cur_nest][nm] = val;
			}
		}
		.let {
			e.eval(at_as_astn(ast_node.left))!;
			val := e.stack.pop();
			nm  := e.stack.pop().as_str();

			e.nest_vars();
			e.vars[e.cur_nest][nm] = val;

			e.eval(at_as_astn(ast_node.right))!;

			e.pop_vars();
		}
		.nvbind {
			e.stack << ast_node.left;
			len_before := e.stack.len;
			e.eval(at_as_astn(ast_node.right))!;
			if len_before == e.stack.len {
				e.stack << AstNode {}
			}
		}
		.var {
			nm := ast_node.left.as_str();
			prsnt, nest := e.is_var(nm);
			if !prsnt {
				vlisp_error(line, "Undefined: ${nm}");
				e.stack << AstNode{};
				return true
			}

			e.stack << e.vars[nest][nm] or {
				vlisp_error(line, "Unreachable undefined: ${nm}");
				return true
			};
		}
        else {}
    }
    return false
}

fn at_as_astn(at AValue) AstNode {
    if at is AstNode {
        return at
    } else if at is int {
        return AstNode {
            atype: AstN.intval
            left: at
        }
    } else if at is string {
        return AstNode {
            atype: AstN.strlit
            left: at
        }
    }
    panic("unreachable at at_as_astn")
}
