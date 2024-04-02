
#include <sstream>
#include <string>
#include <fstream>
#include<stdlib.h>
#include<vector>
using namespace std;


class Optimization{
public:

    string createComment(string comment){
        string str = "\n;\t";
        for(int i=0; i<comment.size(); i++){
            if(comment[i]=='\n' and i+1<comment.size()) str += "\n\t;\t";
            else str += comment[i];
        }
        return str + (string)"\n";
    }

    void create_optimized_code(string src_code,ofstream &optimized_code)
    {
        vector<string> lines, line_1, line_2;
        stringstream ss(src_code);
        string temp;

        while(getline(ss, temp, '\n')){
            lines.push_back(temp);
        }

        for(int i=0; i+1<lines.size(); i++)
        {
            if(lines[i].size() < 4 || lines[i+1].size() < 4){
                optimized_code<<lines[i]<<endl;
                continue;
            }
            //if we get "mov" operations two times in a row
            if(lines[i].substr(1, 3) == "mov" && lines[i+1].substr(1, 3)=="mov")
            {
                stringstream ss1(lines[i]), ss2(lines[i+1]);
                while(getline(ss1, temp, ' ')){
                    line_1.push_back(temp);
                }
                while(getline(ss2, temp, ' ')){
                    line_2.push_back(temp);
                }

                string operand_1_line1 = line_1[1].substr(0, line_1[1].size()-1), operand_2_line1 = line_1[2];
                string operand_1_line2 = line_2[1].substr(0, line_1[1].size()-1), operand_2_line2 = line_2[2];

                if(operand_1_line1 == operand_2_line2 && operand_2_line1 == operand_1_line2){
                    
                    optimized_code <<  lines[i] << ";\toptimzed\n"<< endl;
                    i++;
                }
                else{
                    optimized_code << lines[i] << endl;
                }
                line_1.clear();
                line_2.clear();
            }
            else{
                optimized_code << lines[i] << endl;
            }
        }
        optimized_code << lines.back() << endl;
    }
};


//for running variables information
class VariableInfo{
    int varSize;
    string varName;
    string varType;

public:

    VariableInfo(string varName,string varType,int varSize)
    {
        this->varName=varName;
        this->varType=varType;
        this->varSize=varSize;
    }

    string getVarName()
    {
        return varName;
    }
    string getVarType()
    {
        return varType;
    }
    int getVarSize()
    {
        return varSize;
    }

};

class Parameters{
    public:
    string pname,ptype;

    Parameters()
    {

    }

    Parameters(string pname,string ptype)
    {
        this->pname=pname;
        this->ptype=ptype;
    }

    string getPname()
    {
        return pname;
    }
    string getPtype()
    {
        return ptype;
    }

} ;

class SymbolInfo {
    string Name;
    string Type;
    SymbolInfo *nxtPtr;
    

public:

    string code;
	string asm_operand_name;
    vector<Parameters> pList;
    int size;
    string spec_type;

    SymbolInfo(string Name, string Type, int array_size = -1,  string type_specifier = "undeclared") {
        this->size=array_size;
        this->spec_type=type_specifier;
        this->Name = Name;
        this->Type = Type;
        this->nxtPtr = nullptr;
        this->code = "";
    }

    SymbolInfo() {
        nxtPtr = nullptr;
    }

    SymbolInfo *getNxtPtr() const {
        return nxtPtr;
    }

    void setNxtPtr(SymbolInfo *nxtPtr) 
    {
        SymbolInfo::nxtPtr = nxtPtr;
    }


    void setCode(string code)
    {
		this->code = code;
	}
	string getCode()
    {
		return code;
	}

	void set_assembly_operand(string asm_operand_name)
    {
		this->asm_operand_name = asm_operand_name;
	}
	string get_assembly_operand()
    {
		return this->asm_operand_name;
	}

    const string &getName() const {
        return Name;
    }

