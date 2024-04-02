%{
#include<iostream>
#include<cstdlib>
#include<vector>
#include<string>
#include<fstream>
#include<sstream>
#include "MySymbolTable.h"


using namespace std;

extern int line_count;
extern int error_count;

int yyparse(void);
int yylex(void);

extern FILE *yyin;

SymbolTable *table;

FILE* input;
ofstream log,error,code,optimized_code;

void yyerror(char *s){}

Optimization op;
string curr_return_type;
string errorName;
string curr_func_name;
int currentLookahead,currentLine,scope_count = 1,temp_count = 0,label_count = 0;
vector<Parameters> parameterList;
vector<VariableInfo> variableList;
vector<VariableInfo> argumentList; 
vector<VariableInfo> myList; 
vector<string> data_list;
vector<string> received_arg_list;
vector<string> sent_arg_list;
string curr_type;
string temp_str;
string myStr = "NON_TERMINAL";
string currentStr,currName,currType;
bool temp_check = false;



string newTemp()
{
    string ret = "t" + to_string(temp_count++);
    return ret;
}
string newLabel()
{
    string ret = "L" + to_string(label_count++);
    return ret;
}



%}

%union{
    int ival;
    SymbolInfo* symbolInfoPtr;
    vector<SymbolInfo*>* vsi;
}

%token <symbolInfoPtr> ID CONST_INT CONST_FLOAT 
%token <symbolInfoPtr> ADDOP MULOP LOGICOP RELOP 
%token <ival> INT FLOAT VOID IF ELSE FOR WHILE PRINTLN RETURN
%token <ival> ASSIGNOP NOT INCOP DECOP
%token <ival> LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON 



%type <symbolInfoPtr> declaration_list 
%type <symbolInfoPtr> start program unit 
%type <symbolInfoPtr> func_declaration func_definition parameter_list 
%type <symbolInfoPtr> compound_statement var_declaration type_specifier statement statements
%type <symbolInfoPtr> expression_statement variable expression logic_expression rel_expression simple_expression
%type <symbolInfoPtr> term unary_expression factor arguments argument_list

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start: program
	{
        currentLine = line_count;
        $$ = new SymbolInfo($1->getName(), myStr);
        temp_str = $$->getName();
        log << "Line " << currentLine << ": start : program" << endl  << endl;
        log << temp_str << endl  << endl;
        currentStr = temp_str;

        if(error_count==0)
        {
            string assembly_code = "";
            assembly_code += (string)".model small\n.stack 100h\n.data\n\n";
            assembly_code += (string) "\tn_line DB 0AH,0DH,\"$\"   ;for new line\n";

            for(int i=0; i<data_list.size(); i++) {
                assembly_code += (string)"\t"+(string)data_list[i]+(string)"\n";
            }

            data_list.clear();  

            assembly_code += (string)"\n\taddress dw 0";  

            assembly_code += "\n.code\n\n";
            assembly_code += $1->getCode();


            assembly_code += ";function for printing decimal number\n"
            "println proc \n \n"

                "\t;result is stored in ax \n"   
                "\tpush ax ;save registers \n"
                "\tpush bx \n"
                "\tpush cx \n"
                "\tpush dx \n"
                
                "\t;if ax<0 \n"
                "\tor ax, ax \n"
                "\tjge @end_if_1 ;no, <0 \n"
                
                "\tpush ax \n"
                "\tmov dl, '-' \n"
                "\tmov ah, 2 \n"
                "\tint 21h \n"
                "\tpop ax \n"
                "\tneg ax \n"
                
                "\t;get decimal digits \n"
                "\t@end_if_1: \n"
                "\txor cx, cx \n"
                "\tmov bx, 10d \n"
                
                "\t@repeat_2: \n"
                "\txor dx, dx \n"
                "\tdiv bx  ;ax = quotient , dx = remainder \n"
                "\tpush dx ;save remainder on stack \n"
                "\tinc cx  ;count = count + 1 \n"
                
                "\tor ax, ax ;until quotient = 0 \n"
                "\tjne @repeat_2 \n"
                
                "\t;print digits \n"
                "\tmov ah, 2 \n"
                
                "\t@print_loop: \n"
                "\tpop dx ;digit in dl \n"
                "\tor dl, 30h ;convert to ascii \n"
                "\tint 21h \n"
                "\tloop @print_loop  \n"
                
                
                "\t;end_for \n"

                "\tLEA DX,n_line ;lea means least effective address\n"
                "\tMOV AH,9\n"
                "\tINT 21H       ;print new line\n"
                "\tpop dx \n"
                "\tpop cx \n"
                "\tpop bx \n"
                "\tpop ax \n"
                
                "\tret \n"
                "println endp\n\n";
            

            assembly_code += (string)"end main";
            $$->setCode(assembly_code);
            code << $$->getCode() << endl;
            op.create_optimized_code($$->getCode(),optimized_code);
        }
	}
	    ;

program: program unit { 
        currentLine = line_count;
        $$ = new SymbolInfo($1->getName()+$2->getName(), myStr);
        temp_str = $$->getName();
        log << "Line " << currentLine << ": program : program unit" << endl  << endl;
        log << temp_str << endl  << endl;
        $$->setCode($1->getCode()+$2->getCode());
        currentStr = temp_str;
    } 
    | unit {
        currentLine = line_count;
        $$ = new SymbolInfo($1->getName(), myStr);
        temp_str = $$->getName();
        log << "Line " << currentLine << ": program : unit" << endl  << endl; 
        log << temp_str << endl  << endl;
        $$->setCode($1->getCode());
        currentStr = temp_str;
    }  
	    ;
	
unit: var_declaration{
        currentLine = line_count;
        $$ = new SymbolInfo($1->getName(), myStr);
        temp_str = $$->getName();
        log << "Line " << currentLine << ": unit : var_declaration" << endl << endl;
        log << temp_str << endl  << endl;
        currentStr = temp_str;
    }
    | func_declaration{
        currentLine = line_count;
        $$ = new SymbolInfo($1->getName(), myStr);
        temp_str = $$->getName();
        log << "Line " << line_count << ": unit : func_declaration" << endl << endl;
        log << temp_str << endl  << endl;
        currentStr = temp_str;
     }
    | func_definition{
        currentLine = line_count;
        $$ = new SymbolInfo($1->getName(), myStr);
        temp_str = $$->getName();
        log << "Line " << currentLine << ": unit : func_definition" << endl << endl;
        log << temp_str << endl  << endl;
        $$->setCode($1->getCode());
        currentStr = temp_str;
    }
        ;
     		
func_declaration: type_specifier ID LPAREN parameter_list RPAREN 
        { 
            curr_return_type= $1->getName(); 
            currentStr = curr_return_type;
            curr_func_name = $2->getName();
            temp_str = curr_func_name;
        }
         function_declaration SEMICOLON{
            currentLine = line_count;
            $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+$4->getName()+")"+ ";"  + (string) "\n", myStr);
            temp_str = $$->getName();
            log << "Line " << currentLine << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl  << endl;
            log << temp_str << endl  << endl;
            parameterList.clear();
            myList.clear();
            currentStr = temp_str;

    }
	| type_specifier ID LPAREN RPAREN 
        { 
            curr_func_name = $2->getName();
            currentStr = curr_func_name;
            curr_return_type = $1->getName(); 
            temp_str = curr_return_type;
        }
        function_declaration SEMICOLON{
            currentStr = $1->getName()+" "+$2->getName()+"("+")"+ ";" + (string) "\n";
            currentLine = line_count;
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();
            log << "Line " << currentLine << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << endl  << endl;
            log << temp_str << endl  << endl;
            parameterList.clear();
            myList.clear();
            currentStr = temp_str;
    }
	    ;

