module main
import cli
import os

fn main() {
	mut app := cli.Command {
		name: 'vlisp'
		description: 'Simple lisp interpreter written in Vlang'
		version: '0.0.0'
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
	lines := os.read_lines(fname)!;

	for line in lines {
		toks := lex(line.trim_space());

		mut parser := Parser{toks: toks}
		ast := parser.parse_everything()!;

		mut ast_ev := AstEvaler{};
		ast_ev.eval(ast[0])!;
	}
}

fn repl(cmd cli.Command) ! {
	for true {
		inp := os.input('>> ');

		toks := lex(inp);

		mut parser := Parser{toks: toks}
		ast := parser.parse_everything()!;

		mut ast_ev := AstEvaler{};
		should_exit := ast_ev.eval(ast[0])!;

		if should_exit {
			break
		}
	}
}