    void setName(const string &name) {
        Name = name;
    }


    string getSpecType()
	{
		return spec_type;
	}
	void setSpecType(string spec_type)
	{
		this->spec_type = spec_type;
	}

	int getArraySize(){
		return size;
	}
	void setArraySize(int size){
		this->size = size;
	}

    const string &getType() const {
        return Type;
    }

    void setType(const string &type) {
        Type = type;
    }

	void add_Parameter(string ptype, string pname)
	{
		Parameters p(pname,ptype);
		pList.push_back(p);
	}

    int getPlistSize(){
		return pList.size();
	}

	Parameters get_Parameter(int index){
        return pList[index];
    }


    virtual ~SymbolInfo() {
        free(nxtPtr);
    }

};

class ScopeTable {
private:
    int total_buckets;
    int uniqueIdNo;
    SymbolInfo *parentScopeMaintain;
    SymbolInfo **arrayOfPtr; //array of pointers of SymbolInfo type
    ScopeTable *parentScope;
    int total_child;
    string uniqueID;

public:
    ScopeTable(int total_buckets) {

        this->total_child = 0;
        this->uniqueIdNo = 0;
        this->uniqueID = "1";
        this->total_buckets = total_buckets;
        arrayOfPtr = new SymbolInfo *[total_buckets];
        for (int i = 0; i < total_buckets; ++i) {
            arrayOfPtr[i] = nullptr;
        }
        parentScope = nullptr;
        parentScopeMaintain = nullptr;
    }

    SymbolInfo *getParentScopeMaintain() const {
        return parentScopeMaintain;
    }

    void setParentScopeMaintain(SymbolInfo *parentScopeMaintain) {
        ScopeTable::parentScopeMaintain = parentScopeMaintain;
    }

    int getTotalBuckets() const {
        return total_buckets;
    }

    void setTotalBuckets(int totalBuckets) {
        total_buckets = totalBuckets;
    }

    int getUniqueIdNo() const {
        return uniqueIdNo;
    }

    void setUniqueIdNo(int uniqueIdNo) {
        ScopeTable::uniqueIdNo = uniqueIdNo;
    }

    SymbolInfo **getArrayOfPtr() const {
        return arrayOfPtr;
    }

    void setArrayOfPtr(SymbolInfo **arrayOfPtr) {
        ScopeTable::arrayOfPtr = arrayOfPtr;
    }

    ScopeTable *getParentScope() const {
        return parentScope;
    }

    void setParentScope(ScopeTable *parentScope) {
        ScopeTable::parentScope = parentScope;
    }

    int getTotalChild() const {
        return total_child;
    }

    void setTotalChild(int totalChild) {
        total_child = totalChild;
    }

    const string &getUniqueId() const {
        return uniqueID;
    }

    void setUniqueId(const string &uniqueId) {
        uniqueID = uniqueId;
    }

    static unsigned long sdbmhash(unsigned char *str) {

        unsigned long hash = 0;
        int c;

        while ((c = *str++)) {
            hash = c + (hash << 6) + (hash << 16) - hash;
        }

        return hash;
    }

    int hashFunc(string name) {
        return sdbmhash((unsigned char *) name.c_str()) % getTotalBuckets();

    }