func_definition: type_specifier ID LPAREN parameter_list RPAREN 
        { 
            curr_func_name = $2->getName();
            currentStr = curr_func_name;
            curr_return_type = $1->getName(); 
            temp_str = curr_return_type;
        } 
        function_definition compound_statement{
            currentStr = $1->getName()+" "+$2->getName()+"("+$4->getName()+")"+$8->getName();
            currentLine = line_count;
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();
            log << "Line " << currentLine << ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << endl  << endl;
            log << temp_str << endl  << endl;

            $$->setCode($8->getCode());
            string code = "";
            if($2->getName() == "main") {
                code += (string)"main proc\n" + "\tmov ax, @data\n" + "\tmov ds ,ax\n\n";
                code += $8->getCode();
                code += (string) "\n\n\tmov ah, 4ch\n\t" + "int 21h\n" + "main endp\n\n";
            }
            else{
                code += $2->getName() + " proc\n";
                code += (string) "\tpop address\n";

                for(int i=received_arg_list.size()-1; i>=0; i--) {
                    code += (string)"\tpop " + received_arg_list[i] + (string)"\n";
                }

                code += $8->getCode();
                code += (string)"\tpush address\n" + (string) "\tret\n";
                code += $2->getName() + (string)" endp\n\n";
            }

            $$->setCode(code); 
            received_arg_list.clear();
            currentStr = temp_str;
            
        }
	| type_specifier ID LPAREN RPAREN 
        {
           curr_return_type = $1->getName(); 
           currentStr = curr_return_type;
           curr_func_name = $2->getName();   
           temp_str = curr_func_name;

        } 
        function_definition compound_statement{
            currentLine = line_count;
            $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+")"+$7->getName(), myStr);
            temp_str = $$->getName();
            log << "Line " << currentLine << ": func_definition : type_specifier ID LPAREN RPAREN compound_statement" << endl  << endl;
            log << temp_str << endl  << endl;  

            string code = "";
            if($2->getName() == "main") {
                code += (string)"main proc\n" + "\tmov ax, @data\n" + "\tmov ds ,ax\n\n";
                code += $7->getCode();
                code += (string) "\n\n\tmov ah, 4ch\n\t" + "int 21h\n" + "main endp\n\n";
            }
            else{
                code += $2->getName() + " proc\n";
                code += (string) "\tpop address\n";

                for(int i=received_arg_list.size()-1; i>=0; i--) {
                    code += (string)"\tpop " + received_arg_list[i] + (string)"\n";
                }

                code += $7->getCode();
                code += (string)"\tpush address\n" + (string) "\tret\n";
                code += $2->getName() + (string)" endp\n\n";
            }

            $$->setCode(code); 
            received_arg_list.clear(); /*reset the list*/
            currentStr = temp_str;
     }
 		;	


function_declaration: {

        currentStr = curr_func_name;
        SymbolInfo* symbol_info_curr = table->LookUpCurrent(currentStr);
        SymbolInfo* symbol_info_ptr = table->LookUpAll(currentStr);

        if(symbol_info_ptr != NULL)
        {
            currentStr = curr_func_name;
            errorName = ": Multiple declaration of "+ currentStr;
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            currentLookahead = 0;
            currentStr = errorName;
        }

        else if(symbol_info_ptr == NULL){

            currentLookahead = -2;
            currentStr = curr_return_type;
            SymbolInfo *temp = new SymbolInfo(curr_func_name, "ID", currentLookahead); 
            temp->setSpecType(curr_return_type);

            for(Parameters temp_parameter : parameterList)
            {
                currName = temp_parameter.getPname();
                currType = temp_parameter.getPtype();
                temp->add_Parameter(currType, currName);
            }

            temp_check = table->InsertSymbol(temp);

            if (!temp_check)
            {
                currentStr = curr_func_name;
                currentLookahead = 0;
            }
        }

    }   
        ;




function_definition: {

        currentStr = curr_func_name;
        SymbolInfo* symbol_info_curr = table->LookUpCurrent(currentStr);
        SymbolInfo* symbol_info_ptr = table->LookUpAll(currentStr);

        if(symbol_info_ptr != NULL)
        {

            if(symbol_info_ptr->getArraySize() != -2)
            {
                currentStr = curr_func_name;
                errorName = ": Multiple declaration of "+ currentStr;
                error << "Error at line " << line_count << errorName << endl << endl;
                log << "Error at line " << line_count << errorName << endl << endl;
                currentLookahead = 0;
                error_count++;
                currentStr = errorName;
            }

            else if(symbol_info_ptr->getSpecType() != curr_return_type)
            {
                currentStr = curr_func_name;
                errorName = ": Return type mismatch with function declaration in function "+ currentStr;
                error << "Error at line " << line_count << errorName << endl << endl;
                log << "Error at line " << line_count << errorName << endl << endl;
                if(currentLookahead != 0) 
                {
                    temp_check = true;
                    currentStr = symbol_info_ptr->getSpecType();
                    currentLookahead = 0;
                }
                error_count++;
                currentStr = errorName;
            }   

            else if(symbol_info_ptr->getPlistSize() != parameterList.size()) {
                currentStr = curr_func_name;
                errorName = ": Total number of arguments mismatch with declaration in function "+ currentStr;
                error << "Error at line " << line_count << errorName << endl << endl;
                log << "Error at line " << line_count << errorName << endl << endl;
                if(currentLookahead != 0) 
                {
                    temp_check = true;
                    currentLookahead = 0;
                }
                error_count++;
                currentStr = errorName;
            }      

            else if( (symbol_info_ptr->getPlistSize() == 0 || (symbol_info_ptr->getPlistSize()==1 && symbol_info_ptr->get_Parameter(0).getPtype() == "void")) &&
                      (parameterList.size()==0 || (parameterList.size()==1 && parameterList[0].getPtype()=="void")) )
            {
                if(currentLookahead == 0) 
                {
                    temp_check = true;
                    currentStr = symbol_info_ptr->get_Parameter(0).getPtype();
                }
                else 
                {
                    temp_check = false;
                    currentStr = parameterList[0].getPtype();
                    currentLookahead = 0;
                }
                
            } 

            else{
                currentLookahead = -1;
                for(int i=0; i<parameterList.size(); i++) 
                {
                        if(symbol_info_ptr->get_Parameter(i).getPtype() != parameterList[i].getPtype()) 
                        {
                            currentStr = parameterList[i].getPtype();
                            currentLookahead = i;
                            break;
                        }
                }

                if(currentLookahead!=-1) 
                {
                    currentStr = curr_func_name;
                    errorName = "th argument mismatch in function " + currentStr;
                    temp_check = false;
                    error << "Error at line " << line_count << ": " << currentLookahead << errorName << endl << endl;
                    log << "Error at line " << line_count << ": " << currentLookahead << errorName << endl << endl;
                    error_count++;
                    currentStr = temp_str;
                }
            }
        }

        else if(symbol_info_ptr == NULL){
            
            currentLookahead = -2;
            SymbolInfo *temp = new SymbolInfo(curr_func_name, "ID", currentLookahead);
            temp->setSpecType(curr_return_type);

            for(Parameters temp_parameter : parameterList)
            {
                currName = temp_parameter.getPname();
                currType = temp_parameter.getPtype();
                temp->add_Parameter(currType, currName);
            }

            temp_check = table->InsertSymbol(temp);

            if (!temp_check)
            {
                currentStr = curr_func_name;
                currentLookahead = 0;
            }
        
        }
  
    } 
        ;
		 

parameter_list: parameter_list COMMA type_specifier ID{
        currentLine = line_count;
        currentStr = $1->getName()+","+$3->getName()+" "+$4->getName();
        $$ = new SymbolInfo(currentStr, myStr);
        temp_str = $$->getName();

        log << "Line " << currentLine << ": parameter_list : parameter_list COMMA type_specifier ID" << endl  << endl;
        log << temp_str << endl << endl;

        currName = $4->getName();
        currType = $3->getName();
        Parameters tempParameter(currName,currType);
        parameterList.push_back(tempParameter);
        if (!temp_check)
        {
            currentLookahead = 0;
            currentStr = currType;
        }
    }
	| parameter_list COMMA type_specifier{
            currentLine = line_count;
            currentStr = $1->getName()+","+ $3->getName();
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();

            log << "Line " << currentLine << ": parameter_list : parameter_list COMMA type_specifier" << endl << endl;
            log << temp_str << endl  << endl;

            currName = "";
            currType = $3->getName();
            Parameters tempParameter(currName,currType);
            parameterList.push_back(tempParameter);
            if (!temp_check)
            {
                currentLookahead = 0;
                currentStr = currType;
            }
            
     }
 	| type_specifier ID{
            currentLine = line_count;
            currentStr = $1->getName()+" "+$2->getName();
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();

            log << "Line " << currentLine << ": parameter_list : type_specifier ID" << endl << endl;
            log << temp_str << endl  << endl;

            currName = $2->getName();
            currType = $1->getName();
            Parameters tempParameter(currName,currType);
            parameterList.push_back(tempParameter);
            if (!temp_check)
            {
                currentLookahead = 0;
                currentStr = currType;
            }

     }
	| type_specifier{
            currentLine = line_count;
            $$ = new SymbolInfo($1->getName(), myStr);  
            temp_str = $$->getName();

            log << "Line " << currentLine << ": parameter_list : type_specifier" << endl << endl;
            log << temp_str << endl  << endl;

            currName = "";
            currType = $1->getName();
            Parameters tempParameter(currName,currType);
            parameterList.push_back(tempParameter);
            if (!temp_check)
            {
                currentLookahead = 0;
                currentStr = currType;
            }
    }

 		;

 		
