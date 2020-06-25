/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       
  Program Date:       

  Description:        

  Input(s):           

  Output(s):          

  Comments:           

  Revision History:   
  Date:    Author:    Description of Change:
***/

*--- READ TDMatrix ;
%m_read_tdmatrix(path=./, file=TrialDesignMatrix_for_TDF_study.xlsm)


*--- Generate foundational DM vars (study, site, subj, arms) ;
%generate_dmcore()
*;


*--- Generate foundational dates - switch to M_QUERY_TDF_CONFIG macro calls ;
/***
  proc sql noprint;
    select cfval into :enrllen from sdtm_config where cfparmcd="ENRLLEN";
    select cfval into :trtlen from sdtm_config where cfparmcd="TRTLEN";
    select cfval into :lenvar from sdtm_config where cfparmcd="LENVAR";
    select input(tsval,yymmdd10.) into :sstdtc from ts where tsparmcd="SSTDTC";
    select input(tsval,yymmdd10.) into :sendtc from ts where tsparmcd="SENDTC";
  quit;
***/

%let enrllen = %m_query_tdf_config(sdtm_config, cfval, %str(upcase(cfparmcd)="ENRLLEN")) ;
%let trtlen  = %m_query_tdf_config(sdtm_config, cfval, %str(upcase(cfparmcd)="TRTLEN")) ;
%let lenvar  = %m_query_tdf_config(sdtm_config, cfval, %str(upcase(cfparmcd)="LENVAR")) ;
%let sstdtc  = %m_query_tdf_config(ts, tsval, %str(upcase(tsparmcd)="SSTDTC"), infmt=yymmdd10) ;
%let sendtc  = %m_query_tdf_config(ts, tsval, %str(upcase(tsparmcd)="SENDTC"), infmt=yymmdd10) ;

%generate_dates(inds=dm, outds=dm1, prefix=rfic, basedt= ,dtrnglo=&sstdtc, dtrnghi=&sstdtc+&enrllen);
%generate_dates(inds=dm1, outds=dm2, prefix=rfst, basedt=rficdtc, dtrnglo=28, dtrnghi=56);
%generate_dates(inds=dm2, outds=dm3, prefix=rfen, basedt=rfstdtc, dtrnglo=&trtlen-&lenvar, dtrnghi=&trtlen+&lenvar);
%generate_dates(inds=dm3, outds=dm4, prefix=rfxst, basedt=rfstdtc, dtrnglo=0, dtrnghi=0);
*;
