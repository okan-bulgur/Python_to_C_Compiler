%{
	#include <stdio.h>
	#include <iostream>
	#include <string>
	#include <string.h>
    #include <vector>
    #include <map>
	#include "y.tab.h"

	using namespace std;
	extern FILE *yyin;
	extern int yylex();
	void yyerror(string s);

	extern int linenum;
    extern int numberOfTab;

    int actualTab = 0;
    int lastControlLine = -1;
    int prevActualTab = 0;
    string bodyPart;

    struct Variable 
    {
        string name;
        string currentType;
    };

    struct Statement 
    {
        string type;
		int startLine;
        int tabCount;
    };

    map<int, vector<Variable> > listOfVariable;
    map<string, vector<string> > listOfTypes;

    vector<string> operandTypes;
    vector<Statement> listOfStatement;

    string closeParanthesis(int prevActualTab, int numberOfTab){
        string closeBracket;
        if(prevActualTab > numberOfTab){
            int tmp = prevActualTab;
            while(tmp > numberOfTab){
                int count = tmp-1;
                string tabCombine = "\t";
                for(int i=0; i<count; i++){
                    tabCombine += "\t";
                }
                closeBracket += tabCombine + "}\n";
                tmp--;
            }
        }
        return closeBracket;
    }

    string getStatementPartSring(string val, int numberOfTab, int prevActualTab){
        string tabCombine = "\t";
        for(int i=0; i<numberOfTab; i++){
            tabCombine += "\t";
        }

        string closeBracket = closeParanthesis(prevActualTab, numberOfTab);      

        string combined = closeBracket + tabCombine + string(val);
        return combined;
    }

    string getDeclarePartString(){
        string str = "\t";
        for (const auto& pair : listOfTypes) {
            if(pair.first == "flt"){
                str += "float ";
            }
            else if(pair.first == "str"){
                str += "string ";
            }
            else{
                str += "int ";
            }
            vector<string> list = listOfTypes[pair.first];
            for(string var : list){
                str += var + "_" + pair.first + ",";
            }
            str.pop_back();
            str += ";\n\t";
        }
        str.pop_back();
        str += "\n";
        return str;
    }

    void clearListForVariableList(int tabCount){
        if (listOfVariable.find(tabCount) != listOfVariable.end()){
            listOfVariable[tabCount].clear();
        }
    }

    void afterControlStateTabCheck(int linenum, int lastControlLine, int actualTab, int numberOfTab){
        if (linenum == lastControlLine+1 && actualTab != numberOfTab){
            cerr << "there is a tab inconsistency in line " << linenum << endl;
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

        if(size > 1 && type == "assignment"){
            string prevType = listOfStatement[size-2].type;
            int prevTabCount = listOfStatement[size-2].tabCount;
            if((prevType == "if" || prevType == "elif" || prevType == "else") && (tabCount != prevTabCount+1)){
                cerr << "there is a tab inconsistency in line " << startLine << endl;
                exit(1);
            }
        }

        if(type == "if"){
            if(tabCount != actualTab){
                cerr << "there is a tab inconsistency in line " << startLine << endl;
                exit(1);
            }
            else{
                return;
            }
        }

        if(size == 1 && (type == "elif" || type == "else")){
            cerr << "if/else consistency in line " << startLine << endl;
            exit(1);
        }

        if(type == "elif" || type == "else"){
            int check = 0;
            for(int i=size-2 ; i>=0 ; i--){
                if(listOfStatement[i].type == "if" && tabCount == listOfStatement[i].tabCount){
                    check = 1;
                    break;
                }
            }

            if(check == 0){
                cerr << "if/else consistency in line " << startLine << endl;
                exit(1);
            }
        }

        if(type != "assignment"){
            int checkCount = 0;
            int lastMatchedIf = -1;
            int lastMatchedElse = -1;
            int lastMatchedAssignment = -1;
            int checkIf = 0;
            int checkElse = 0;
            int checkAssignment = 0;

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
                    else if(listOfStatement[i].type == "assignment" && checkAssignment == 0){
                        lastMatchedAssignment = listOfStatement[i].startLine;
                        checkAssignment = 1;
                    }
                }
            }

            if(lastMatchedIf == -1 || lastMatchedElse > lastMatchedIf || lastMatchedAssignment > lastMatchedIf){
                cerr << "if/else consistency in line " << startLine << endl;
                exit(1);
            }

            if (checkCount == 0){
                cerr << "b if/else consistency in line " << startLine << endl;
                exit(1);
            }
        }
    }

    void controlLastStatement(){
        int size = listOfStatement.size();
        Statement lastStatement = listOfStatement[size-1];
        string type = lastStatement.type;
        int startLine = lastStatement.startLine;
        
        if(type != "assignment"){
            cerr << "there is a tab inconsistency in line " << startLine << endl;
            exit(1);
        }
    }

    void addTypeList(string varName, string type){
        
        for(int i=0; i<listOfTypes[type].size(); i++){
            if(varName.compare(listOfTypes[type][i]) == 0){
                return;
            }
        }
        listOfTypes[type].push_back(varName);
    }

    string findVariableType(string varName, int tabCount){

        while(tabCount >= 0){
            for(int i=0; i<listOfVariable[tabCount].size(); i++){
                if(listOfVariable[tabCount][i].name == varName){
                    return listOfVariable[tabCount][i].currentType;
                }
            }
            tabCount--;
        }
        return "undeclared";
    }

    void addNewVariable(string varName, string currentType, int tabCount){

        Variable newVar;
        newVar.name = varName;
        newVar.currentType = currentType;

        listOfVariable[tabCount].push_back(newVar);
    }

    void updateVariable(string varName, string type, int tabCount){
        for(int i=0; i<listOfVariable[tabCount].size(); i++){
            if(listOfVariable[tabCount][i].name == varName){
                listOfVariable[tabCount][i].currentType = type;
                return;
            }
        }
        addNewVariable(varName, type, tabCount);
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
    {
        controlLastStatement();
        string result = "void main()\n{\n";
        string declarePart = getDeclarePartString();
        result += declarePart;
        result += bodyPart;
        if(actualTab != 0){
            actualTab = 0;
            result += "\n";
            result += closeParanthesis(prevActualTab, 0);
        }
        result += "\n}";
        cout << result;
    }
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
        string combined = getStatementPartSring($1, numberOfTab, prevActualTab);
        bodyPart += combined;
        prevActualTab = actualTab;
    }
    |
    controlStatement
    {
        string combined = getStatementPartSring($1, numberOfTab, prevActualTab);
        bodyPart += combined;

        lastControlLine = linenum;
        prevActualTab = actualTab;
    }
    |
    NEXTLINE
    {
        numberOfTab = 0;
        linenum++;
        prevActualTab = actualTab;
        bodyPart += "\n";
    }
    ;

