letter [A-Za-z]
digit [0-9]

%{
  #include <stdio.h>
  #include <string.h>
  #include "y.tab.h"
  #include <iostream>
  using namespace std;
  int linenum = 1;
  int numberOfTab = 0;
%}
%%

":" {yylval.str_val = strdup(yytext); return COLON;}

"+" {yylval.str_val = strdup(yytext); return SUM;}
"-" {yylval.str_val = strdup(yytext); return SUB;}
"*" {yylval.str_val = strdup(yytext); return MULT;}
"/" {yylval.str_val = strdup(yytext); return DIV;}

"if" {yylval.str_val = strdup(yytext); return IF;}
"elif" {yylval.str_val = strdup(yytext); return ELIF;}
"else" {yylval.str_val = strdup(yytext); return ELSE;}

"=" {yylval.str_val = strdup(yytext); return EQ;}
"!=" {yylval.str_val = strdup(yytext); return NEQ;}
">" {yylval.str_val = strdup(yytext); return BIGGER;}
"<" {yylval.str_val = strdup(yytext); return SMALLER;}

\"([^\"\\]|\\.)*\" { yylval.str_val = strdup(yytext); return STRING; }
0|([-]?[1-9]{digit}*) { yylval.str_val = strdup(yytext); return INTEGER; }
(0|([-]?[1-9]{digit}*))([.]{digit}*)? { yylval.str_val = strdup(yytext); return FLOAT; }
{letter}({digit}|{letter}|[_])* { yylval.str_val = strdup(yytext); return VAR; }

\n {linenum++; return NEXTLINE;}
^([ \t]*) {numberOfTab = yyleng/4; cout<<"tab: " << numberOfTab << endl; return TAB;}

.
%%