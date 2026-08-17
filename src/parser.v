module main

struct Parser {
    toks []Token
mut:
    pos int
    cur_line int
	fold_lvl int
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

fn (mut p Parser) expect_idt(toks []Token) !AstNode {
	if p.pos >= toks.len {
        return error("Unexpected EOF\n")
    }

    cur := toks[p.pos];
    match cur.ttype {
		.idt {
			p.pos += 1;
			return AstNode {
				atype: AstN.idt
				left:  tv_to_av(cur.value)
				line: cur.line
			}
		}
		else {
			panic("Expected identifier, found ${cur}");
		}
	}
    return error("Unexpected ${cur}")
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
					"neg" {
						left := p.parse_expr(toks)!;

						return AstNode {
							atype: AstN.negation
							left: left
							line: cur.line
						}
					}
                    "print" {
                        left := p.parse_expr(toks)!;

                        return AstNode {
                            atype: AstN.print
                            left: left
							line: cur.line
                        }
                    }
                    "exit" {
                        return AstNode {
                            atype: AstN.exit
							line: cur.line
                        }
                    }
					"def", "defvar", "setf" {
						name := p.expect_idt(toks)!;
						val  := p.parse_expr(toks)!;

						atp := match cur.value {
							"def" 	 {AstN.def}
							"defvar" {AstN.defvar}
							"setf" 	 {AstN.setf}
							else {
								panic("Internal error: got curval ${cur.value}")
							}
						};

						return AstNode {
							atype: atp
							left:  name
							right: val
							line:  cur.line
						}
					}
					"let" {
						nvbind 	  := p.parse_nmvalbind(toks)!;
						rhs       := p.parse_expr(toks)!;

						return AstNode {
							atype: AstN.let
							left:  nvbind
							right: rhs
							line:  cur.line
						}
					}
                    else {}
                }
            }
        }
		.idt {
			p.pos += 1;
			return AstNode {
				atype: AstN.var
				left:  tv_to_av(cur.value)
				line:  cur.line
			}
		}
    	.lpar {
            p.pos += 1;
			last_fold_lvl := p.fold_lvl;
			p.fold_lvl += 1;

            expr := p.parse_expr(toks)!;

			is_rpar := p.pos < toks.len && toks[p.pos].ttype == Tok.rpar;
			if last_fold_lvl != p.fold_lvl && !is_rpar {
				println("While parsing ${expr}:");
				if p.pos < toks.len {
					return error("Expected `)`, found EOF")
				}
				return error("Fold level mismatch: expected ${last_fold_lvl},\
					found ${p.fold_lvl}")
            }

            p.pos += 1;
            return expr
        }
        .rpar {
            return AstNode {
				line: cur.line
            }
        }
        .intval {
            p.pos += 1;
            return AstNode {
                atype: AstN.intval
                left: tv_to_av(cur.value)
				line: cur.line
            }
        }
		.floatval {
			p.pos += 1;
			return AstNode {
				atype: AstN.floatval
				left:  tv_to_av(cur.value)
				line:  cur.line
			}
		}
        .strlit {
            p.pos += 1;
            return AstNode {
                atype: AstN.strlit
                left: tv_to_av(cur.value)
				line: cur.line
            }
        }
        .plus {
            p.pos += 1;
            left := p.parse_expr(toks)!;
            right := p.parse_expr(toks)!;

            return AstNode {
                atype: AstN.addition
                left:  left
                right: right
				line:  cur.line
            }
        }
		.minus {
			p.pos += 1;
			left := p.parse_expr(toks)!;
			right := p.parse_expr(toks)!;

			return AstNode {
				atype: AstN.subtraction
				left:  left
				right: right
				line:  cur.line
			}
		}
        .asterisk {
            p.pos += 1;
            left := p.parse_expr(toks)!;
            right := p.parse_expr(toks)!;

            return AstNode {
                atype: AstN.multiply
                left:  left
                right: right
				line:  cur.line
            }
        }
        .slash {
            p.pos += 1;
            left := p.parse_expr(toks)!;
            right := p.parse_expr(toks)!;

            return AstNode {
                atype: AstN.divide
                left:  left
                right: right
				line:  cur.line
            }
        }
        // else {}
    }
    return error("Unexpected ${cur}")
}

fn (mut p Parser) peek() !Token {
    if p.pos + 1 >= p.toks.len {
        return error("Peek is over bounds\n")
    }
    return p.toks[p.pos + 1]
}

fn (mut p Parser) expect(ttype Tok) ! {
	if p.pos + 1 >= p.toks.len {
		return error("Expect is out of bounds\n");
	}
	cur   := p.toks[p.pos];
	p.pos += 1;
	if cur.ttype != ttype {
		return error("Expected ${ttype}, got ${cur.ttype}");
	}
}

/// Parse a name-value bind, e.g. `(x 15)`
fn (mut p Parser) parse_nmvalbind(toks []Token) !AstNode {
	p.expect(.lpar)!;

	nm   := p.expect_idt(toks)!;
	line := nm.line;

	rhs := p.parse_expr(toks)!;

	p.expect(.rpar)!;

	return AstNode {
		atype: .nvbind
		left:  nm
		right: rhs
		line:  line
	}
}

fn tv_to_av(tv TValue) AValue {
	return match tv {
		int, f64, string { tv }
		// else { 0 }
	}
}


pub type AValue = AstNode | int | f64 | string
pub fn (av AValue) as_str() string {
    match av {
        int {return av.str()}
		f64 {return av.str()}
        string {return av}
        AstNode {match av.atype {
			.idt {
				return av.left.as_str();
			}
			.strlit {
				return av.left.as_str();
			}
			else {
				return av.str();
			}
		}}
    }
}

pub struct AstNode {
    atype AstN
    left AValue
    right AValue
	line int
}

pub enum AstN {
    none
    breakexpr
    exit

    print

    intval
	floatval
    strlit

	idt
	var

    addition
    subtraction
	negation
    multiply
    divide

	def
	defvar
	setf
	let

	nvbind // name-value bind
}
