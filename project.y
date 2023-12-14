%{
	#include <stdio.h>
	#include <iostream>
	#include <string>
	#include "y.tab.h"
	using namespace std;
	extern FILE *yyin;
	extern int yylex();
	void yyerror(string s);
	extern int linenum;// use variable linenum from the lex file
%}

%union {
    char* str_val;
    int int_val;
    float float_val;
    char* var_val;
}

%token <str_val> STRING
%token <int_val> INTEGER
%token <float_val> FLOAT
%token <var_val> VAR
%token COLON SUM SUB MULT DIV IF ELIF ELSE EQ NEQ BIGGER SMALLER TAB NEXTLINE

%%

program:
	statements
    |
	;

statements:
    statement statements { cout << "statement + statements" << endl; }
    |
    statement { cout << "statement" << endl; }
    ;

statement:
    assignment
    |
    control
    ;

assignment:
    VAR EQ calculations { cout << "Var value: " << $1 << endl; }
    ;

calculations:
    calculation calculations
    |
    calculation
    ;

calculation:
    operand operator
    |
    operand
    ;

control:
    ifControl { cout << "if" << endl; }
    |
    ifControl afterIfControl { cout << "if + afterIf" << endl; }
    ;

ifControl:
    IF comparible condition comparible COLON statements
    ;

afterIfControl:
    elifControl { cout << "elif" << endl; }
    |
    elifControl elseControl { cout << "elif + else" << endl; }
    |
    elifControl afterIfControl { cout << "elif + after" << endl; }
    |
    elseControl { cout << "else" << endl; }
    ;

elifControl:
    ELIF comparible condition comparible COLON statements
    ;

elseControl:
    ELSE COLON statements
    ;

comparible:
    operand
    |
    VAR
    ;

operand:
    STRING { cout << "String value: " << $1 << endl; }
    |
    INTEGER { cout << "Integer value: " << $1 << endl; }
    |
    FLOAT { cout << "Float value: " << $1 << endl; }
    |
    VAR { cout << "Var value: " << $1 << endl; }
    ;

operator:
    SUM
    |
    SUB
    |
    MULT
    |
    DIV
    ;

condition:
    EQ EQ
    |
    NEQ
    |
    BIGGER
    |
    SMALLER
    |
    BIGGER EQ
    |
    SMALLER EQ
    ;

%%
void yyerror(string s){
	cerr<<"Error at line: "<<linenum<<endl;
}
int yywrap(){
	return 1;
}
int main(int argc, char *argv[])
{
    /* Call the lexer, then quit. */
    yyin=fopen(argv[1],"r");
    yyparse();
    fclose(yyin);
    return 0;
}
