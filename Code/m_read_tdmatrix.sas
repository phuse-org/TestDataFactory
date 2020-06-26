/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       m_read_tdmatrix.sas
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       dditommaso
  Program Date:       2019-09-29

  Description:        Read into WORK the main TDF Trial Design Matrix (TDM) tabs
                        - TS, TA, SDTM_Configuration
  Input(s):           Path and Filename to Test Data Factory TDM workbook
  Output(s):          WORK datasets
                        + TS, TA, SDTM_CONFIG
                        + SETTINGS - convenience dset for retrieving subset of 
                          --PARMCD/--PARM/--VAL settings from
                          TS and SDTM_CONFIG
                      MACRO variables for
                        + tdf_studyid - Study ID, from TS var STUDYID
                        + tdf_plansub - Planned # Subjs, from TS var PLANSUB
                        + tdf_title   - Trial name, from TS var TITLE
                        + tdf_trt     - Investigational Drug name, from TS var TRT
  Comments:           
  Revision History:   
  Date:    Author:    Description of Change:
***/

%macro m_read_tdmatrix(path=, file=) / minoperator;
  %global tdf_studyid tdf_plansub tdf_title tdf_trt;

  %if %qsubstr(&path, %length(&path)) IN (%str(/) %str(\)) 
      %then %let path = %qsubstr(&path,1,%eval(%length(&path)-1));

  libname tdfstudy xlsx "&path/&file" access=readonly;

  data ts;
    set tdfstudy.ts (where=(not missing(tsparmcd)));

    select(upcase(tsparmcd));
      when('TITLE') do;
                       call symput('tdf_studyid', strip(studyid));
                       call symput('tdf_title', strip(tsval));
                     end;
      when('TRT') call symput('tdf_trt', strip(tsval));
      when('PLANSUB') call symput('tdf_plansub', strip(tsval));
      otherwise;
    end;

    array chars [*] $_character_;
    array ucchr [2] $ domain tsparmcd;
    do idx = 1 to dim(chars);
      chars[idx] = strip(chars[idx]);
      chars[idx] = compress(chars[idx], '090A0D'x);
    end;
    do idx = 1 to dim(ucchr);
      chars[idx] = upcase(chars[idx]);
    end;
    drop idx;
  run;

  data ta;
    set tdfstudy.ta (where=(not missing(armcd)));
  run;

  data sdtm_config;
    set tdfstudy.tdf_configuration (where=(not missing(cfdomain)));
  run;

  %local ts_len sd_len;

  proc sql noprint;
    select length into: ts_len separated by ' '
    from dictionary.columns
    where upcase(libname ) = 'WORK' and upcase(memname) = 'TS'
          and upcase(name) in ('TSPARMCD' 'TSPARM' 'TSVAL')
    order by name;
    select length into: sd_len separated by ' '
    from dictionary.columns
    where upcase(libname ) = 'WORK' and upcase(memname) = 'SDTM_CONFIG'
          and upcase(name) in ('CFPARMCD' 'CFPARM' 'CFVAL')
    order by name;
  quit;

  data settings;
    length PARMCD $%sysfunc(max(%scan(&ts_len,2),%scan(&sd_len,2)))
           PARM   $%sysfunc(max(%scan(&ts_len,1),%scan(&sd_len,1)))
           VAL    $%sysfunc(max(%scan(&ts_len,3),%scan(&sd_len,3)))
           ;
    set ts (keep=tsparmcd tsparm tsval
            rename=(tsparmcd=PARMCD tsparm=PARM tsval=VAL))
        sdtm_config (keep=cfparmcd cfparm cfval
            rename=(cfparmcd=PARMCD cfparm=PARM cfval=VAL));
  run;

  proc sort data=settings;
    by parmcd parm val;
  run;

  data _null_;
    set settings;
    by parmcd parm;
    if not first.parm or not last.parm then
       putlog "WARNING: (&sysmacroname) UNEXPECTED DUPLICATE settings "
              parmcd= parm= val=;
  run;
%mend m_read_tdmatrix;

/*** test
  %m_read_tdmatrix(path=../TrialDesign-Tool/,
                   file=TrialDesignMatrix_for_TDF_study.xlsm);
***/