compound_statement: LCURL entering_scope statements RCURL{
        currentLine = line_count;
        currentStr = (string)"\{ "+(string)"\n"+ $3->getName() + (string)"\n"+(string)"\}"+(string)"\n";
        $$ = new SymbolInfo(currentStr, myStr);
        temp_str = $$->getName();

        log << "Line " << currentLine << ": compound_statement : LCURL statements RCURL" << endl << endl;
        log << temp_str << endl  << endl;

        if (!temp_check)
        {
            currentLookahead = 0;
            currentStr = temp_str;
            temp_check = true;
        }
        $$->setCode($3->getCode());
        table->PrintAllScopeTable(log);
        table->ExitScope(log);
    }
 	| LCURL entering_scope RCURL{
            currentLine = line_count;
            currentStr = (string)"\{ "+(string)"\n"+(string)"\n"+(string)"\}"+(string)"\n";
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();

            log << "Line " << currentLine << ": compound_statement : LCURL RCURL" << endl  << endl;
            log << temp_str << endl  << endl;
            if (!temp_check)
            {
                currentLookahead = 0;
                currentStr = temp_str;
                temp_check = true;
            }
            table->PrintAllScopeTable(log);
            table->ExitScope(log);
    }
 		;	 

entering_scope:   {
            table->EnterScope(log, ++scope_count);
            myList.clear();
            for(Parameters temp_parameter : parameterList)
            {
                currentLookahead = -1;
                VariableInfo temp_variable(temp_parameter.getPname(),temp_parameter.getPtype(),currentLookahead);


                SymbolInfo* symbolInfoPtr = new SymbolInfo(temp_variable.getVarName(), "ID",  -1);
                symbolInfoPtr->setArraySize(temp_variable.getVarSize());
                symbolInfoPtr->setSpecType(temp_variable.getVarType());

                string asm_name = temp_variable.getVarName() + to_string(scope_count);
                symbolInfoPtr->set_assembly_operand(asm_name);

                if(temp_variable.getVarSize() == -1){
                    data_list.push_back(asm_name + " dw ?");
                }
                else{
                    string temp = asm_name;
                    temp += " dw ";
                    temp += to_string(temp_variable.getVarSize()) + " dup (?)";
                    data_list.push_back(temp);
                }

                temp_check = table->InsertSymbol(symbolInfoPtr);
                temp_str = asm_name;

                if(!temp_check)
                {
                     errorName = ": Multiple declaration of " + temp_variable.getVarName() + " in parameter";
                     error << "Error at line " << line_count << errorName << endl << endl;
                     log << "Error at line " << line_count << errorName << endl << endl;
                     error_count++;
                }
                else
                {
                    received_arg_list.push_back(temp_str);
                }

            }
            parameterList.clear();
        } 
    ;

 		 
var_declaration: type_specifier declaration_list SEMICOLON {
            currentLine = line_count;
            currentStr = (string)$1->getName()+(string)" "+(string)$2->getName()+(string)";"+(string)"\n"+(string)"\n";
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();
            currentLookahead = myList.size();
            log << "Line " << line_count << ": var_declaration : type_specifier declaration_list SEMICOLON" << endl << endl;
            log << temp_str << endl  << endl;

            for(int i=0; i<variableList.size(); i++){
                if(variableList[i].getVarType() == "void") 
                {
                    errorName = ": Variable type cannot be void ";
                    error << "Error at line " << line_count << errorName << endl << endl;
                    log << "Error at line " << line_count << errorName << endl << endl;
                    error_count++;
                    temp_check = false;
                }
                else 
                {

                    SymbolInfo* symbolInfoPtr = new SymbolInfo(variableList[i].getVarName(), "ID",  -1);
                    symbolInfoPtr->setArraySize(variableList[i].getVarSize());
                    symbolInfoPtr->setSpecType(variableList[i].getVarType());

                    string asm_name = variableList[i].getVarName() + to_string(scope_count);
                    symbolInfoPtr->set_assembly_operand(asm_name);

                    if(variableList[i].getVarSize() == -1){
                        data_list.push_back(asm_name + " dw ?");
                    }
                    else{
                        string temp = asm_name;
                        temp += " dw ";
                        temp += to_string(variableList[i].getVarSize()) + " dup (?)";
                        data_list.push_back(temp);
                    }

                    temp_check = table->InsertSymbol(symbolInfoPtr);
                    temp_str = asm_name;

                }
            }
            variableList.clear();
            myList.clear();

    }
 		;
 		 
type_specifier: INT {
            currentLine = line_count;
            curr_type = "int";
            $$ = new SymbolInfo(curr_type, myStr);
            log << "Line " << currentLine << ": type_specifier : INT" << endl << endl;
            log << curr_type << endl << endl;
            temp_check = true;

    }
 		| FLOAT {
            currentLine = line_count;
            curr_type = "float";
            $$ = new SymbolInfo(curr_type, myStr);
            log << "Line " << currentLine << ": type_specifier : FLOAT" << endl << endl;
            log << curr_type << endl << endl;
            temp_check = true;

    }
 		| VOID {
            currentLine = line_count;
            curr_type = "void";
            $$ = new SymbolInfo(curr_type, myStr);
            log << "Line " << currentLine << ": type_specifier : VOID" << endl << endl;
            log << curr_type << endl << endl;
            temp_check = true;

    }
 		;

declaration_list: declaration_list COMMA ID {
            currentStr = (string)$1->getName()+(string)","+(string)$3->getName();
            currentLine = line_count;
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();
            currentLookahead = -1;
            log << "Line " << currentLine << ": declaration_list : declaration_list COMMA ID" << endl << endl;
            log << temp_str << endl  << endl;
            VariableInfo temp_variable($3->getName(),curr_type,currentLookahead);
            currentLookahead = 0;
            temp_check = true;
            variableList.push_back(temp_variable);
            myList.push_back(temp_variable);
            SymbolInfo* symbolAllPtr = table->LookUpAll(temp_variable.getVarName());
            SymbolInfo* symbolPtr = table->LookUpCurrent(temp_variable.getVarName());
            currentLookahead = myList.size();

            if(symbolPtr != NULL) {
                errorName = ": Multiple declaration of "+ temp_variable.getVarName();
                error << "Error at line " << line_count << errorName << endl << endl;
                log << "Error at line " << line_count << errorName << endl << endl;
                error_count++;
                currentStr = temp_str;
            }

            delete $1;
            delete $3;
            
    }
 		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
            currentStr = (string)$1->getName()+(string)","+(string)$3->getName()+(string)"["+(string)$5->getName()+(string)"]";
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();
            currentLine = line_count;
            currentLookahead = 0;
            log << "Line " << currentLine << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << endl << endl;
            log << temp_str << endl  << endl;
            stringstream str($5->getName());
            str >> currentLookahead;
            VariableInfo temp_variable($3->getName(),curr_type,currentLookahead);
            currentLookahead = 0;
            temp_check = true;
            variableList.push_back(temp_variable);  
            myList.push_back(temp_variable);
            SymbolInfo* symbolAllPtr = table->LookUpAll(temp_variable.getVarName()); 
            SymbolInfo* symbolPtr = table->LookUpCurrent(temp_variable.getVarName());
            currentLookahead = myList.size();

            if(symbolPtr != NULL) {
                errorName = ": Multiple declaration of "+ temp_variable.getVarName();
                error << "Error at line " << line_count << errorName << endl << endl;
                log << "Error at line " << line_count << errorName << endl << endl;
                error_count++;
                currentStr = temp_str;
            }

            delete $1;
            delete $3;
            delete $5;
                 
    }
 		| ID {
            currentLine = line_count;
            $$ = new SymbolInfo($1->getName(), myStr);
            temp_str = $$->getName();
            log << "Line " << currentLine << ": declaration_list : ID" << endl << endl;
            log << temp_str << endl  << endl;
            VariableInfo temp_variable($1->getName(),curr_type,-1);
            myList.push_back(temp_variable);
            currentLookahead = 0;
            temp_check = true;
            variableList.push_back(temp_variable);  
            SymbolInfo* symbolAllPtr = table->LookUpAll(temp_variable.getVarName()); 
            SymbolInfo* symbolPtr = table->LookUpCurrent(temp_variable.getVarName());
            currentLookahead = myList.size();

            if(symbolPtr != NULL) {
                errorName = ": Multiple declaration of "+ temp_variable.getVarName();
                error << "Error at line " << line_count << errorName << endl << endl;
                log << "Error at line " << line_count << errorName << endl << endl;
                error_count++;
                currentStr = temp_str;
            }

            delete $1;
    }
 		| ID LTHIRD CONST_INT RTHIRD {
            currentStr = (string)$1->getName()+(string)"["+(string)$3->getName()+(string)"]";
            currentLookahead = 0;
            currentLine = line_count;
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();
            log << "Line " << currentLine << ": declaration_list : ID LTHIRD CONST_INT RTHIRD" << endl  << endl;
            log << temp_str << endl  << endl;
            stringstream str($3->getName());
            str >> currentLookahead;
            VariableInfo temp_variable($1->getName(),curr_type,currentLookahead);
            currentLookahead = 0;
            temp_check = true;
            variableList.push_back(temp_variable);  
            myList.push_back(temp_variable);
            SymbolInfo* symbolAllPtr = table->LookUpAll(temp_variable.getVarName()); 
            SymbolInfo* symbolPtr = table->LookUpCurrent(temp_variable.getVarName());
            currentLookahead = myList.size();

            if(symbolPtr != NULL) {
                errorName = ": Multiple declaration of " + temp_variable.getVarName();
                temp_check = false;
                error << "Error at line " << line_count << errorName << endl << endl;
                log << "Error at line " << line_count << errorName << endl << endl;
                error_count++;
                currentStr = temp_str;
            }
            delete $1;
            delete $3;
            
    }
 		;

