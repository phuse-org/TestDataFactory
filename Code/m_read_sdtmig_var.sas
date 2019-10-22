/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       m_read_sdtmig_var.sas
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       dditommaso
  Program Date:       2019-10-21

  Description:        Read into WORK the CDISC SDTM IG variables, as needed
                      and return details for the requested variable,
                      either to the log, or as an ATTRIB statement.
  Input(s):           Path and Filename to CDISC SDTM IG Excel file, as published
                      in the CDISC Library Archive:
                        https://www.cdisc.org/members-only/cdisc-library-archives

                      REQUIRED if the work data set does not already exist
                        <PATH> (Relative) path to SDTM IG Excel Metadata
                        <FILE> Name of Excel Metadata file
                        <TAB>  Tab that contains variable attributes, used as string literal
                      OPTIONAL to retrieve var details
                        <VAR>  Name of variable to retrieve attributes. 
                               Caller must specify a UNIQUE VARNAME, 
                               which may require specifying DOMAIN.
                               Syntax:
                                 (<domain-prefix>.)variable-name
                                 "variable-name" is sufficient if this uniquely identifies a var
                                 "domain-prefix.variable-name" should otherwise be specified
                        <MACVAR> A global macro var to contain a PARTIAL attrib statement 
                               - CDISC does not specify LENGTH, which the caller can add
                                 to complete this ATTRIB statement.

  Output(s):          WORK dataset, and either Var attributes in log, or as ATTRIB statement

  Comments:           1. Workbook read only once per session into WORK.
                         DELETE WORK.SDTMIG_VAR_ATTRIBS to force update.
                      2. IGNORE the CDISC variable "Variable Name (minus domain prefix)",
                         rely just on the "Domain Prefix" and "Variable Name" columns
                      3. IMPORT ONLY: just pass in
                         <PATH>, <FILE>, <TAB> to create WORK.SDTMIG_VAR_ATTRIBS
                      4. RETRIEVE attributes of unique variable: pass in optional
                         <VAR> and <MACVAR>, to get a partial ATTRIB statement

  Revision History:   
  Date:    Author:    Description of Change:
***/

%macro m_read_sdtmig_var (path=, file=, tab=, var=, macvar=) / minoperator;
  %local dfx uvnm cdisc_vnam;

  %let var = %upcase(&var);
  %let macvar = %upcase(&macvar);
  %if %length(&macvar) > 0 %then %global &macvar ;

  %if not %sysfunc(exist(sdtmig_var_attribs)) %then %do;
    %if %qsubstr(&path, %length(&path)) IN (%str(/) %str(\)) 
        %then %let path = %qsubstr(&path,1,%eval(%length(&path)-1));

    libname sdtmig xlsx "&path/&file" access=readonly;

    data sdtmig_var_attribs;
      keep VERSION OBSERVATION_CLASS DOMAIN_PREFIX 
           VARIABLE_NAME VARIABLE_LABEL TYPE CONTROLLED_TERMS_OR_FORMAT
           ROLE CORE;
      set sdtmig."&tab"n;
    run;
  %end;

  %if %length(&var) > 0 %then %do;
    %if %index(&var,.) %then %do;
      %let dfx = %qscan(&var,1,.);
      %let var = %qscan(&var,-1,.);
      %let uvnm = %sysfunc(cats(&dfx,&var));
    %end;

    proc sql noprint;
      select upcase(variable_name) into: cdisc_vnam separated by ' '
      from sdtmig_var_attribs
      where %if %length(&dfx) > 0 %then upcase(domain_prefix) = "&dfx" and;
            upcase(variable_name) = "&var" ;
    quit;

    %if &sqlobs = 0 %then 
        %put ERROR: (m_read_sdtmig_var) CDISC Variable "&var", Domain "&dfx" NOT FOUND.;
    %else %if &sqlobs > 1 %then 
        %put ERROR: (m_read_sdtmig_var) CDISC Variable "&var", Domain "&dfx" IS NOT UNIQUE.;
    %else %do;

      *--- Retrieve requested attributes for unique variable;
      data _null_;
        set sdtmig_var_attribs;
        where %if %length(&dfx) %then upcase(domain_prefix) = "&dfx" and;
              upcase(variable_name) = "&var";
        putlog "INFO: CDISC attributes for Variable '&var', Domain '&dfx'";
        putlog '      type         ' type ;
        putlog '      label        ' variable_label;
        putlog '      CT or format ' controlled_terms_or_format;
        putlog '      role         ' role;
        putlog '      core         ' core;

        %if %length(&macvar) > 0 
            %then call symput("&macvar", 
                              catx(' ', 
                                   'attrib', variable_name,
                                   'label =', quote(strip(variable_label))));;
      run;

      %if %length(&macvar) > 0 
          %then %put INFO: (m_read_sdtmig_var) Macro var &macvar created with value [&&&macvar];
    %end;
  %end;
  
%mend m_read_sdtmig_var;


/*** tests
  libname sdtmig xlsx "../_Offline_/sdtmig-3-3-excel.xlsx" access=readonly;

  %*--- First call creates WORK dset ;
    %m_read_sdtmig_var(path=../_Offline_/,
                       file=sdtmig-3-3-excel.xlsx,
                       tab=SDTMIG V3.3 VARIABLES);

  %*--- Second call DOES NOT re-create WORK dset ;
    %m_read_sdtmig_var(path=../_Offline_/,
                       file=sdtmig-3-3-excel.xlsx,
                       tab=SDTMIG V3.3 VARIABLES);

  %*--- NON-EXISTENT VAR error condition ;
    %m_read_sdtmig_var(path=../_Offline_/,
                       file=sdtmig-3-3-excel.xlsx,
                       tab=SDTMIG V3.3 VARIABLES,
                       var=MyIdVar);

  %*--- NON-UNIQUE VAR error condition ;
    %m_read_sdtmig_var(path=../_Offline_/,
                       file=sdtmig-3-3-excel.xlsx,
                       tab=SDTMIG V3.3 VARIABLES,
                       var=IdVar);

  %*--- UNIQUE VAR condition, no macro var ;
    %m_read_sdtmig_var(path=../_Offline_/,
                       file=sdtmig-3-3-excel.xlsx,
                       tab=SDTMIG V3.3 VARIABLES,
                       var=RelRec.IdVar);

  %*--- UNIQUE VAR condition, no macro var, without specifying source file ;
    %m_read_sdtmig_var(var=RelRec.IdVar);

  %*--- UNIQUE VAR condition, CREATE macro var ;
    %m_read_sdtmig_var(path=../_Offline_/,
                       file=sdtmig-3-3-excel.xlsx,
                       tab=SDTMIG V3.3 VARIABLES,
                       var=RelRec.IdVar,
                       macvar=MyAttrib);

  %*--- UNIQUE VAR condition, CREATE macro var, without specifying source file ;
    %m_read_sdtmig_var(var=RelRec.IdVar,
                       macvar=MyAttrib);
***/
