module main
import cli
import os
import readline

fn main() {
	mut app := cli.Command {
		name: 'vlisp'
		description: 'Simple lisp interpreter written in Vlang'
		version: '0.0.4'
		execute: fn (cmd cli.Command) ! {
			println("Welcome to vlisp! Please specify command or run `vlisp help`");

		}
		commands: [
			cli.Command {
				name: 'file'
				description: 'Runs lisp program from specified file'
				usage: 'vlisp file <name>'
				required_args: 1
				execute: run_file
			}
			cli.Command {
				name: 'repl'
				description: 'Runs interactive (REPL) mode'
				execute: repl
			}
		]
	}

	app.setup();
	app.parse(os.args);
}

fn run_file(cmd cli.Command) ! {
	if cmd.args.len < 1 {
		eprintln("Usage: vlisp file file.lisp");
		return
	}
	fname := cmd.args[0];
	contents := os.read_file(fname)!;
	mut ast_ev := new_astev();

	toks := lex(contents);
	mut parser := Parser{toks: toks}
	asts := parser.parse_everything()!;

	for ast in asts {
		eres := ast_ev.eval(ast)!;
		if eres.exit || eres.had_error {
			break
		}
	}
}

fn repl(cmd cli.Command) ! {
	mut r := readline.Readline{}
	mut ast_ev := new_astev();

	for {
		inp := r.read_line(">> ") or { break }
		if inp.trim_space() == '' { continue }

		toks := lex(inp);

		mut parser := Parser{toks: toks}
		ast := parser.parse_everything()!;

		eres := ast_ev.eval(ast[0])!;

		if eres.exit {
			break
		}

		if ast_ev.stack.len > 0 {
			val := ast_ev.stack.last();
			if !(val is AstNode) {
				println("${val.as_str()}");
			}
		}
	}
}
