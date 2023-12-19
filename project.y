%{
	#include <stdio.h>
	#include <iostream>
	#include <string>
	#include "y.tab.h"
	using namespace std;
	extern FILE *yyin;
	extern int yylex();
	void yyerror(string s);
	extern int linenum;
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
	nextLine statements
	;

statements:
    statement NEXTLINE statements {cout << "statement 1" << " numberOfTab: " << numberOfTab << endl;}
    |
    statement {cout << "statement 2" << " numberOfTab: " << numberOfTab << endl;}
    |
    tabs nextLine statements {cout << "statement 3" << " numberOfTab: " << numberOfTab << endl;}
    |
    {cout << "statement 4" << " numberOfTab: " << numberOfTab << endl;}
    ;

statement:
    assignment
    {   
        cout << "number of tab: " << numberOfTab << " actual tab: " << actualTab << " at line: " << linenum << endl;
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
        cout << "number of tab: " << numberOfTab << " actual tab: " << actualTab << endl;
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
    tabs VAR EQ calculations { cout << "VAR:  " << $2 << endl; }
    ;

calculations:
    operand operator calculations
    |
    operand
    ;

control:
    ifControl statementOfIf statements
    |
    ifControl statementOfIf statements afterIfControl
    ;

ifControl:
    tabs IF comparible condition comparible COLON {actualTab++;}
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
    tabs ELIF comparible condition comparible COLON
    {
        if (numberOfTab != actualTab - 1){
            cerr << "Tab error at line : " << linenum << endl;
            exit(0);
        } 
    }
    ;

elseControl:
    tabs ELSE COLON
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
    TAB 
    |
    {cout << "There is not tab in line: " << linenum << endl; }
    ;

nextLine:
    NEXTLINE nextLine
    |
    NEXTLINE
    |
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