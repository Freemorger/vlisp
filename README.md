## Lisp dialect interpreter on V
It's pretty much simillar to common lisp in core syntax.
Docs will be out there (maybe).
## Build
```sh
# Clone repo:
https://github.com/Freemorger/vlisp.git
# Go to cloned repo directory:
cd vlisp
# Build it:
v -o vlisp src/ # add `-prod` for optimized build
# Finally, run it. (next block)
```
## Running
If you want enter interactive (REPL) mode:
```
./vlisp repl
```
If you want to run script from file:
```
./vlisp file test.lisp
```
