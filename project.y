%{
	#include <stdio.h>
	#include <iostream>
	#include <string>
	#include <string.h>
    #include <vector>

	using namespace std;
	#include "y.tab.h"
	extern FILE *yyin;
	extern int yylex();
	void yyerror(string s);

	extern int linenum;
    extern int numberOfTab;

    int actualTab = 0;
    int lastControlLine = -1;

    struct Variable 
    {
        string name;
		int intVal;
        int floatVal;
        int stringVal;
        string currentType;
    };
    vector<Variable> listOfVariable;

    vector<string> operandTypes;

    struct Statement 
    {
        string type;
		int startLine;
        int tabCount;
    };
    vector<Statement> listOfStatement;

    void displayInfo(){
        cout << "Line: " << linenum << " actualTab: " << actualTab << " numberOfTab: " << numberOfTab << " lastControlLine: "<< lastControlLine << endl;
    }

    void afterControlStateTabCheck(int linenum, int lastControlLine, int actualTab, int numberOfTab){
        if (linenum == lastControlLine+1 && actualTab != numberOfTab){
            cerr << "Must be at least one statement after control statement" << endl;
            cerr << "Tab error at line: " << linenum << endl;
            exit(1);
        }
    }

    void addNewStatement(string type, int startLine, int tabCount){
        Statement newStatement;
        newStatement.type = type;
        newStatement.startLine = startLine;
        newStatement.tabCount = tabCount;
        listOfStatement.push_back(newStatement);
    }

    void checkStatementConsistency(){
        int size = listOfStatement.size();
        Statement lastStatement = listOfStatement[size-1];
        string type = lastStatement.type;
        int startLine = lastStatement.startLine;
        int tabCount = lastStatement.tabCount;

        if(type == "if"){
            if(tabCount != actualTab){
                cerr << "Tab error at line: " << startLine << endl;
                exit(1);
            }
            else{
                return;
            }
        }

        if(size == 1 && (type == "elif" || type == "else")){
            cerr << "1) if/else consistency in line: " << startLine << endl;
            exit(1);
        }

        if(listOfStatement[size-2].type == "assignment" && listOfStatement[size-2].tabCount == tabCount && type != "if"){
            cerr << "2) if/else consistency in line: " << startLine << endl;
            exit(1);
        }

        int checkCount = 0;
        int lastMatchedIf = -1;
        int lastMatchedElse = -1;
        int checkIf = 0;
        int checkElse = 0;

        for(int i=size-2; i>=0; i--){
            if(listOfStatement[i].tabCount == tabCount){
                checkCount = 1;
                if(listOfStatement[i].type == "if" && checkIf == 0){
                    lastMatchedIf = listOfStatement[i].startLine;
                    checkIf = 1;
                }
                else if(listOfStatement[i].type == "else" && checkElse == 0){
                    lastMatchedElse = listOfStatement[i].startLine;
                    checkElse = 1;
                }
            }
        }

        if(lastMatchedIf == -1 || lastMatchedElse > lastMatchedIf){
            cerr << "3) if/else consistency in line: " << startLine << endl;
            exit(1);
        }

        if (checkCount == 0){
            cerr << "4) if/else consistency in line: " << startLine << endl;
            exit(1);
        }
    }

    string findVariableType(string varName){
        for(int i=0; i<listOfVariable.size(); i++){
            if(listOfVariable[i].name == varName){
                return listOfVariable[i].currentType;
            }
        }
        return "undeclared";
    }

    void addNewVariable(string varName, string currentType){
        int intVal = 0;
        int floatVal = 0;
        int stringVal = 0;

        if(currentType == "intiger"){
            intVal = 1;
        }
        else if(currentType == "float"){
            floatVal = 1;
        }
        else{
            stringVal = 1;
        }

        Variable newVar;
        newVar.name = varName;
        newVar.intVal = intVal;
        newVar.floatVal = floatVal;
        newVar.stringVal = stringVal;
        newVar.currentType = currentType;
        listOfVariable.push_back(newVar);
    }

    void updateVariable(string varName, string type){
        for(int i=0; i<listOfVariable.size(); i++){
            if(listOfVariable[i].name == varName){
                listOfVariable[i].currentType = type;

                if(type == "intiger"){
                    listOfVariable[i].intVal = 1;
                }
                else if(type == "float"){
                    listOfVariable[i].floatVal = 1;
                }
                else{
                    listOfVariable[i].stringVal = 1;
                }
            }
        }
        addNewVariable(varName, type);
    }

%}

%union {
    char* str_val;
    int int_val;
    float float_val;
    char* var_val;
}

%token <str_val> STRING
%token <str_val> INTEGER
%token <str_val> FLOAT
%token <str_val> VAR
%token <str_val> IF <str_val> ELIF <str_val> ELSE
%token <str_val> SUM <str_val> SUB <str_val> MULT <str_val> DIV
%token <str_val> EQ <str_val> NEQ <str_val> BIGGER <str_val> SMALLER
%token <str_val> COLON
%token TAB NEXTLINE

%type<str_val> assignment
%type<str_val> rightAssignment
%type<str_val> operand
%type<str_val> operator
%type<str_val> condition