    bool Insert(const string &symbolName, const string &symbolType, int arr_size = -1, string type_specifier="") {
        bool check = true;
        int position = 0;
        SymbolInfo *temp= nullptr;

        auto *newSymbol = new SymbolInfo(symbolName, symbolType, arr_size, type_specifier);
        SymbolInfo *currentPtr = arrayOfPtr[getIndex(symbolName)];
        SymbolInfo *previousPtr = currentPtr;

        if (currentPtr != nullptr) {
            while (currentPtr != nullptr) {
                if (currentPtr->getName() != symbolName) {
                    temp = parentScopeMaintain;
                    position++;
                    previousPtr = currentPtr;
                    currentPtr = currentPtr->getNxtPtr();
                    parentScopeMaintain=currentPtr;
                } else {
                    temp = currentPtr;
                    //cout << "<" << symbolName << "," << symbolType << "> already exists in current ScopeTable" << endl;
                    check = false;
                    parentScopeMaintain=currentPtr;
                    break;
                }
            }
            if (!check) return false;
            else {
                temp = newSymbol;
                previousPtr->setNxtPtr(newSymbol);
                parentScopeMaintain=newSymbol;
                //cout << "Inserted in ScopeTable# " << this->getUniqueId() << " at position " << getIndex(symbolName) << ", "<< position << endl;
                return true;
            }
        }
        else{
            check = true;
            temp = newSymbol;
            arrayOfPtr[getIndex(symbolName)] = newSymbol;
            parentScopeMaintain = newSymbol;
            //cout << "Inserted in ScopeTable# " << this->getUniqueId() << " at position " << getIndex(symbolName) << ", " << position << endl;
            return true;
        }

    }





    bool Insert(SymbolInfo* p )
	{

		SymbolInfo *symbol = new SymbolInfo(p->getName(), p->getType(), p->getArraySize(), p->getSpecType());
		for(int i=0; i < p->pList.size(); i++)
        {
            symbol->add_Parameter(p->pList[i].getPtype() , p->pList[i].getPname());
        }
			
		int pos = 0;
        int idx = getIndex(p->getName());

		if (arrayOfPtr[idx] == NULL)
		{
			arrayOfPtr[idx] = symbol;
			cout << "Inserted in ScopeTable# " << this->getUniqueId() << " at position " << idx << ", " << pos << endl;
			return true;
		}

		SymbolInfo *cur = arrayOfPtr[idx], *prev = arrayOfPtr[idx];
		while (cur != NULL)
		{
			if (cur->getName() == p->getName())
			{
				cout << "<" << p->getName() << "," << p->getType() << "> already exists in current ScopeTable" << endl;
				return false;
			}
			prev = cur;
            cur = cur->getNxtPtr();
			pos++;
		}
		
        prev->setNxtPtr(symbol);
		cout << "Inserted in ScopeTable# " << this->getUniqueId() << " at position " << idx << ", " << pos << endl;
		return true;
	}




    bool Delete(string symbolName) {
        bool check = false;
        int position = 0;

        SymbolInfo *currentPtr = arrayOfPtr[getIndex(symbolName)];
        SymbolInfo *previousPtr = currentPtr;
        SymbolInfo *temp = nullptr;

        while (currentPtr != nullptr) {
            if (currentPtr->getName() == symbolName) {
                if (position == 0) arrayOfPtr[getIndex(symbolName)] = currentPtr->getNxtPtr();//first element delete
                else previousPtr->setNxtPtr(currentPtr->getNxtPtr());

                check= true;
                temp = parentScopeMaintain;
                parentScopeMaintain=currentPtr;
                free(currentPtr);
                //cout << "Deleted Entry " << getIndex(symbolName) << ", " << position << " from current ScopeTable " << endl;
                return true;
            }
            else {
                check = false;
                temp = previousPtr;
                parentScopeMaintain->setNxtPtr(currentPtr);
                previousPtr = currentPtr;
                currentPtr = currentPtr->getNxtPtr();
                position++;
                parentScopeMaintain = previousPtr;
            }
        }

        return false;


    }

    int getIndex(string symbolName)
    {
        return hashFunc(symbolName);
    }

    static int getPosition(SymbolInfo *currentPtr,string symbolName)
    {
        int pos=0;
        while (currentPtr!= nullptr)
        {
            if (currentPtr->getName() == symbolName) return pos;
            pos++;
            currentPtr = currentPtr->getNxtPtr();
        }
        return -1;
    }

