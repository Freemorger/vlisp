module main
import strconv

pub enum Tok {
	keyword

	intval
	strlit

	lpar
	rpar
	plus
	minus
	asterisk
	slash

	idt
}

pub type TValue = int | string

pub struct Token {
pub:
	ttype Tok
	line int
	value TValue
}

pub fn lex(input string) []Token {
	mut res := []Token{}
	mut line_ctr := 1;
	mut pos := 0;
	n := input.len;

	for pos < n {
		ch := input[pos];
		match ch {
			` ` {
				pos += 1;
				continue
			}
			`\n` {
				line_ctr = line_ctr + 1;
				pos += 1;
			}
			`(` {
				res << Token{ttype: Tok.lpar, line: line_ctr}
				pos += 1;
			}
			`)` {
				res << Token{ttype: Tok.rpar, line: line_ctr}
				pos += 1;
			}
			`+` {
				res << Token{ttype: Tok.plus, line: line_ctr}
				pos += 1;
			}
			`-` {
				if (pos + 1) < input.len && input[pos + 1].is_digit() {
					start := pos + 1;
					mut end := pos;
					for end < input.len {
						end += 1;
						if !input[end].is_digit() {
							break
						}
					}
					num_s := "-${input[start..end]}";
					res_n := num_s.int();

					res << Token{ttype: Tok.intval, value: res_n, line: line_ctr}
					pos = end;
				} else {
					res << Token{ttype: Tok.minus, line: line_ctr}
					pos += 1;
				}
			}
			`*` {
				res << Token{ttype: Tok.asterisk, line: line_ctr}
				pos += 1;
			}
			`/` {
				res << Token{ttype: Tok.slash, line: line_ctr}
				pos += 1;
			}
			`"` {
				start := pos;
				pos += 1;
				for pos < n && input[pos] != `"` {
					if input[pos] == `\n` {
						line_ctr += 1;
					}
					pos += 1;
				}
				if pos >= n {
					break
				}
				literal := input[start + 1..pos];
				res << Token{ttype: Tok.strlit, value: literal, line: line_ctr}
				pos += 1;
			}
			else {
				start := pos;
				for pos < n && !is_whitespace(input[pos]) && input[pos] != `(` && input[pos] != `)` {
					pos += 1;
				}
				word := input[start..pos];

				intv := strconv.atoi(word) or {
					res << try_kword(word, line_ctr)
					continue
				}
				res << Token{ttype: Tok.intval, value: intv, line: line_ctr}
			}
		}
	}
	return res
}

fn is_whitespace(ch u8) bool {
	return ch == ` ` || ch == `\t` || ch == `\n` || ch == `\r`
}

fn try_kword(s string, line int) Token {
	return match s {
		"neg" {Token{ttype: Tok.keyword, value: s}}
		"print" {Token{ttype: Tok.keyword, value: s}}
		"exit" {Token{ttype: Tok.keyword, value: s}}
		else {Token{ttype: Tok.idt, value: s}}
	}
}