statements: statement {
            $$ = new SymbolInfo((string)$1->getName(), myStr);
            temp_str = $$->getName();
            currentLine = line_count;
            log << "Line " << currentLine << ": statements : statement" << endl << endl;
            log << temp_str << endl  << endl;
            $$->setCode( $1->getCode());
            delete $1;
            currentStr = temp_str;
    }
	    | statements statement {
            $$ = new SymbolInfo((string)$1->getName()+(string)$2->getName(), myStr);
            temp_str = $$->getName();
            currentLine = line_count;
            log << "Line " << currentLine << ": statements : statements statement" << endl << endl;
            log << temp_str << endl  << endl;
            $$->setCode($1->getCode()+$2->getCode());
            delete $1;
            delete $2;
            currentStr = temp_str;
    }
	    ;
	   
statement: var_declaration{
        $$ = new SymbolInfo((string)"\t"+(string)$1->getName(), myStr);
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": statement : var_declaration" << "\n"  << endl;
        log << temp_str << endl  << endl;
        temp_check = false;
        currentStr = temp_str;
    }
	  | expression_statement{
           $$ = new SymbolInfo($1->getName(), myStr);
           temp_str = $$->getName();
           currentLine = line_count;
           log << "Line " << currentLine << ": statement : expression_statement" << endl  << endl;
           log << temp_str << endl  << endl;
           $$->setCode(op.createComment($$->getName()) + $1->getCode());
           temp_check = false;
           currentStr = temp_str;
      }
	  | compound_statement{
           $$ = new SymbolInfo($1->getName(), myStr);
           temp_str = $$->getName();
           currentLine = line_count;
           log << "Line " << currentLine << ": statement : compound_statement" << endl  << endl;
           log << temp_str << endl  << endl;
           $$->setCode($1->getCode());
           if(!temp_check)
           {
                currentStr = temp_str;
                temp_check = true;
                currentLookahead = 0;
           }
      }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement{
           currentStr = "for"+(string)"("+$3->getName()+$4->getName()+$5->getName()+(string)")"+ $7->getName();
           $$ = new SymbolInfo(currentStr, myStr);
           temp_str = $$->getName();
           currentLine = line_count;
           log << "Line " << currentLine << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << endl  << endl;
           log << temp_str << endl  << endl;
           currentLookahead = myList.size();

           string label1 = newLabel();
           string label2 = newLabel();
           string code = "";

           code += $3->getCode();
           code += "\t" + label1+ ":\n";
           code += $4->getCode() + "\tmov ax, " + $4->get_assembly_operand() + "\n\tcmp ax, 0\n\tje " + label2 + "\n";
           code += $7->getCode() + $5->getCode() ;
           code +=  "\tjmp " + label1 + "\n\t" + label2 + ":\n";

           $$->setCode(op.createComment($$->getName()) + code);


           if(!temp_check)
           {
                currentStr = temp_str;
                temp_check = true;
                currentLookahead = 0;
           }
       }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE{
           currentStr = "if"+(string)"("+$3->getName()+(string)")"+$5->getName();
           $$ = new SymbolInfo(currentStr, myStr);
           temp_str = $$->getName();
           currentLine = line_count;
           currentLookahead = myList.size();
           log << "Line " << currentLine << ": statement : IF LPAREN expression RPAREN statement" << endl << endl;
           log << temp_str << endl  << endl;

           string label = newLabel();
           $$->setCode(op.createComment($$->getName()) + $3->getCode()+"\tmov ax, "+$3->get_assembly_operand()+"\n\tcmp ax, 0\n\tje " + label+ "\n"+$5->getCode()+ "\t" + label + ":\n");
           
           if(!temp_check)
           {
                currentStr = temp_str;
                temp_check = true;
                currentLookahead = 0;
           }
       }
	  | IF LPAREN expression RPAREN statement ELSE statement{
           currentStr = "if"+(string)"("+$3->getName()+(string)")"+$5->getName()+" else"+$7->getName();
           $$ = new SymbolInfo(currentStr, myStr);
           temp_str = $$->getName();
           currentLine = line_count;
           log << "Line " << currentLine << ": statement : IF LPAREN expression RPAREN statement ELSE statement" << endl  << endl;
           log << temp_str << endl  << endl;

           string label1 = newLabel();
           string label2 = newLabel();

           string code = $3->getCode() +"\tmov ax, " + $3->get_assembly_operand() + "\n\tcmp ax, 0\n" +"\tje " + label1 + "\n" + $5->getCode() + "\tjmp " + label2+"\n";
           code = code  + "\t" + label1 + ":\n" + $7->getCode() + "\t" + label2 + ":\n";
           $$->setCode(op.createComment($$->getName()) + code);

           if(!temp_check)
           {
                currentStr = temp_str;
                temp_check = true;
                currentLookahead = 0;
           }
      }
	  | WHILE LPAREN expression RPAREN statement{
            currentStr = "while"+(string)"("+$3->getName()+(string)")"+$5->getName();
            $$ = new SymbolInfo(currentStr, myStr);
            temp_str = $$->getName();
            currentLine = line_count;
            log << "Line " << currentLine << ": statement : WHILE LPAREN expression RPAREN statement" << endl  << endl;
            log << temp_str << endl  << endl;

            string label1 = newLabel();
            string label2 = newLabel();
            $$->setCode(op.createComment($$->getName()) + (string) "\t"+label1+":\n"+$3->getCode()+"\tmov ax, "+$3->get_assembly_operand()+"\n\tcmp ax, 0\n\tje "+label2+"\n");
            $$->setCode($$->getCode() +  $5->getCode()+"\tjmp "+label1+"\n\t"+label2+":\n");

            if(!temp_check)
            {
                currentStr = temp_str;
                temp_check = true;
                currentLookahead = 0;
            }
      }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON{
            currentStr = "println"+(string)"("+$3->getName()+");";
            $$ = new SymbolInfo(currentStr , myStr);
            temp_str = $$->getName();
            currentLine = line_count;
            log << "Line " << currentLine << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << endl  << endl;
            log << temp_str << endl  << endl;
            currentStr = temp_str;

            SymbolInfo* symbolPtr = table->LookUpCurrent($3->getName());
            pair<string,SymbolInfo*> pr = table->LookUpAll2($3->getName());
            temp_str = pr.second->getName();
            temp_str.append(pr.first);

            if(table->LookUpAll($3->getName()) == NULL)
            {
                errorName = ": Undeclared variable " + $3->getName();
                error << "Error at line " << line_count << errorName << endl << endl;
                log << "Error at line " << line_count << errorName << endl << endl;
                error_count++;
                currentStr = temp_str;
                temp_check = true;
            }



            if(table->LookUpAll($3->getName()) != NULL  && table->LookUpAll($3->getName())->getArraySize()==-1)
            {
                string code = (string)"\tpush ax\n\tpush bx\n\tpush address\n"
                "\tmov ax, " + temp_str + (string)"\n"
                "\tcall println\n\tpop address\n\tpop bx\n\tpop ax\n";

                $$->setCode(op.createComment($$->getName()) + code);
                temp_check = true;
                currentLookahead = 0;
            }

      }
	  | RETURN expression SEMICOLON{
            $$ = new SymbolInfo("return "+$2->getName()+";" , myStr);
            temp_str = $$->getName();
            currentLine = line_count;
            log << "Line " << currentLine << ": statement : RETURN expression SEMICOLON" << endl  << endl;
            log << temp_str << endl  << endl;
            temp_check = true;
            currentLookahead = 0;

            if($2->getSpecType() == "void") {
                errorName = ": Void function called within expression";
                error << "Error at line " << line_count << errorName << endl << endl;
                log << "Error at line " << line_count << errorName << endl << endl;
                error_count++;
                currentStr = temp_str;
            } 

            $$->setCode(op.createComment($$->getName())  + $2->getCode() + (string)"\tpush " + $2->get_assembly_operand()+(string)"\n");
        }
	        ;
	  