%type<str_val> controlStatement
%type<str_val> ifContol
%type<str_val> elifControl
%type<str_val> elseControl

%%

program:
    statements
    |
    ;

statements:
    statement statements
    |
    statement
    ;

statement:
    assignment
    {
        cout << $1 << endl;
        displayInfo();

        afterControlStateTabCheck(linenum, lastControlLine, actualTab, numberOfTab);

        if (actualTab > 0){
            actualTab = numberOfTab;
        }

        else if (actualTab == 0 && actualTab != numberOfTab){
            cerr << "Tab error at line: " << linenum << endl;
            exit(1);
        }

        addNewStatement("assignment", linenum, actualTab);
    }
    |
    controlStatement
    {
        cout << $1 << endl;

        lastControlLine = linenum;

        displayInfo();
    }
    |
    NEXTLINE
    {
        numberOfTab = 0;
    }
    ;

assignment:
    VAR EQ rightAssignment 
    { 
        string combined = string($1) + string($2) + string($3);
		$$ = strdup(combined.c_str());

        string typeOfVar = operandTypes.back();
        operandTypes.clear();

        updateVariable($1, typeOfVar);

        string type = findVariableType($1);
        cout << "varName: " << $1 << " type: " <<  type <<endl;


    }
    |
    TAB assignment
    { 
        $$ = $2; 
    }
    ;

rightAssignment:
    operand operator rightAssignment
    { 
        string combined = string($1) + string($2) + string($3);
		$$ = strdup(combined.c_str());

        string lastOperand_1 = operandTypes.back();
        operandTypes.pop_back();
        string lastOperand_2 = operandTypes.back();
        operandTypes.pop_back();  

        if (lastOperand_1 == "string" && lastOperand_2 == "string"){
            operandTypes.push_back("string");
        }
        
        else if ((lastOperand_1 == "string" && lastOperand_2 != "string") || (lastOperand_2 == "string" && lastOperand_1 != "string")){
            cerr << "Type inconsistency in line: " << linenum << endl;
            exit(1);
        }

        else if (lastOperand_1 == "float" || lastOperand_2 == "float"){
            operandTypes.push_back("float");
        }
        
        else{
            operandTypes.push_back("intiger");
        }

    }
    |
    operand
    { $$ = $1; }
    ;

controlStatement:
    ifContol
    {
        $$ = $1;

        afterControlStateTabCheck(linenum, lastControlLine, actualTab, numberOfTab);
        addNewStatement("if", linenum, actualTab);
        checkStatementConsistency();
        actualTab++;

    }
    |
    elifControl
    {
        $$ = $1;

        afterControlStateTabCheck(linenum, lastControlLine, actualTab, numberOfTab);
        addNewStatement("elif", linenum, actualTab-1);
        checkStatementConsistency();
    }
    |
    elseControl
    {
        $$ = $1;

        afterControlStateTabCheck(linenum, lastControlLine, actualTab, numberOfTab);
        addNewStatement("else", linenum, actualTab-1);
        checkStatementConsistency();
    }
	;

ifContol: 
	IF operand condition operand COLON
    { 
        string combined = string($1) + " " + string($2) + string($3) + string($4) + string($5);
		$$ = strdup(combined.c_str());
    }
    |
    TAB ifContol
    { $$ = $2; }
    ;

elifControl: 
    ELIF operand condition operand COLON
    { 
        string combined = string($1) + " " + string($2) + string($3) + string($4) + string($5);
		$$ = strdup(combined.c_str());
    }
    |
    TAB elifControl
    { $$ = $2; }
    ;

elseControl: 
    ELSE COLON
    { 
        string combined = string($1) + string($2);
		$$ = strdup(combined.c_str());
    }
    |
    TAB elseControl
    { $$ = $2; }
    ;

operand:
    STRING { 
        $$ = $1; 
        operandTypes.push_back("string");
    }
    |
    INTEGER { 
        $$ = $1; 
        operandTypes.push_back("integer");
    }
    |
    FLOAT { 
        $$ = $1; 
        operandTypes.push_back("float");
    }
    |
    VAR {
        $$ = $1;
        string type = findVariableType($1);
        if(type == "undeclared"){
            cerr << $1 << " is undeclared in line: " << linenum << endl;
        }
        operandTypes.push_back(type);
    }
    ;

operator:
    SUM { $$ = $1; }
    |
    SUB { $$ = $1; }
    |
    MULT { $$ = $1; }
    |
    DIV { $$ = $1; }
    ;

condition:
    EQ EQ { $$ = $1; }
    |
    NEQ { $$ = $1; }
    |
    BIGGER { $$ = $1; }
    |
    SMALLER { $$ = $1; }
    |
    BIGGER EQ { $$ = $1; }
    |
    SMALLER EQ { $$ = $1; }
    ;

%%

void yyerror(string s){
	cerr<<"Error at line: "<<linenum<<endl;
}

int yywrap(){
	return 1;
}

int main(int argc, char *argv[]){
    yyin=fopen(argv[1],"r");
    yyparse();
    fclose(yyin);
    return 0;
}