    SymbolInfo *LookUp(string symbolName) {
        bool check = false;
        int position = 0;

        SymbolInfo *currentPtr = arrayOfPtr[getIndex(symbolName)];
        SymbolInfo *tempPtr = nullptr;

        while (currentPtr != nullptr) {

            if (currentPtr->getName() == symbolName) {
                check= true;
                tempPtr = currentPtr;
                parentScopeMaintain=currentPtr;
                //cout << "Found in ScopeTable# " << getUniqueId() << " at position " << getIndex(symbolName) << ", " << position << endl;
                return tempPtr;
            }
            else {
                parentScopeMaintain=currentPtr;
                currentPtr = currentPtr->getNxtPtr();
                position++;
            }
        }
        return nullptr;
    }

    void Print(ofstream &out) {
        SymbolInfo *temp= nullptr;
        out << "ScopeTable # " << getUniqueId() << endl;
        for (int i = 0; i < getTotalBuckets(); i++) {
            SymbolInfo *currentPtr = arrayOfPtr[i];
            if(currentPtr == NULL) continue;
            out << i << " -->";
            
            while (currentPtr) {
                out << " < " << currentPtr->getName() << " : " << currentPtr->getType() << " > ";
                currentPtr = currentPtr->getNxtPtr();
                temp = parentScopeMaintain;
                parentScopeMaintain = currentPtr;
            }
            out << endl;
        }
        out << endl;
    }

    virtual ~ScopeTable() {
        for (int i = 0; i < getTotalBuckets(); ++i) {
            free(arrayOfPtr[i]);
        }
        free(parentScope);
        free(parentScopeMaintain);
        free(arrayOfPtr);
    }

};

class SymbolTable {
    ScopeTable *scopeTableCurrentPtr;
    int total_buckets;

public:
    SymbolTable(int total_buckets) {
        scopeTableCurrentPtr = new ScopeTable(total_buckets);
        this->total_buckets = total_buckets;

    }

    ScopeTable *getScopeTableCurrentPtr() const {
        return scopeTableCurrentPtr;
    }

    void setScopeTableCurrentPtr(ScopeTable *scopeTableCurrentPtr) {
        SymbolTable::scopeTableCurrentPtr = scopeTableCurrentPtr;
    }

    int getTotalBuckets() const {
        return total_buckets;
    }

    void setTotalBuckets(int totalBuckets) {
        total_buckets = totalBuckets;
    }


    void generateId(ScopeTable *newCurrentPtr,int id)
    {
        newCurrentPtr->setParentScope(scopeTableCurrentPtr);
        int totalChild= getChildNo(newCurrentPtr);
        newCurrentPtr->getParentScope()->setTotalChild(totalChild+ 1);
        //newCurrentPtr->setUniqueId(newCurrentPtr->getParentScope()->getUniqueId() + "." +to_string(totalChild + 1));
        newCurrentPtr->setUniqueId(to_string(id));
    }

    int getChildNo(ScopeTable *newCurrentPtr)
    {
        return newCurrentPtr->getParentScope()->getTotalChild();
    }



    void EnterScope(ofstream &out,int id) {
        auto *newCurrentPtr = new ScopeTable(total_buckets);

        // if (scopeTableCurrentPtr!= nullptr) generateId(newCurrentPtr,id);

        if (scopeTableCurrentPtr!= nullptr)
        {
            newCurrentPtr->setParentScope(scopeTableCurrentPtr);
            int totalChild= newCurrentPtr->getParentScope()->getTotalChild();
            newCurrentPtr->getParentScope()->setTotalChild(totalChild+ 1);
            //newCurrentPtr->setUniqueId(newCurrentPtr->getParentScope()->getUniqueId() + "." +to_string(totalChild + 1));
            newCurrentPtr->setUniqueId(to_string(id));
        }


        scopeTableCurrentPtr=newCurrentPtr;
        //out << "New ScopeTable with id " << scopeTableCurrentPtr->getUniqueId() << " created " << endl;
    }