expression_statement: SEMICOLON	{
        $$ = new SymbolInfo("; ", myStr);    
        log << "Line " << line_count << ": expression_statement : SEMICOLON" << endl  << endl;  
        log << $$->getName() << endl  << endl;
        $$->set_assembly_operand(";");
        currentStr = temp_str;
        temp_check = true;
        currentLookahead = 0;
    }		
	| expression SEMICOLON {
        currentStr = "\t"+$1->getName()+";"+"\n";
        $$ = new SymbolInfo(currentStr, myStr);
        log << "Line " << line_count << ": expression_statement : expression SEMICOLON" << endl << endl;
        log << $$->getName() << endl  << endl;
        $$->set_assembly_operand($1->get_assembly_operand());
        $$->setCode($1->getCode());
        if(!temp_check)
        {
            currentStr = temp_str;
            temp_check = true;
            currentLookahead = 0;
        }
    }
			;

variable: ID {
        currentStr = $1->getName();
        $$ = new SymbolInfo(currentStr, myStr);
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": variable : ID" << endl  << endl;
        log << temp_str << endl  << endl;
        SymbolInfo* symbolCurr = table->LookUpCurrent(currentStr);
        pair<string,SymbolInfo*> pr = table->LookUpAll2(currentStr);

        // cout<<pr.first<<endl;

        if(pr.second == NULL) {
            errorName = ": Undeclared variable " + currentStr;
            $$->setSpecType("undeclared");
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++;
        } 
        else {
            currentStr = temp_str;
            temp_check = true;
            currentLookahead = 0;
            $$->setSpecType(pr.second->getSpecType());
            $$->setArraySize(pr.second->getArraySize());
            temp_str = pr.second->getName();
            temp_str.append(pr.first);
            $$->set_assembly_operand(temp_str);
            //cout<<temp_str<<endl;
            
        }

    }	

	| ID LTHIRD expression RTHIRD {
         
        $$ = new SymbolInfo($1->getName()+"["+$3->getName()+"]", myStr);
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": variable: ID LTHIRD expression RTHIRD" << endl << endl;
        log << temp_str << endl  << endl;
        SymbolInfo* symbolcurrPtr = table->LookUpCurrent($1->getName());
        SymbolInfo* symbolPtr = table->LookUpAll($1->getName());

        if(symbolPtr == NULL) {
            errorName = ": Undeclared variable " + $1->getName();
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            currentLookahead = error_count;
        } 
        else {
            currentStr = temp_str;
            temp_check = true;
            $$->setSpecType(symbolPtr->getSpecType());
            $$->setArraySize(symbolPtr->getArraySize());
        }
        
        if($3->getSpecType() != "int") {
            errorName = ": Expression inside third brackets not an integer ";
            currentLookahead = error_count;
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            temp_check = false;
        }            

        if($3->getSpecType() == "void") {
            errorName = ": Void function called within expression";
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            temp_check = false;
        } 

        if(symbolPtr->getArraySize() < 0 && symbolPtr!=NULL ) {
            currentLookahead = error_count;
            errorName = ": " + symbolPtr->getName() + " not an array";
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            temp_check = false;
        }

        string code = $3->getCode()+ "\tmov bx, " + $3->get_assembly_operand() + "\n\t add bx, bx\n";
        $$->setCode(code);
        $$->set_assembly_operand(symbolPtr->get_assembly_operand());

        if(!temp_check)
        {
            currentStr = temp_str;
            temp_check = true;
            currentLookahead = 0;
        }


    }
	    ;

expression: logic_expression{
        $$ = new SymbolInfo($1->getName(), myStr, $1->getArraySize());
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": expression : logic_expression" << endl << endl;
        log << temp_str << endl  << endl;
        temp_check = true;
        currentLookahead = 0;
        $$->setSpecType($1->getSpecType());
        $$->setCode($1->getCode());
        $$->set_assembly_operand($1->get_assembly_operand());
    }	
	| variable ASSIGNOP logic_expression{
        currentStr = $1->getName() + " = " + $3->getName();
        $$ = new SymbolInfo(currentStr, myStr, $1->getArraySize());
        temp_str = $$->getName();
        currentLine = line_count;
        temp_check = false;
        log << "Line " << currentLine << ": expression : variable ASSIGNOP logic_expression" << endl  << endl;
        log << temp_str << endl  << endl;

        if($3->getSpecType() == "void") {
            errorName = ": Void function used in expression";
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            temp_check = true;
            currentLookahead = error_count;
        }

        // if(!temp_check && $1->getArraySize() >=0  && $3->getArraySize() < 0){
        //         errorName = ": Type mismatch , " + $1->getName() + " is an array";
        //         error << "Error at line " << line_count << errorName << endl << endl;
        //         log << "Error at line " << line_count << errorName << endl << endl;
        //         error_count++;
        //         currentLookahead = error_count;
        // } 

        if($1->getArraySize() == -2)
        {
            errorName = ": " + $1->getName() + " is a function , not a variable. ";
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            temp_check = true;
        }

        if(!temp_check  &&  $3->getSpecType() != "undeclared"  && $1->getSpecType() != "undeclared") {

                if($3->getSpecType() == "int" && $1->getSpecType() == "float"){
                    currentLookahead = 0;
                    currentStr = temp_str;
                }
                else if($1->getSpecType() != $3->getSpecType()){
                    errorName = ": Type mismatch ";
                    error << "Error at line " << line_count << errorName << endl << endl;
                    log << "Error at line " << line_count << errorName << endl << endl;
                    error_count++;
                    temp_check = true;
                    currentLookahead = error_count;
                }
                
        }
        
        $$->setSpecType($1->getSpecType());
        currentStr = temp_str;
        currentLookahead = 0;

        if($1->getArraySize() > -1){
            string temp  = newTemp();
            data_list.push_back(temp + (string)" dw ?");
            string code = $3->getCode() + $1->getCode()+ (string)"\tmov ax, "+$3->get_assembly_operand()+(string)"\n";
            code += (string)"\tmov " + $1->get_assembly_operand() + (string)"[bx], ax\n";
            code += (string)"\tmov " + temp + (string)", ax\n";
            $$->setCode(code);
        }
        else{
            $$->setCode($1->getCode()+$3->getCode()+"\tmov ax, "+$3->get_assembly_operand()+"\n\tmov "+$1->get_assembly_operand()+", ax\n");
            //cout<<$1->get_assembly_operand()<<endl;
            $$->set_assembly_operand($1->get_assembly_operand());
        }
    }	
	    ;
			
