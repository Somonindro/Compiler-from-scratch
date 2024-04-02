%option noyywrap

%{
#include<iostream>
#include<string.h>
#include<fstream>
#include<stdlib.h>
#include "MySymbolTable.h"
#include "y.tab.h"

using namespace std;

void yyerror(char*);
int line_count = 1;
int error_count = 0;

%}


DIGIT [0-9]
LETTER [A-Za-z]
DELIM [ \t\r\f\v]
NEWLINE (\r)?\n
WHITESPACE {DELIM}+
ID (_|{LETTER})(_|{LETTER}|{DIGIT})*
INTEGER {DIGIT}+
NUMBER {DIGIT}+("."{DIGIT}+)?(E[+-]?{DIGIT}+)?
ADDOP [+-] 
MULOP [*/%]


%%

{DELIM}+ { /* do nothing for whitespace*/ }
{NEWLINE} { line_count++; }  

"if" {return IF;}
"else" {return ELSE;}
"for" {return FOR;}
"while" {return WHILE;}
"int" {return INT;}
"float" {return FLOAT;}
"return" {return RETURN;}
"void" {return VOID;}
"println"|"printf" {return PRINTLN;}


{ADDOP}	{
            SymbolInfo* s = new  SymbolInfo(yytext, "ADDOP");
            yylval.symbolInfoPtr = s;
            return ADDOP;
        }


{MULOP}	{
            SymbolInfo* s = new  SymbolInfo(yytext, "MULOP");
            yylval.symbolInfoPtr = s;
            return MULOP;
        }


"=" 	{return ASSIGNOP;}

">"		|
"<"		|
">="	|
"<="	|
"=="	|
"!="	{
            SymbolInfo* s = new  SymbolInfo(yytext, "RELOP");
            yylval.symbolInfoPtr = s;
            return RELOP;
		}


"&&"    |
"||"	{
            SymbolInfo* s = new  SymbolInfo(yytext, "LOGICOP");
            yylval.symbolInfoPtr = s;
            return LOGICOP;
        }

"!"	    { return NOT;}


";" 	{ return SEMICOLON;}
"," 	{return COMMA;}
"(" 	{return LPAREN;}
")" 	{return RPAREN;}
"{" 	{return LCURL;}
"}" 	{return RCURL;}
"[" 	{return LTHIRD;}
"]" 	{return RTHIRD;}
"++" 	{return INCOP;}
"--" 	{return DECOP;}

{INTEGER}	{
				SymbolInfo *s= new  SymbolInfo(yytext, "CONST_INT");
				yylval.symbolInfoPtr = s;
				return CONST_INT;
			}

{NUMBER} 	{	
				SymbolInfo *s= new  SymbolInfo(yytext, "CONST_FLOAT");
				yylval.symbolInfoPtr = s;
				return CONST_FLOAT; 
			}


{ID}     {
            SymbolInfo* s = new SymbolInfo(yytext, "ID");
            yylval.symbolInfoPtr = s;    
            return ID;
        }


%%


