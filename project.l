letter [A-Za-z]
digit [0-9]

%{
  #include <stdio.h>
  #include <string.h>
  #include "y.tab.h"
  #include <iostream>
  using namespace std;
  int linenum=1;
  int numberOfTab = 0;
%}
%%

^[ \t]+ { 
  cout << "Tab found at Line: " << linenum << " yyleng: " << yyleng <<endl;
  numberOfTab = yyleng; 
  return TAB; 
}
[ \t]+ {cout << "Space at line: " << linenum << " yyleng: " << yyleng << endl;}
[\n] { 
  numberOfTab = 0;
  linenum++; 
  return NEXTLINE; 
}


":" return COLON;

"+" return SUM;
"-" return SUB;
"*" return MULT;
"/" return DIV;

"if" return IF;
"elif" return ELIF;
"else" return ELSE;

"=" return EQ;
"!=" return NEQ;
">" return BIGGER;
"<" return SMALLER;

\"([^\"\\]|\\.)*\" { yylval.str_val = strdup(yytext); return STRING; }
0|([-]?[1-9]{digit}*) { yylval.int_val = atoi(yytext); return INTEGER; }
(0|([-]?[1-9]{digit}*))([.]{digit}*)? { yylval.float_val = atof(yytext); return FLOAT; }
{letter}({digit}|{letter}|[_])* { yylval.var_val = strdup(yytext); return VAR; }

.
%%