logic_expression: rel_expression {
        $$ = new SymbolInfo($1->getName(), myStr, $1->getArraySize());
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": logic_expression : rel_expression" << endl << endl;
        log << temp_str << endl  << endl;
        $$->setSpecType($1->getSpecType());  
        $$->setCode($1->getCode());
        $$->set_assembly_operand($1->get_assembly_operand()); 
        currentStr = temp_str;
        currentLookahead = currentLine;     
    }	
	| rel_expression LOGICOP rel_expression {
        currentStr = $1->getName()+$2->getName()+$3->getName();
        $$ = new SymbolInfo(currentStr, myStr, $1->getArraySize());
        temp_str = $$->getName();
        currentLine = line_count;
        $$->setSpecType("int");
        log << "Line " << currentLine << ": logic_expression : rel_expression LOGICOP rel_expression" << endl << endl;
        log << temp_str << endl  << endl;

        if($3->getSpecType() == "void" || $1->getSpecType() == "void") {
            errorName = ": Void function called within expression ";
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++;
            currentLookahead = error_count;
        }

        string label1 = newLabel();
        string label2 = newLabel();
        string temp = newTemp();
        data_list.push_back(temp+(string)" dw ?");

        string code = $1->getCode()+$3->getCode();
        
        if($2->getName() == "&&") {
            code += (string)"\tmov ax, " + $1->get_assembly_operand()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n";
            code += (string)"\tmov ax, "+$3->get_assembly_operand()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n";
            code += (string)"\tmov ax, 1\n" + (string)"\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n\t";
            code += label1+(string)":\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\t";
            code += label2+(string)":\n";
        } else {
            /*  LOGICOP is "||"  */
            code += (string)"\tmov ax, "+$1->get_assembly_operand()+(string)"\n\tcmp ax, 0\n\tjne "+label1+(string)"\n";
            code += (string)"\tmov ax, "+$3->get_assembly_operand()+(string)"\n\tcmp ax, 0\n\tjne "+label1+(string)"\n";
            code += (string)"\tmov ax, 0\n" + (string) "\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n\t";
            code += label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t";
            code += label2+(string)":\n";
        }
        $$->setCode(code);
        $$->set_assembly_operand(temp);
        
        if(!temp_check)
        {
            currentStr = temp_str;
            temp_check = true;
            currentLookahead = 0;
        }
    }	
	    ;
			
rel_expression: simple_expression {
        temp_str = $1->getName();
        $$ = new SymbolInfo(temp_str, myStr, $1->getArraySize());
        currentLine = line_count;
        $$->setSpecType($1->getSpecType()); 
        log << "Line " << currentLine << ": rel_expression : simple_expression" << endl << endl; 
        log << temp_str << endl  << endl; 
        $$->setCode($1->getCode());
        $$->set_assembly_operand($1->get_assembly_operand());
        currentStr = temp_str;
        temp_check = true;
    }
	| simple_expression RELOP simple_expression{
        currentStr = $1->getName()+$2->getName()+$3->getName();
        $$ = new SymbolInfo(currentStr, myStr, $1->getArraySize());
        temp_str = $$->getName();
        currentLine = line_count;
        $$->setSpecType("int");
        log << "Line " << currentLine << ": rel_expression :  simple_expression RELOP simple_expression" << endl  << endl;
        log << temp_str << endl  << endl;
        if($1->getSpecType() == "void" || $3->getSpecType() == "void") {
            errorName = ": Void function called within expression ";
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++;
            currentLookahead = error_count;
        }
        string label1 = newLabel();
        string label2 = newLabel();
        string temp = newTemp();
        data_list.push_back(temp+" dw ?"); 
        
        string code = $1->getCode() + $3->getCode() + "\tmov ax, " + $1->get_assembly_operand()+ "\n\tcmp ax, " + $3->get_assembly_operand()+"\n";

        if($2->getName() == "==") {

            code += "\tje " + label1 + "\n\t" + "mov ax, 0\n\t" + "mov " + temp + ", ax\n\t" + "jmp " + label2 + "\n";
            code +=  "\t" + label1 + ":\n\tmov ax, 1\n\tmov " + temp + ", ax\n\t" + label2 + ":\n";
            
        } else if($2->getName() == "!="){

            code += "\tjne "+ label1 + "\n\t" + "mov ax, 0\n\tmov "+temp+", ax\n\tjmp " + label2 +"\n";
            code += "\t" +label1 + ":\n\t" + "mov ax, 1\n\tmov " + temp + ", ax\n\t" + label2 + ":\n";
        }
        else if($2->getName() == "<") {

            code += "\tjl "+ label1 + "\n\t" + "mov ax, 0\n\tmov " + temp + ", ax\n\tjmp "+ label2 + "\n";
            code += "\t" + label1 + ":\n\t" + "mov ax, 1\n\tmov " + temp + ", ax\n\t" + label2 + ":\n";
        } 
        else if($2->getName() == "<=") {

            code += "\tjle " + label1 + "\n\t" +" mov ax, 0\n\tmov " + temp + ", ax\n\tjmp " + label2 + "\n";
            code += "\t" + label1 + ":\n\t" + "mov ax, 1\n\tmov " + temp + ", ax\n\t" + label2 + ":\n";
        }
        else if($2->getName() == ">") {

            code += "\tjg "+ label1 + "\n\tmov ax, 0\n\tmov " + temp + ", ax\n\tjmp " + label2+"\n";
            code += "\t" + label1 + ":\n\tmov ax, 1\n\tmov " + temp + ", ax\n\t" + label2 + ":\n";

        } 
        else if($2->getName() == ">=") {

            code += "\tjge "+ label1 + "\n\tmov ax, 0\n\tmov " + temp +", ax\n\tjmp " + label2 + "\n";
            code += "\t" + label1 + ":\n\tmov ax, 1\n\tmov " + temp + ", ax\n\t" + label2 + ":\n";
        }

        $$->setCode(code);
        $$->set_assembly_operand(temp);
        currentStr = temp_str;
        temp_check = true;

    }	
	    ;
				
simple_expression: term {
        temp_str = $1->getName();
        currentLine = line_count;
        $$ = new SymbolInfo(temp_str, myStr, $1->getArraySize());
        $$->setSpecType($1->getSpecType());
        currentLookahead = myList.size();
        log << "Line " << currentLine << ": simple_expression : term" << endl << endl;
        log << temp_str << endl  << endl; 
        $$->setCode($1->getCode());
        $$->set_assembly_operand($1->get_assembly_operand()); 
        currentStr = temp_str;
        temp_check = true;

    }
	| simple_expression ADDOP term { 
        currentStr = $1->getName()+$2->getName()+$3->getName();
        $$ = new SymbolInfo(currentStr, myStr, $1->getArraySize());
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": simple_expression : simple_expression ADDOP term" << endl << endl;
        log << temp_str << endl  << endl;

        
        if($1->getSpecType() == "void" || $3->getSpecType() == "void") {
            errorName = ": Void function called within expression ";
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++;
            currentLookahead = error_count;
        }
        if($1->getSpecType()=="float" || $3->getSpecType()=="float") {
            $$->setSpecType("float");
            temp_check = true;
            currentLookahead = 0;
        }
        else {
            $$->setSpecType($1->getSpecType()); 
            currentStr = temp_str;
            temp_check = true;
            currentLookahead = 0;
        }

        string temp = newTemp(); 
        data_list.push_back(temp+" dw ?");

        if($2->getName() == "+") {
            /* addition */
            $$->setCode($1->getCode()+$3->getCode()+"\tmov ax, "+$1->get_assembly_operand()+"\n\tadd ax, "+$3->get_assembly_operand()+"\n\tmov "+temp+", ax\n");
            $$->set_assembly_operand(temp);

        } else {
            /* subtraction */
            $$->setCode($1->getCode()+$3->getCode()+"\tmov ax, "+$1->get_assembly_operand()+"\n\tsub ax, "+$3->get_assembly_operand()+"\n\tmov "+temp+", ax\n");
            $$->set_assembly_operand(temp);
        }
    }
	    ;