    void PrintCurrentScopeTable(ofstream &out) {
        scopeTableCurrentPtr->Print(out);
    }

    void PrintAllScopeTable(ofstream &out) {

        ScopeTable* temp=scopeTableCurrentPtr;
        while (temp!= nullptr)
        {
            temp->Print(out);
            temp=temp->getParentScope();
        }
    }

    bool Insert(string name, string type, int array_sz =-1, string _type_specifier = "") {
        return scopeTableCurrentPtr->Insert(name, type, array_sz, _type_specifier);
    }

    bool InsertSymbol(SymbolInfo *symbolinfo)
	{
		return scopeTableCurrentPtr->Insert(symbolinfo);
		
	}

    SymbolInfo *LookUpAll(string symbolName)
    {
        ScopeTable* temp=scopeTableCurrentPtr;
        SymbolInfo *symbolInfoTmp;
        while (temp!= nullptr)
        {
            symbolInfoTmp=temp->LookUp(symbolName);
            if (symbolInfoTmp!= nullptr)
            {
                return symbolInfoTmp;
            }
            temp=temp->getParentScope();
        }
        //cout<<"Not Found"<<endl;
        return nullptr;
    }

    pair<string,SymbolInfo *> LookUpAll2(string symbolName)
    {
        ScopeTable* temp=scopeTableCurrentPtr;
        SymbolInfo *symbolInfoTmp;
        while (temp!= nullptr)
        {
            symbolInfoTmp=temp->LookUp(symbolName);
            if (symbolInfoTmp!= nullptr)
            {
                //return symbolInfoTmp;
                return std::make_pair(temp->getUniqueId(),symbolInfoTmp);
            }
            temp=temp->getParentScope();
        }
        //cout<<"Not Found"<<endl;
        //return nullptr;
    }



	SymbolInfo* LookUpCurrent(string symbolName)
	{
		SymbolInfo *temp = scopeTableCurrentPtr->LookUp(symbolName);
		if (temp != NULL) return temp;

		//cout << "Not Found " << endl;
		return NULL;
	}


    void ExitScope(ofstream &out)
    {
        if (scopeTableCurrentPtr== nullptr) return;
        //out << "ScopeTable with id " << scopeTableCurrentPtr->getUniqueId() << " removed " << endl;
        scopeTableCurrentPtr=scopeTableCurrentPtr->getParentScope();
    }

    bool Remove(string symbolName)
    {

        SymbolInfo *temp=scopeTableCurrentPtr->LookUp(symbolName);

        if (temp != nullptr)
        {
            return scopeTableCurrentPtr->Delete(symbolName);
        }
        else{
            //cout<<"Not Found."<<endl<<endl;
            cout<<symbolName<<" not found"<<endl;
            return false;
        }

    }

    char ToConstchar(string currentLexeme)
    {
        char ch=currentLexeme[2];
        
        if(currentLexeme[1]!='\\'){
            return currentLexeme[1];
        }
        else{
            if(ch=='n')
                return (char) 10;
            else if(ch=='0')
                return (char) 0;
            else if(ch=='v')
                return (char) 11;
            else if(ch=='b')
                return (char) 8;
            else if(ch=='t')
                return (char) 9;
            else if(ch=='a')
                return (char) 7;
            else if(ch=='f')
                return (char) 12;
            else if(ch=='r')
                return (char) 13;
            else if(ch=='\\')
                return (char) 92;
            else if(ch=='\'')
                return (char) 39;
            else //if(ch=='\"')
                return (char) 34;
        }
    }

    virtual ~SymbolTable() {

        ScopeTable *temp=scopeTableCurrentPtr;
        while (temp!= nullptr)
        {
            scopeTableCurrentPtr=scopeTableCurrentPtr->getParentScope();
            free(temp);
            temp=scopeTableCurrentPtr;
        }

    }

};


