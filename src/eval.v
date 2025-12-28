module main

struct AstEvaler {
mut:
    stack []AValue
}

/// retval bool - should_exit
pub fn (mut e AstEvaler) eval(ast_node AstNode) !bool {
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
                println("Could not sum ${left} and ${right}");
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
                println("Could not sub ${left} and ${right}");
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
                println("Could not mul ${left} and ${right}");
            }
        }
        .divide {
            e.eval(at_as_astn(ast_node.left))!;
            e.eval(at_as_astn(ast_node.right))!;
            
            left := e.stack.pop();
            right := e.stack.pop();
            
            if left is int && right is int {
                e.stack << right / left;
            } else {
                println("Could not div ${left} and ${right}");
            }
        }
        .print {
            e.eval(at_as_astn(ast_node.left))!;
            
            println("${e.stack.pop().as_str()}");
        }
        .exit {
            return true 
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