term:	unary_expression{
        temp_str = $1->getName();
        currentLine = line_count;
        $$ = new SymbolInfo(temp_str, myStr, $1->getArraySize());
        log << "Line " << currentLine << ": term : unary_expression" << endl << endl;
        log << temp_str << endl  << endl;  
        $$->setSpecType($1->getSpecType());
        $$->setCode($1->getCode());
        $$->set_assembly_operand($1->get_assembly_operand());
        currentStr = temp_str;
        temp_check = true;
    }
    | term MULOP unary_expression{
        currentStr = $1->getName()+$2->getName()+$3->getName();
        $$ = new SymbolInfo(currentStr, myStr, $1->getArraySize());
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": term : term MULOP unary_expression" << endl  << endl;
        log << temp_str << endl  << endl;  
        if($1->getSpecType() == "void" || $3->getSpecType() == "void") {
            errorName = ": Void function used in expression";
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++;
            currentLookahead = error_count;
            temp_check = false;
        }

        if(($1->getSpecType() != "int" || $3->getSpecType() != "int") && ($2->getName() == "%")) {
            errorName = ": Non-Integer operand on modulus operator";
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++;
            currentLookahead = error_count;
            $$->setSpecType("int");
            currentStr = $1->getSpecType();
        } 
        else if(($2->getName() != "%") && ($1->getSpecType() == "float" || $3->getSpecType() == "float")) {
            temp_check = false;
            $$->setSpecType("float");  
            currentStr = $1->getSpecType();
        } 
        else if(($2->getName() == "%") && stoi($3->getName(), nullptr, 10) ==  0) {
            errorName = ": Modulus by zero ";
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            currentLookahead = error_count;
            $$->setSpecType("int");  
            currentStr = $1->getSpecType();
        } 

        else $$->setSpecType($1->getSpecType());

        string temp = newTemp();
        data_list.push_back(temp+" dw ?");

        if($2->getName() == "*") {
            /*  multiplication */
            $$->setCode($1->getCode()+$3->getCode()+"\tmov ax, "+$1->get_assembly_operand()+"\n\tmov bx, "+$3->get_assembly_operand()+"\n\timul bx\n\tmov "+temp+", ax\n");
            $$->set_assembly_operand(temp);

        } else {
            /*  division or mod */
            $$->setCode($1->getCode()+$3->getCode()+"\tmov ax, "+$1->get_assembly_operand()+"\n\tcwd\n");
            $$->setCode($$->getCode()+"\tmov bx, "+$3->get_assembly_operand()+"\n\tidiv bx\n");
                
            if($2->getName() == "/") {
                $$->setCode($$->getCode()+(string)"\tmov "+temp+", ax\n"); 
            } else {
                $$->setCode($$->getCode()+(string)"\tmov "+temp+", dx\n");
            }
                
            $$->set_assembly_operand(temp);
        }
        currentLookahead = 0;
        temp_check = true;
        
    }
        ;

unary_expression: ADDOP unary_expression {
        currentStr = $1->getName()+ $2->getName();
        $$ = new SymbolInfo(currentStr, myStr, $2->getArraySize());
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": unary_expression : ADDOP unary_expression " << endl << endl;
        log << temp_str << endl  << endl; 
        currentStr = $2->getSpecType();

        if($1->getSpecType() == "void") {
            errorName = ": Void function called within expression ";
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++;
            currentLookahead = error_count;
        }
        else{ 
            currentLookahead = 0;
            temp_check = true;
            $$->setSpecType(currentStr);
        }

        if($1->getName() == "+") {
            /* positive number */
            $$->set_assembly_operand($2->get_assembly_operand());
            $$->setCode($2->getCode());
        } else {
            /* negative number */
            string temp = newTemp();
            data_list.push_back(temp+ " dw ?");

            $$->setCode($2->getCode()+"\tmov ax, "+$2->get_assembly_operand()+"\n\tmov "+temp+", ax\n\tneg "+temp+"\n");
            $$->set_assembly_operand(temp);
        } 
            
    } 
	| NOT unary_expression {
        $$ = new SymbolInfo( "!" + $2->getName(), myStr, $2->getArraySize());
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": unary_expression : NOT unary_expression " << endl << endl;
        log << temp_str << endl  << endl;  

        if($2->getSpecType() == "void") {
            errorName = ": Void function called within expression ";
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            currentLookahead = error_count;
        }

        else{ 
            currentLookahead = 0;
            temp_check = true;
            $$->setSpecType($2->getSpecType());
        }

        string label1 = newLabel();
        string label2 = newLabel();

        string temp = newTemp();
        data_list.push_back(temp+(string)" dw ?");

        string code = (string)"\tmov ax, " + $2->get_assembly_operand() + (string)"\n\tcmp ax, 0\n";
        code += "\tje " + label1 + (string) "\n\tmov ax, 0\n\tmov " + temp +(string)", ax\n\tjmp " + label2 + (string)"\n";
        code += (string)"\t" + label1 + (string)": \n\tmov ax, 1\n";
        code += "\tmov " + temp + (string)", ax\n\t" + label2 + (string)":\n";

        $$->setCode(code);
        $$->set_assembly_operand(temp);

    }
	| factor {
        temp_str = $1->getName();
        currentLine = line_count;
        $$ = new SymbolInfo(temp_str, myStr, $1->getArraySize()); 
        log << "Line " << currentLine << ": unary_expression : factor" << endl << endl;
        log << temp_str << endl  << endl;  
        currentStr = $1->getSpecType();
        temp_check = true;
        $$->setSpecType(currentStr);  
        $$->setCode($1->getCode());
        $$->set_assembly_operand($1->get_assembly_operand());
        currentLookahead = myList.size();
    }
    	;

