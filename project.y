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
    extern int numberOfTab;
    int actualTab = 0;
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
	;

statements:
    statement NEXTLINE statements {cout << "statement 1" << endl;}
    |
    statement {cout << "statement 2" << endl;}
    |
    {cout << "statement 4" << endl;}
    ;

statement:
    assignment
    {   
        if (numberOfTab > actualTab){
            cerr << "Tab error at line : " << linenum << endl;
            exit(0);
        }
        actualTab = numberOfTab;
    } 
    |
    control
    {
        if (numberOfTab > actualTab){
            cerr << "Tab error at line : " << linenum << endl;
            exit(0);
        }
        actualTab = numberOfTab;
    }
    ;

statementOfIf:
    assignment
    {
        if (numberOfTab != actualTab){
            cerr << "Tab error at line : " << linenum << endl;
            exit(0);
        }
    }
    |
    control
    {
        if (numberOfTab != actualTab){
            cerr << "Tab error at line : " << linenum << endl;
            exit(0);
        }
    }
    ;

assignment:
    VAR EQ calculations { cout << "VAR:  " << $1 << endl; }
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
    ifControl statementOfIf statements
    |
    ifControl statementOfIf statements afterIfControl
    ;

ifControl:
    IF comparible condition comparible COLON {actualTab++;}
    ;

afterIfControl:
    elifControl statementOfIf statements
    |
    elifControl statementOfIf statements elseControl statementOfIf statements
    |
    elifControl statementOfIf statements afterIfControl
    |
    elseControl statementOfIf statements
    ;

elifControl:
    ELIF comparible condition comparible COLON
    {
        if (numberOfTab != actualTab - 1){
            cerr << "Tab error at line : " << linenum << endl;
            exit(0);
        } 
    }
    ;

elseControl:
    ELSE COLON
    {
        if (numberOfTab != actualTab - 1){
            cerr << "Tab error at line : " << linenum << endl;
            exit(0);
        } 
    }
    ;

comparible:
    operand
    |
    VAR
    ;

operand:
    STRING { cout << "STRING:  " << $1 <<endl; }
    |
    INTEGER { cout << "INTEGER:  " << $1 <<endl; }
    |
    FLOAT { cout << "FLOAT:  " << $1 <<endl; }
    |
    VAR { cout << "VAR:  " << $1 <<endl; }
    ;

operator:
    SUM { cout << "+" <<endl; }
    |
    SUB { cout << "-" <<endl; }
    |
    MULT { cout << "*" <<endl; }
    |
    DIV { cout << "/" <<endl; }
    ;

condition:
    EQ EQ { cout << "==" <<endl; }
    |
    NEQ { cout << "!=" <<endl; }
    |
    BIGGER { cout << ">" <<endl; }
    |
    SMALLER { cout << "<" <<endl; }
    |
    BIGGER EQ { cout << ">=" <<endl; }
    |
    SMALLER EQ { cout << "<=" <<endl; }
    ;

tabs: 
    TAB {cout << "There are tabs in line: " << linenum << endl; }
    |
    {cout << "There is not tab in line: " << linenum << endl; }
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
