/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       m_read_sdtmig_dset.sas
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       dditommaso
  Program Date:       2019-12-09

  Description:        Read into WORK the CDISC SDTM IG data sets, as needed
                      and return details for the requested PARENT domain data set(s).
  Input(s):           Path and Filename to CDISC SDTM IG Excel file, as published
                      in the CDISC Library Archive:
                        https://www.cdisc.org/members-only/cdisc-library-archives

                      REQUIRED if the work data set does not already exist
                        <PATH> (Relative) path to SDTM IG Excel Metadata
                        <FILE> Name of Excel Metadata file
                        <TAB>  Tab that contains variable attributes, used as string literal
                      OPTIONAL to retrieve var details
                        <DSET> Name of data set(s) to retrieve attributes.
                               Syntax: space-delimited list of domains

  Output(s):          WORK dataset, and domain-specific macro vars:
                        <DOMAIN>_VER
                        <DOMAIN>_CLASS
                        <DOMAIN>_NAME
                        <DOMAIN>_LABEL
                        <DOMAIN>_STRUCT

  Comments:           1. Workbook read only once per session into WORK.
                         DELETE WORK.SDTMIG_DSET_ATTRIBS to force update.
                      2. IMPORT ONLY: just pass in
                         <PATH>, <FILE>, <TAB> to create WORK.SDTMIG_DSET_ATTRIBS

  Revision History:   
  Date:    Author:    Description of Change:
***/

%macro m_read_sdtmig_dset (path=, file=, tab=, dset=) / minoperator;
  %local ok idx nxt qdset cdisc_dsnam;

  %let OK = 1;

  %let dset = %sysfunc(compress(%upcase(&dset),,ask));
  %let qdset = "%sysfunc(transtrn(&dset,%str( ), " "))";

  %if not %sysfunc(exist(sdtmig_dset_attribs)) %then %do;
    %if %length(&path) > 0 and %length(&file) > 0 %then %do;
      %if %qsubstr(&path, %length(&path)) IN (%str(/) %str(\)) 
          %then %let path = %qsubstr(&path,1,%eval(%length(&path)-1));

      libname sdtmig xlsx "&path/&file" access=readonly;

      data sdtmig_dset_attribs;
        keep Version Observation_Class Domain_Name Domain_Label Domain_Structure;
        set sdtmig."&tab"n;
      run;
    %end;
    %else %do;
      %put ERROR: SDTMIG Metadata not available. Please provide path/filename.;
      %let OK = 0;
    %end;
  %end;

  %if &OK and %length(&dset) > 0 %then %do;

    proc sql noprint;
      select upcase(Domain_Name) into: cdisc_dsnam separated by '" "'
      from sdtmig_dset_attribs
      where upcase(Domain_Name) in ( &qdset ) ;
    quit;

    %if &sqlobs = 0 %then 
        %put ERROR: (m_read_sdtmig_dset) CDISC Data Set(s) "&dset" NOT FOUND.;
    %else %do;

      *--- Retrieve requested attributes for unique variable;
      data _null_;
        set sdtmig_dset_attribs;
        where upcase(domain_name) in ( "&cdisc_dsnam" ) ;
        putlog "INFO: CDISC attributes for Data Sets '&dset'";
        putlog 'INFO- version   ' Version ;
        putlog 'INFO- class     ' Observation_Class ;
        putlog 'INFO- Domain    ' Domain_Name ;
        putlog 'INFO- Label     ' Domain_Label ;
        putlog 'INFO- Structure ' Domain_Structure ;
        putlog "INFO: (&sysmacroname) Macro var set created for " domain_name;

        call execute(catx(' ', '%global', 
                               cats(domain_name, '_VER'),   
                               cats(domain_name, '_CLASS'), 
                               cats(domain_name, '_NAME'),  
                               cats(domain_name, '_LABEL'), 
                               cats(domain_name, '_STRUCT'),
                           ';'));

        call symput(cats(domain_name, '_VER'),    strip(Version));
        call symput(cats(domain_name, '_CLASS'),  strip(Observation_Class));
        call symput(cats(domain_name, '_NAME'),   strip(Domain_Name));
        call symput(cats(domain_name, '_LABEL'),  strip(Domain_Label));
        call symput(cats(domain_name, '_STRUCT'), strip(Domain_Structure));

      run;

    %end;
  %end;
  
%quickexit:
%mend m_read_sdtmig_dset;


/*** tests

  %*--- First call creates WORK dset ;
    %m_read_sdtmig_dset(path=../WorkingCDISC/,
                        file=sdtmig-3-3-excel.xlsx,
                        tab=SDTMIG V3.3 DATASETS);

  %*--- Second call DOES NOT re-create WORK dset ;
    %m_read_sdtmig_dset(path=../WorkingCDISC/,
                        file=sdtmig-3-3-excel.xlsx,
                        tab=SDTMIG V3.3 DATASETS);

  %*--- NON-EXISTENT DSET error condition ;
    %m_read_sdtmig_dset(path=../WorkingCDISC/,
                        file=sdtmig-3-3-excel.xlsx,
                        tab=SDTMIG v3.3 Datasets,
                        dset=AAE);

  %*--- INVALID SUPP-- request;
    %m_read_sdtmig_dset(path=../WorkingCDISC/,
                        file=sdtmig-3-3-excel.xlsx,
                        tab=SDTMIG v3.3 Datasets,
                        dset=SUPP--);

  %*--- INVALID SUPP-- request ;
    %m_read_sdtmig_dset(path=../WorkingCDISC/,
                        file=sdtmig-3-3-excel.xlsx,
                        tab=SDTMIG v3.3 Datasets,
                        dset=SUPPAE);

  %*--- VALID DSET request, mixed-case ;
    %m_read_sdtmig_dset(path=../WorkingCDISC/,
                        file=sdtmig-3-3-excel.xlsx,
                        tab=SDTMIG v3.3 Datasets,
                        dset=Ae);

  %*--- VALID DSET request, without specifying source file ;
    %m_read_sdtmig_dset(dset=Dm);

  %*--- MULTIPLE DSET requests, quoted, mostly valid ;
    %m_read_sdtmig_dset(path=../WorkingCDISC/,
                        file=sdtmig-3-3-excel.xlsx,
                        tab=SDTMIG v3.3 Datasets,
                        dset="AE" 'DM' "LB" 'VS' "SuppAe" 'suPP--');
***/
