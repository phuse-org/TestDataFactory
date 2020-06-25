/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       m_query_tdf_config.sas
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       dditommaso
  Program Date:       2020-06-25

  Description:        IN-LINE MACRO - does not generate Base SAS code
                      Simple initial version of querying TDF config settings
                      from the WORK data sets read in from TrialDesignMatrix_for_TDF_study.xlsm
  Input(s):           <TBL>   REQ POSITIONAL ARGUMENT
                              Available tables are SDTM_CONFIG, TA, TS
                              These WORK data sets must exist. First call m_read_tdmatrix.sas
                      <VAR>   REQ POSITIONAL ARGUMENT
                              Variable in &TBL that holds the desired setting
                      <WHR>   REQ POSITIONAL ARGUMENT
                              WHERE clause that uniquely identifies a single config record in &TBL
                              QUOTED as needed by user
                              EG: %str(upcase(cfparmcd)="SITEWGT"))
                              Used in a %sysfunc(open()) call.
                      <FMT>   OPT KEYWORD ARGUMENT
                              Put format, to correct raw config value
                              Provide fmt or infmt, not both. Macro uses first available
                      <INFMT> OPT KEYWORD ARGUMENT
                              Input format, to correct raw config value
                              Provide fmt or infmt, not both. Macro uses first available
  Output(s):          In-line response of null (value not found) or appropriately (in)formatted setting
  Comments:           
  Revision History:   
  Date:    Author:    Description of Change:
***/

%macro m_query_tdf_config(  tbl
                          , var
                          , whr
                          , fmt=%str()
                          , infmt=%str()
                          ) / minoperator;

  %local dsid rc resnum restype res resfmt;

  %let tbl=%sysfunc(strip(%upcase(&tbl)));
  %let var=%sysfunc(strip(%upcase(&var)));
  %let whr=%sysfunc(strip(%superq(whr)));
  %if %length(&fmt) > 0 %then %let fmt=%sysfunc(strip(%upcase(&fmt)));
  %if %length(&infmt) > 0 %then %let infmt=%sysfunc(strip(%upcase(&infmt)));

  %if "&tbl" # ("SDTM_CONFIG" "TA" "TS") %then %do;
    %let dsid = %sysfunc(open(&tbl(where=(&whr))));

    %if &dsid > 0 %then %do;
      %let rc = %sysfunc(fetch(&dsid));

      %if &rc = 0 %then %do;
        %let resnum  = %sysfunc(varnum(&dsid, &var));
        %let restype = %sysfunc(vartype(&dsid, &resnum));

        %if &restype = C %then %let res = %sysfunc(getVarC(&dsid, &resnum));
        %if &restype = N %then %let res = %sysfunc(getVarN(&dsid, &resnum));

        %if %length(&fmt) > 0 %then %do;
          %if %length(&infmt) > 0 %then %put WARNING: (&sysmacroname) FMT and INFMT both specified. Using FMT &fmt..;
          %let res = %sysfunc(put&restype(&res, &fmt));
        %end;
        %else %if %length(&infmt) > 0 %then %do;
          %let res = %sysfunc(input&restype(&res, &infmt));
        %end;

        &res.
      %end;
      %else %do;
        %put WARNING: (&sysmacroname) is unable to open [&tbl (where=(&whr))].;
        %put WARNING- (&sysmacroname) Exiting macro.;
      %end;

      %let dsid = %sysfunc(close(&dsid));
    %end;
    %else %do;
      %put WARNING: (&sysmacroname) is unable to fetch a fetch a record from [&tbl (where=(&whr))].;
      %put WARNING- (&sysmacroname) Exiting macro.;
    %end;
  %end;

%mend m_query_tdf_config;

/*** TESTS

  %put Sdtm_Config CFVal for SiteWgt [%m_query_tdf_config(sdtm_Config, CFval, %str(upcase(cfparmcd)="SITEWGT"))];
  %put Sdtm_Config CFVal for TrtLen [%m_query_tdf_config(sdtm_Config, CFval, %str(upcase(cfparmcd)="TRTLEN"))];
  %put ts tsval for SstDtc [%m_query_tdf_config(Ts, TsVal, %str(upcase(tsparmcd)="SSTDTC"), infmt=yymmdd10)];

***/
