all: lex yacc 
	g++ lex.yy.c y.tab.c -ll -o project

run: project
	./project input.txt>output.txt

yacc: project.y
	yacc -d -v project.y

lex: project.l
	lex project.l

clean: lex.yy.c y.tab.c project y.tab.h
	rm lex.yy.c y.tab.c project y.tab.h

invalid: project
	./project invalid_inputs/invalid1.txt>output.txt
	./project invalid_inputs/invalid2.txt>output.txt
	./project invalid_inputs/invalid3.txt>output.txt
	./project invalid_inputs/invalid4.txt>output.txt
	./project invalid_inputs/invalid5.txt>output.txt
	./project invalid_inputs/invalid6.txt>output.txt
	./project invalid_inputs/invalid7.txt>output.txt
	./project invalid_inputs/invalid8.txt>output.txt

valid: project
	./project valid_inputs/valid1.txt>output.txt
	./project valid_inputs/valid2.txt>output.txt
	./project valid_inputs/valid3.txt>output.txt