assignment:
    VAR EQ rightAssignment 
    { 

        // Tab checking part

        afterControlStateTabCheck(linenum, lastControlLine, actualTab, numberOfTab);

        if (actualTab > 0){
            actualTab = numberOfTab;
        }

        else if (actualTab == 0 && actualTab != numberOfTab){
            cerr << "there is a tab inconsistency in line " << linenum << endl;
            exit(1);
        }

        addNewStatement("assignment", linenum, actualTab);
        checkStatementConsistency();

        // Type checking part

        string typeOfVar = operandTypes.back();
        operandTypes.clear();

        addTypeList($1, typeOfVar);
        updateVariable($1, typeOfVar, numberOfTab);

        string type = findVariableType($1, numberOfTab);

        string varCombine = string($1) + "_" + typeOfVar;
        string combined = varCombine + " " + string($2) + " " + string($3) + ";";
		$$ = strdup(combined.c_str());

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
        string lastOperand_1 = operandTypes.back();
        operandTypes.pop_back();
        string lastOperand_2 = operandTypes.back();
        operandTypes.pop_back();  

        if (lastOperand_1 == "str" && lastOperand_2 == "str"){
            operandTypes.push_back("str");
        }
        
        else if ((lastOperand_1 == "str" && lastOperand_2 != "str") || (lastOperand_2 == "str" && lastOperand_1 != "str")){
            cerr << "type inconsistency in line " << linenum << endl;
            exit(1);
        }

        else if (lastOperand_1 == "flt" || lastOperand_2 == "flt"){
            operandTypes.push_back("flt");
        }
        
        else{
            operandTypes.push_back("int");
        }

        string combined = string($1) + " " + string($2) + " " + string($3);
		$$ = strdup(combined.c_str());
    }
    |
    operand
    { $$ = $1; }
    ;

