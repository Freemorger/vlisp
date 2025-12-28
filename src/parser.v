module main

struct Parser {
    toks []Token
mut:
    pos int 
    cur_line int 
}

pub fn (mut p Parser) parse_everything() ![]AstNode {
    mut res := []AstNode{}

    for p.pos < p.toks.len {
        if p.toks[p.pos].ttype == .rpar {
            break  
        }

        p.cur_line = p.toks[p.pos].line;
        expr := p.parse_expr(p.toks)!;
        res << expr 
        if expr.atype == AstN.breakexpr {
            break
        }
    }

    return res
}

fn (mut p Parser) parse_expr(toks []Token) !AstNode {
    return p.parse_prefix(toks)
}

fn (mut p Parser) parse_prefix(toks []Token) !AstNode {
    if p.pos >= toks.len {
        return error("Unexpected EOF\n")
    }

    cur := toks[p.pos];
    match toks[p.pos].ttype {
        .keyword {
            p.pos += 1;
            if cur.value is string {
                match cur.value {
                    "print" {
                        left := p.parse_expr(toks)!;

                        return AstNode {
                                atype: AstN.print
                                left: left
                        }
                    }
                    "exit" {
                        return AstNode {
                            atype: AstN.exit
                        }
                    }
                    else {}
                }
            }
        }
        .lpar {
            p.pos += 1;
            
            expr := p.parse_expr(toks)!;
            
            if !((p.pos < toks.len) && (toks[p.pos].ttype == Tok.rpar)) {
                return error("Expected `)`, got ${toks[p.pos]}")
            }

            p.pos += 1;
            return expr
        }
        .rpar {
            return AstNode {
            }
        }
        .intval {
            p.pos += 1;
            return AstNode {
                atype: AstN.intval
                left: tv_to_av(cur.value)
            }
        }
        .strlit {
            p.pos += 1;
            return AstNode {
                atype: AstN.strlit 
                left: tv_to_av(cur.value)
            }
        }
        .plus {
            p.pos += 1;
            left := p.parse_expr(toks)!;
            right := p.parse_expr(toks)!;
            
            return AstNode {
                atype: AstN.addition
                left: left 
                right: right
            }
        }
        .asterisk {
            p.pos += 1;
            left := p.parse_expr(toks)!;
            right := p.parse_expr(toks)!;
            
            return AstNode {
                atype: AstN.multiply
                left: left 
                right: right
            }
        }
        .slash {
            p.pos += 1;
            left := p.parse_expr(toks)!;
            right := p.parse_expr(toks)!;
            
            return AstNode {
                atype: AstN.divide
                left: left 
                right: right
            }
        }


        else {} 
    }
    return error("Unexpected ${cur}")
}

fn (mut p Parser) peek() !Token {
    if p.pos + 1 >= p.toks.len {
        return error("Peek is over bounds\n")
    }
    return p.toks[p.pos + 1]
}

fn tv_to_av(tv TValue) AValue {
    if tv is int {
        return tv
    } else if tv is string {
        return tv
    }
    return 0 // unreachable
}

pub type AValue = AstNode | int | string
pub fn (av AValue) as_str() string {
    match av {
        int {return av.str()}
        string {return av}
        else {return "$av"}
    }
}

pub struct AstNode {
    atype AstN 
    left AValue
    right AValue
}

pub enum AstN {
    none
    breakexpr
    exit

    print

    intval
    strlit

    addition
    subtraction
    multiply
    divide
}
