/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       m_query_tdf_config.sas
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       dditommaso
  Program Date:       2020-06-25

  Description:        IN-LINE MACRO - does not generate Base SAS code
                      Simple initial version of querying WORK data set SETTINGS created by
                      macro M_READ_TDMATRIX from the
                      config workbook TrialDesignMatrix_for_TDF_study.xlsm
  Input(s):           <PARMCD> REQ POSITIONAL ARGUMENT
                               String, PARMCD of desired setting
                      <PORV>   REQ POSITIONAL ARGUMENT
                               PARM or VAL, to return either the label or value for this setting
                               Defaults to VAL.
                      <FMT>    OPT KEYWORD ARGUMENT
                               Put format, to correct raw config value
                               Ignored for PARM requests
                               Provide fmt or infmt, not both. Macro uses first available
                      <INFMT>  OPT KEYWORD ARGUMENT
                               Input format, to correct raw config value
                               Ignored for PARM requests
                               Provide fmt or infmt, not both. Macro uses first available
  Output(s):          In-line response of null (value not found) or appropriately (in)formatted setting
  Comments:           
  Revision History:   
  Date:    Author:    Description of Change:
***/

%macro m_query_tdf_config(  parmcd
                          , porv
                          , fmt=%str()
                          , infmt=%str()
                          );

  %local dsid rc resnum restype res resfmt;

  %if %length(&parmcd) > 0 %then %let parmcd=%sysfunc(strip(%upcase(&parmcd)));
  %if %length(&porv) > 0 %then %let porv=%sysfunc(strip(%upcase(&porv)));

  %if "&porv" ne "PARM" %then %let porv = VAL;
  %if %length(&fmt) > 0 %then %let fmt=%sysfunc(strip(%upcase(&fmt)));
  %if %length(&infmt) > 0 %then %let infmt=%sysfunc(strip(%upcase(&infmt)));

  %let dsid = %sysfunc(open(settings (where=(upcase(parmcd)="&parmcd"))));

  %if &dsid > 0 %then %do;
    %let rc = %sysfunc(fetch(&dsid));

    %if &rc = 0 %then %do;
      %let resnum  = %sysfunc(varnum(&dsid, &porv));
      %let restype = %sysfunc(vartype(&dsid, &resnum));

      %*--- For now, PARM and VAL are both C vartypes ---*;
      %if &restype = C %then %let res = %sysfunc(getVarC(&dsid, &resnum));
      %if &restype = N %then %let res = %sysfunc(getVarN(&dsid, &resnum));

      %if &porv = VAL %then %do;
        %if %length(&fmt) > 0 %then %do;
          %if %length(&infmt) > 0 %then %put WARNING: (&sysmacroname) FMT and INFMT both specified. Using FMT &fmt..;
          %let res = %sysfunc(put&restype(&res, &fmt));
        %end;
        %else %if %length(&infmt) > 0 %then %do;
          %let res = %sysfunc(input&restype(&res, &infmt));
        %end;
      %end;

      &res.
    %end;
    %else %do;
      %put WARNING: (&sysmacroname) is unable to fetch an obs from SETTINGS (WHERE=(UPCASE(PARMCD)="&PARMCD")).;
      %put WARNING- (&sysmacroname) Exiting macro.;
    %end;

    %let dsid = %sysfunc(close(&dsid));
  %end;
  %else %do;
    %put WARNING: (&sysmacroname) is unable to open SETTINGS (WHERE=(UPCASE(PARMCD)="&PARMCD")).;
    %put WARNING- (&sysmacroname) Exiting macro.;
  %end;

%mend m_query_tdf_config;

/*** TESTS

  %put Sdtm_Config CFVal for SiteWgt [%m_query_tdf_config2(SiteWgt)];
  %put Sdtm_Config CFVal for SiteWgt [%m_query_tdf_config2(SiteWgt, Val)];
  %put Sdtm_Config CFVal for SiteWgt [%m_query_tdf_config2(SiteWgt, Parm)];
  %put Sdtm_Config CFVal for TrtLen [%m_query_tdf_config2(TRTlen, Val)];
  %put Sdtm_Config CFVal for TrtLen [%m_query_tdf_config2(TRTlen, Parm)];
  %put ts tsval for SstDtc [%m_query_tdf_config2(SSTdtc, val, infmt=yymmdd10)];

***/
