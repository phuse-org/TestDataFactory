/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       gen_sitearmwgts.sas
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       dditommaso
  Program Date:       2019-09-28

  Description:        Access treatments arms, and user-specified allocation weights
                      and create Subject IDs and Treatment Arm Codes, accordingly
  Input(s):           TAIN   - TA dset, created in WORK by macro m_read_tdmatrix.sas
                      SDTMIN - SDTM_CONFIG dset, created in WORK by same macro, above
                      ARMVAR - ARM or ARMCD, a var in the TA dset
                      STUDYID- Study ID, default is created by same macro, above
                               Used to create SUBJID, concat of Study & Subj IDs
                      BIGN   - Number of subjs, default is created by same macro, above
                      ARMDLIM- Pipe (|) by default, this char should NOT appear in
                               any ARMVAR value. Override, as needed
  Output(s):          DM dataset with 5 (somewhat redundant) standard SDTM vars:
                        STUDYID, USUBJIT, SITEID, SUBJID, ARMCD

  Comments:           Just a first step for now

  Revision History:
  Date:    Author:    Description of Change:
***/

%macro generate_subjids(tain=work.ta, sdtmin=work.sdtm_config,
                        armvar=armcd, armdlim=|,
                        studyid=&tdf_studyid, bign=&tdf_plansub);
  *--- Confirm number of arms defined, and their codes ;
  *--- See SDTM IG "Variable-Naming Conventions" ;
  *--- "ARMCD is limited to 20 characters and
        does not have the character restrictions that apply to --TESTCD" ;
  proc sql noprint;
    select max(length(cfval)) into: cf_sitewgtlen trimmed
    from &sdtmin
    where upcase(cfparmcd) = 'SITEWGT';

    select distinct(compress(upcase(&armvar))) into: ta_arms separated by "&armdlim"
    from &tain
    where not missing(&armvar);

    select count(distinct(&armvar)) into: ta_armn trimmed
    from &tain
    where not missing(&armvar);

    select max(length(&armvar)) into: ta_armlen trimmed
    from &tain
    where not missing(&armvar);
  quit;
  %put NOTE: Detected SiteWgt len [&cf_sitewgtlen], and [&ta_armn] arms as [&ta_arms];

  *--- Process SITE IDs and Weights ;
    data _null_;
      set &sdtmin (where=(upcase(cfparmcd) = 'SITEWGT'));

      length nxt nxtsite nxtwgt $&cf_sitewgtlen;

      idx=1;
      do while (scan(strip(cfval), idx, ',') ne ' ');

        nxt     = scan(strip(cfval), idx, ',');
        nxtsite = scan(strip(nxt), 1, '=');
        nxtwgt  = scan(strip(nxt), 2, '=');

        if missing(nxtwgt) then nxtwgt = '1';

        call symput('cf_site'!!strip(put(idx,best.)), strip(nxtsite));
        call symput('cf_sitewgt'!!strip(put(idx,best.)), strip(nxtwgt));

        idx+1;
      end;

      call symput('cf_siten', strip(put(idx-1, best.)));
    run;

  *--- Default arm weights to balanced, 1 each ;
    data _null_;
      do idx = 1 to &ta_armn;
        call symput('ta_arm'!!strip(put(idx,best.)), scan("&ta_arms",idx,"&armdlim"));
        call symput('ta_wgt'!!strip(put(idx,best.)), '1');
      end;
    run;

  *--- Update with any user-defined non-default SITE and ARM weights ;
    data _null_;
      set &sdtmin
          (where=( upcase(cfparmcd) = 'ARMWGT' ));

      idx = 1;

      do while (scan(cfval, idx, ',') ne ' ');
        nxt = scan(cfval, idx, ',');
        nxtarm = left(scan(nxt, 1, '='));
        nxtwgt = left(scan(nxt,-1, '='));

        *--- If this one of the known ARMCDs, update weight ;
        do jdx = 1 to &ta_armn;
          if upcase(compress(nxtarm)) = symget('ta_arm'!!put(jdx,best.-L)) then do;
            call symput('ta_wgt'!!put(jdx,best3.-L), nxtwgt);
          end;
        end;

        idx+1;
      end;
    run;

  %put NOTE: Detected [&ta_armn] tx arms, and [&cf_siten] sites in &sdtmin.;
  %do idx = 1 %to &ta_armn;
    %put NOTE-  Arm &idx: &&ta_arm&idx with weight &&ta_wgt&idx ;
  %end;
  %do idx = 1 %to &cf_siten;
    %put NOTE-  Site &idx: &&cf_site&idx with weight &&cf_sitewgt&idx ;
  %end;

  *--- Generate subjects in weighted arms ;
  data dm (keep=studyid siteid usubjid subjid &armvar);
    sitedenom = sum(0 %do idx = 1 %to &cf_siten; , &&cf_sitewgt&idx %end;);
    armdenom  = sum(0 %do idx = 1 %to &ta_armn; , &&ta_wgt&idx %end;);

    *---Note: Length of SITEID, below, is fixed at $4 by z4. construct ;
    *---Note: Length of SUBJID, below, is fixed at $10 by z4.-z5 construct ;
    attrib studyid length=$%length(&studyid) label='Study Identifier';
    attrib siteid  length=$4 label='Study Site Identifier';
    attrib usubjid length=$%eval(%length(&studyid)+10+1)
                   label='Subject Identifier';
    attrib subjid  length=$10 label='Subject Identifier for the Study';
    attrib &armvar length=$&ta_armlen label='Planned Arm Code';

    studyid = "&studyid";

    do idx = 1 to &bign;
      *--- Random allocation to SITE ;
        nxtsite = ranuni(285);

        if nxtsite < &cf_sitewgt1/sitedenom then siteid = "&cf_site1";
          %if &cf_siten > 2 %then %do idx = 2 %to %eval(&cf_siten-1);
            else if nxtsite < sum(0 %do jdx= 1 %to &idx;, &&cf_sitewgt&jdx %end;)
                    /sitedenom then siteid = "&&cf_site&idx";
          %end;
        else siteid = "&&cf_site&cf_siten";

        subjid = cats(siteid, '-', put(idx,z5.));
        usubjid= cats(studyid, '/', subjid);

      *--- Random allocation to ARMCD ;
        nxtsubj = ranuni(41539);

        if nxtsubj < &ta_wgt1/armdenom then &armvar = "&ta_arm1";
          %if &ta_armn > 2 %then %do idx = 2 %to %eval(&ta_armn-1);
            else if nxtsubj < sum(0 %do jdx= 1 %to &idx;, &&ta_wgt&jdx %end;)
                    /armdenom then &armvar = "&&ta_arm&idx";
          %end;
        else &armvar = "&&ta_arm&ta_armn";

      OUTPUT;
    end;
  run;

  proc sort data=dm;
    by studyid siteid subjid;
  run;

  *--- Update to gapless, ordinal subjid WITHIN SITE ;
    data tdfdata.dm (label = 'SDTM Demographics');
      set dm;
      by studyid siteid subjid;

      if first.siteid then idx=1;
      else idx+1;

      subjid = cats(siteid, '-', put(idx,z5.));
      usubjid= cats(studyid, '/', subjid);

      drop idx;
    run;

  *--- Check whether resulting allcoations are correct ;
    proc freq data=dm;
      tables siteid &armvar / list missing nocol nocum;
    run;

%mend generate_subjids;


%m_read_tdmatrix(path=..\TrialDesign-Tool\, file=TrialDesignMatrix_for_TDF_study.xlsm)

%generate_subjids()
*;