controlStatement:
    ifContol
    {   
        $$ = $1;
        if(actualTab >= numberOfTab){
            actualTab = numberOfTab;
        }
        afterControlStateTabCheck(linenum, lastControlLine, actualTab, numberOfTab);
        addNewStatement("if", linenum, numberOfTab);
        checkStatementConsistency();
        actualTab++;
        clearListForVariableList(numberOfTab+1);

    }
    |
    elifControl
    {
        $$ = $1;

        afterControlStateTabCheck(linenum, lastControlLine, actualTab, numberOfTab);
        addNewStatement("elif", linenum, numberOfTab);
        checkStatementConsistency();
        actualTab = numberOfTab+1;
        clearListForVariableList(numberOfTab+1);
    }
    |
    elseControl
    {
        $$ = $1;

        afterControlStateTabCheck(linenum, lastControlLine, actualTab, numberOfTab);
        addNewStatement("else", linenum, numberOfTab);
        checkStatementConsistency();
        actualTab = numberOfTab+1;
        clearListForVariableList(numberOfTab+1);
    }
	;

ifContol: 
	IF operand condition operand COLON
    {
        string tabCombine = "\t";
        for(int i=0; i<numberOfTab; i++){
            tabCombine = tabCombine + "\t";
        }

        string combined = string($1) + "(" + string($2) + string($3) + string($4) + ")\n" + tabCombine +"{";
		$$ = strdup(combined.c_str());
    }
    |
    TAB ifContol
    { $$ = $2; }
    ;

elifControl: 
    ELIF operand condition operand COLON
    { 
        string tabCombine = "\t";
        for(int i=0; i<numberOfTab; i++){
            tabCombine += "\t";
        }

        string combined = string($1) + "(" + string($2) + string($3) + string($4) + ")\n" + tabCombine +"{";
		$$ = strdup(combined.c_str());
    }
    |
    TAB elifControl
    { $$ = $2; }
    ;

elseControl: 
    ELSE COLON
    {
        string tabCombine = "\t";
        for(int i=0; i<numberOfTab; i++){
            tabCombine += "\t";
        }

        string combined = string($1) + "\n" + tabCombine + "{";
		$$ = strdup(combined.c_str());
    }
    |
    TAB elseControl
    { $$ = $2; }
    ;

operand:
    STRING { 
        $$ = $1; 
        operandTypes.push_back("str");
    }
    |
    INTEGER { 
        $$ = $1; 
        operandTypes.push_back("int");
    }
    |
    FLOAT { 
        $$ = $1; 
        operandTypes.push_back("flt");
    }
    |
    VAR {
        string type = findVariableType($1, numberOfTab);
        
        if(type == "undeclared"){
            cerr << $1 << " is undeclared in line " << linenum << endl;
            exit(1);
        }

        string combined = string($1) + "_" + type;
		$$ = strdup(combined.c_str());

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
    EQ EQ { 
        string combined = string(" ") + string($1) + string($2) + string(" ");
		$$ = strdup(combined.c_str());
    }
    |
    NEQ { $$ = $1; }
    |
    BIGGER { $$ = $1; }
    |
    SMALLER { $$ = $1; }
    |
    BIGGER EQ { 
        string combined = string(" ") + string($1) + string($2) + string(" ");
		$$ = strdup(combined.c_str());
    }
    |
    SMALLER EQ { 
        string combined = string(" ") + string($1) + string($2) + string(" ");
		$$ = strdup(combined.c_str());
    }
    ;

%%

void yyerror(string s){
	cerr<<"syntax error at line "<<linenum<<endl;
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