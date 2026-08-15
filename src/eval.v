module main

struct AstEvaler {
mut:
    stack []AValue
	vars  map[string]AValue
}

pub fn vlisp_error(line int, msg string) {
	eprintln("Error at line ${line}!\n\t${msg}")
}

/// retval bool - should_exit
pub fn (mut e AstEvaler) eval(ast_node AstNode) !bool {
	line := ast_node.line;
    match ast_node.atype {
        .intval {
            e.stack << ast_node.left
        }
        .strlit {
            e.stack << ast_node.left
        }
        .addition {
            e.eval(at_as_astn(ast_node.left))!;
            e.eval(at_as_astn(ast_node.right))!;


            left := e.stack.pop();
            right := e.stack.pop();

            if left is int && right is int {
                e.stack << right + left;
            } else if left is string && right is string {
                e.stack << right + left;
            } else {
                vlisp_error(line, "Could not sum ${left} and ${right}");
				return true
            }
        }
        .subtraction {
            e.eval(at_as_astn(ast_node.left))!;
            e.eval(at_as_astn(ast_node.right))!;

            left := e.stack.pop();
            right := e.stack.pop();

            if left is int && right is int {
                e.stack << right - left;
            } else {
                vlisp_error(line, "Could not sub ${left} and ${right}");
				return true
            }
        }
		.negation {
			e.eval(at_as_astn(ast_node.left))!;

			left := e.stack.pop();

			if left is int {
				e.stack << 0 - left // for some reason, c compilation fails
									// with just -left
			} else {
				vlisp_error(line, "Could not negate ${left}");
				return true
			}
		}
        .multiply {
            e.eval(at_as_astn(ast_node.left))!;
            e.eval(at_as_astn(ast_node.right))!;

            left := e.stack.pop();
            right := e.stack.pop();

            if left is int && right is int {
                e.stack << right * left;
            } else {
                vlisp_error(line, "Could not mul ${left} and ${right}");
				return true
            }
        }
        .divide {
            e.eval(at_as_astn(ast_node.left))!;
            e.eval(at_as_astn(ast_node.right))!;

            left := e.stack.pop();
            right := e.stack.pop();

            if left is int && right is int {
				if left == 0 {
					vlisp_error(line, "Could not divide by zero");
					return true
				}
                e.stack << right / left;
            } else {
                vlisp_error(line, "Could not div ${left} and ${right}");
				return true
            }
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

			if ast_node.atype == .setf && !(nm in e.vars) {
				vlisp_error(line, "Undefined: ${nm}");
				return true
			}
			if !(ast_node.atype == .defvar && nm in e.vars) {
				e.vars[nm] = val;
			}
		}
		.var {
			nm := ast_node.left.as_str();
			e.stack << e.vars[nm] or {
				vlisp_error(line, "Undefined: ${nm}");
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