factor: variable {
         temp_str = $1->getName();
         $$ = new SymbolInfo(temp_str, myStr, $1->getArraySize());
         currentLine = line_count;
         log << "Line " << currentLine << ": factor : variable" << endl << endl;
         log << temp_str << endl << endl;
         currentStr = $1->getSpecType();
         currentLookahead = 0;
         temp_check = true;
         $$->setSpecType(currentStr);
         $$->setCode($1->getCode());
         $$->set_assembly_operand($1->get_assembly_operand());

         //cout<<$1->get_assembly_operand()<<endl;

         if($$->getArraySize() > -1) {
            /* array */
            string temp = newTemp();
            data_list.push_back(temp +( string)" dw ?");

            $$->setCode($$->getCode()+(string)"\tmov ax, "+$1->get_assembly_operand()+(string)"[bx]\n\tmov "+temp+(string)", ax\n");
            $$->set_assembly_operand(temp);
        }
    }
	| ID LPAREN argument_list RPAREN{
        currentStr = $1->getName()+"("+ $3->getName() + ")";
        $$ = new SymbolInfo(currentStr, myStr);
        temp_str = $$->getName();
        currentLine = line_count;
        log << "Line " << currentLine << ": factor: ID LPAREN argument_list RPAREN" << endl << endl;
        log << temp_str << endl << endl;
        SymbolInfo* symbolcurrPtr = table->LookUpCurrent($1->getName());
        SymbolInfo* symbolPtr = table->LookUpAll($1->getName());
        currentLookahead = myList.size();
        int prev_error_count = error_count;

        if(symbolPtr == NULL) {
            errorName = ": Undeclared function " + $1->getName();
            temp_check = false;
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++;
        }
        else if(symbolPtr->getArraySize() != -2){
            errorName = ": No such function definition found";
            currentLookahead = error_count;
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++; 
            currentStr = temp_str;
        }
        else
        {
            if(symbolPtr->getPlistSize() != argumentList.size()) {
                errorName = ": Total number of arguments mismatch in function " + symbolPtr->getName();
                error_count++;
                error << "Error at line " << currentLine << errorName << endl << endl;
                log << "Error at line " << currentLine << errorName << endl << endl;
                currentStr = temp_str;
                currentLookahead = myList.size();
            }
            else
            {
                for(int i=0; i<argumentList.size(); i++) { 
                    if(argumentList[i].getVarType() == "undeclared") continue;    
                    if(argumentList[i].getVarSize() != -1)
                    { 
                        errorName = ": Type mismatch, " + argumentList[i].getVarName() + " is an array ";
                        error << "Error at line " << line_count << errorName << endl << endl;
                        log << "Error at line " << line_count << errorName << endl << endl;
                        error_count++;
                        currentLookahead = error_count;
                    }                 
                    else if (symbolPtr->get_Parameter(i).getPtype() != argumentList[i].getVarType()) {
                        errorName = "th argument mismatch in function "+ symbolPtr->getName();
                        error << "Error at line " <<  line_count << ": " << i+1 << errorName << endl << endl;
                        log << "Error at line " <<  line_count << ": " << i+1 << errorName << endl << endl;
                        error_count++;
                        currentStr = temp_str;
                        currentLookahead = myList.size();
                        break;
                    }
                }
            }
            $$->setSpecType(symbolPtr->getSpecType());
            currentLookahead = 0;
        }

        if(prev_error_count == error_count)
        {
            string code = $3->getCode();
            code += (string)"\tpush ax\n\tpush bx\n\tpush address\n";

            string temp = newTemp();
            data_list.push_back(temp + " dw ?");

            for(int i=0; i<sent_arg_list.size(); i++) {
                code += (string)"\tpush " + sent_arg_list[i] + (string)"\n";
            }

            code += (string)"\tcall " + symbolPtr->getName() + (string)"\n";
            if(symbolPtr->getSpecType() != "void") {
                code += (string)"\tpop "+temp+(string)"\n";
            }
            code += (string)"\tpop address\n\tpop bx\n\tpop ax\n";
            $$->setCode(code);
            $$->set_assembly_operand(temp);
        }
        argumentList.clear();
        myList.clear();
        sent_arg_list.clear();
        temp_check = true;
    }
	| LPAREN expression RPAREN{
         currentLine = line_count;
         $$ = new SymbolInfo("("+ $2->getName()+ ")", myStr, $2->getArraySize());
         temp_str = $$->getName();
         temp_check = true;
         log << "Line " << currentLine << ": factor: LPAREN expression RPAREN" << endl << endl;
         log << temp_str << endl << endl;
         currentLookahead = 0;
         $$->setSpecType($2->getSpecType());
         $$->setCode($2->getCode());
         $$->set_assembly_operand($2->get_assembly_operand());
         currentStr = temp_str;
    }
	| CONST_INT {
        temp_str = $1->getName();
        $$ = new SymbolInfo(temp_str, "CONST_INT");
        currentLine = line_count;
        log << "Line " << currentLine << ": factor : CONST_INT" << endl << endl;
        log << temp_str << endl << endl;  
        temp_check = true;
        $$->setSpecType("int");
        $$->set_assembly_operand($1->getName());
        currentStr = temp_str;
    }
	| CONST_FLOAT{
        temp_str = $1->getName();
        $$ = new SymbolInfo(temp_str, "CONST_FLOAT");
        currentLine = line_count;
        log << "At line no: " << currentLine << " factor : CONST_FLOAT" << endl << endl;
        log << temp_str << endl << endl; 
        temp_check = true;
        $$->setSpecType("float");
        currentStr = temp_str;
    }
	| variable INCOP{
         currentLine = line_count;
         $$ = new SymbolInfo($1->getName()+ "++", myStr, $1->getArraySize());
         log << "Line " << currentLine << ": factor : variable INCOP" << endl << endl;
         log << $$->getName() << endl << endl;
         temp_check = true;
         $$->setSpecType($1->getSpecType());

         if($1->getArraySize() > -1) {
            /* array */
            string temp = newTemp();
            data_list.push_back(temp+" dw ?");

            string code = $1->getCode() + "\tmov ax, " + $1->get_assembly_operand() + "[bx]";
            code += "\n\tmov " + temp + ", ax\n" ;
            code += "\tinc "+$1->get_assembly_operand()+"[bx]\n";

            $$->setCode(code); 
            $$->set_assembly_operand(temp);

        } else {
           /* variable */
            string temp = newTemp();
            data_list.push_back(temp + " dw ?");
            $$->setCode($1->getCode()+ "\tmov ax, "+$1->get_assembly_operand()+ "\n\tmov "+temp+ ", ax\n\tinc "+$1->get_assembly_operand()+"\n");
            $$->set_assembly_operand(temp);

        }
         currentStr = temp_str;
    }
	| variable DECOP{
          currentLine = line_count;
          $$ = new SymbolInfo($1->getName()+ "--", myStr, $1->getArraySize());
          temp_str = $$->getName();
          log << "Line " << currentLine << ": factor : variable DECOP" << endl  << endl;
          log << temp_str << endl << endl;
          temp_check = true;
          $$->setSpecType($1->getSpecType());
          if($1->getArraySize() > -1) {
            /* array */
            string temp = newTemp();
            data_list.push_back(temp+" dw ?");
            
            string code = $1->getCode() + "\tmov ax, " + $1->get_assembly_operand() + "[bx]";
            code += "\n\tmov " + temp + ", ax\n" ;
            code += "\tdec "+$1->get_assembly_operand()+"[bx]\n";

            $$->setCode(code); 
            $$->set_assembly_operand(temp);
            
        }
        else {
            /* variable */
            string temp = newTemp();
            data_list.push_back(temp+" dw ?");
            $$->setCode($1->getCode()+"\tmov ax, "+$1->get_assembly_operand()+"\n\tmov "+temp+", ax\n\tdec "+$1->get_assembly_operand()+(string)"\n");
            $$->set_assembly_operand(temp);
        }
          currentStr = temp_str;
    }
	    ;

argument_list: arguments{
        currentLine = line_count;
        temp_str = $1->getName();
        $$ = new SymbolInfo(temp_str, myStr);
        log << "Line " << currentLine << ": argument_list : arguments" << endl << endl;
        log << temp_str << endl  << endl;   
        $$->setCode($1->getCode());
        temp_check = false;
        currentLookahead = 0;
    }
	|   { 
        currentLine = line_count;
        log << "Line " << currentLine << ": argument_list : <epsilon-production>" << endl << endl;
        $$ = new SymbolInfo("", myStr);   
        log << "" << endl << endl;  
        temp_check = false;
        currentLookahead = myList.size();
    }
			;
	
arguments: arguments COMMA logic_expression{
        currentLine = line_count;
        $$ = new SymbolInfo($1->getName()+ ", "+ $3->getName(), myStr);
        temp_str = $$->getName();
        log << "Line " << currentLine << ": arguments : arguments COMMA logic_expression" << endl << endl;
        log << temp_str << endl  << endl;  
        $$->setCode($1->getCode()+$3->getCode()); 
        
        if($3->getSpecType() == "void") {
            errorName = ": Void function called within argument of function ";
            error << "Error at line " << line_count << errorName << endl << endl;
            log << "Error at line " << line_count << errorName << endl << endl;
            error_count++;
            temp_check = false;
            currentLookahead = error_count;
            currentStr = errorName;
        } 

        VariableInfo temp_variable($3->getName(),$3->getSpecType(),$3->getArraySize()); 
        argumentList.push_back(temp_variable);
        currentStr = temp_variable.getVarName();
        sent_arg_list.push_back($3->get_assembly_operand());

    }
	| logic_expression{

        currentLine = line_count;
        $$ = new SymbolInfo($1->getName(), myStr);
        temp_str = $$->getName();
        log << "Line " << currentLine << ": arguments : logic_expression" << endl << endl;
        log << temp_str << endl  << endl;  
        $$->setCode($1->getCode());
        
        // currentStr = temp_variable.getVarName();
        if($1->getSpecType() == "void") 
        {
            errorName = ": Void function called within argument of function ";
            error << "Error at line " << currentLine << errorName << endl << endl;
            log << "Error at line " << currentLine << errorName << endl << endl;
            error_count++;
            temp_check = false;
            currentLookahead = error_count;
            currentStr = errorName;
        } 

        VariableInfo temp_variable($1->getName(),$1->getSpecType(),$1->getArraySize()); 
        argumentList.push_back(temp_variable);
        sent_arg_list.push_back($1->get_assembly_operand());

    }
	      ;
 

%%

int main(int argc,char *argv[])
{
    input = fopen(argv[1], "r");

    if(input == NULL) {
		cout << "input file could not open, program is terminating." << endl;
		exit(0);
	}

	log.open("1805049_log.txt", ios::out);
	error.open("1805049_error.txt", ios::out);
    code.open("1805049_code.asm", ios::out);
    optimized_code.open("1805049_optimized_code.asm", ios::out);

    if(error.is_open() != true) {
		cout << "Error file could not open, program is terminating." << endl;
		fclose(input);	
		exit(0);
	}
	
	if(log.is_open() != true) {
		cout << "log file could not open, program is terminating." << endl;
		fclose(input);	
		exit(0);
	}
	
	if(code.is_open() != true) {
		cout << "code file not opened properly, terminating program..." << endl;
		fclose(input);
		log.close();
		
		exit(0);
	}
	
	if(optimized_code.is_open() != true) {
		cout << "optimized_code file not opened properly, terminating program..." << endl;
		fclose(input);
		log.close();
		
		exit(0);
	}
	
    
	table = new SymbolTable(30);
	yyin = input;
    yyparse();  

    log << endl;
	table->PrintAllScopeTable(log);

	log << "Total Lines: " << (line_count) << endl;  
	log << endl << "Total Errors: " << error_count << endl;
    error << endl << "Total Errors: " << error_count << endl;
	
	fclose(yyin);
	log.close();
	error.close();
	
	return 0;
}