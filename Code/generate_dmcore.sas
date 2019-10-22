/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       generate_dmcore.sas
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       dditommaso
  Program Date:       2019-09-28

  Description:        Access treatments arms, and user-specified allocation weights
                      and create Subject IDs and Treatment Arm Codes, accordingly
  Input(s):           TAIN   - TA dset, created in WORK by macro m_read_tdmatrix.sas
                      SDTMIN - SDTM_CONFIG dset, created in WORK by same macro, above
                      STUDYID- Study ID, default is created by same macro, above
                               Used to create SUBJID, concat of Study & Subj IDs
                      BIGN   - Number of subjs, default is created by same macro, above
                      ARMDLIM- Pipe (|) by default to separate ARMCD values during processing, 
                               this char should NOT appear in any ARMCD value. 
                               Override, as needed
  Output(s):          DM dataset with 5 (somewhat redundant) standard SDTM vars:
                        STUDYID, USUBJIT, SITEID, SUBJID, ARMCD, ARM

  Comments:           Just a first step for now

  Revision History:
  Date:    Author:    Description of Change:
***/

%macro generate_dmcore(tain=work.ta, sdtmin=work.sdtm_config,
                        studyid=&tdf_studyid, bign=&tdf_plansub, 
                        armdlim=|)
                        / minoperator ;

  *--- Confirm number of arms defined, and their codes ;
  *--- See SDTM IG "Variable-Naming Conventions" ;
  *--- "ARMCD is limited to 20 characters and
        does not have the character restrictions that apply to --TESTCD" ;
  proc sql noprint;
    select max(length(cfval)) into: cf_sitewgtlen trimmed
    from &sdtmin
    where upcase(cfparmcd) = 'SITEWGT';

    select distinct(compress(upcase(armcd))) into: ta_arms separated by "&armdlim"
    from &tain
    where not missing(armcd);

    select count(distinct(armcd)) into: ta_armn trimmed
    from &tain
    where not missing(armcd);

    select max(length(arm)), max(length(armcd)) 
           into :ta_armlen trimmed, :ta_armcdlen trimmed
    from &tain
    where not missing(armcd);
  quit;
  %put NOTE: Detected SiteWgt len [&cf_sitewgtlen], and [&ta_armn] arms as [&ta_arms];

  *--- Process SITE IDs and Weights ;
    data _null_;
      set &sdtmin (where=(upcase(cfparmcd) = 'SITEWGT'));
      retain cf_sitelen 0;

      length nxt nxtsite nxtwgt
             $%sysfunc(max(&cf_sitewgtlen, 4));

      idx=1;
      do while (scan(strip(cfval), idx, ',') ne ' ');

        nxt     = scan(strip(cfval), idx, ',');
        nxtsite = scan(strip(nxt), 1, '=');
        nxtwgt  = scan(strip(nxt), 2, '=');

        if missing(nxtwgt) then nxtwgt = '1';

        *--- Standardize NUM Site IDs to INTEGER IDs in z4. format ;
        test_num = input(nxtsite, ?? best.);
        if not missing(test_num) then 
           nxtsite = strip(put(test_num, z4.));

        call symput('cf_site'!!strip(put(idx,best.)), strip(nxtsite));
        call symput('cf_sitewgt'!!strip(put(idx,best.)), strip(nxtwgt));

        if length(nxtsite) > cf_sitelen then cf_sitelen = length(nxtsite);
        idx+1;
      end;

      call symput('cf_siten',   strip(put(idx-1, best.)));
      call symput('cf_sitelen', strip(put(cf_sitelen, best.)));
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

  *--- Use TA dset to format ARMCD into ARM values ;
    proc sort data=ta (keep=armcd arm rename=(armcd=start arm=label))
              out=fmtin nodupkey;
      by start label;
    run;
    data fmtin;
      set fmtin;
      retain fmtname 'ta_arm' type 'C';
    run;
    proc format cntlin=fmtin;
    run;


  *--- Retrieve CDISC attributes for Core DM vars ;
    %m_read_sdtmig_var(path=../_Offline_/,
                       file=sdtmig-3-3-excel.xlsx,
                       tab=SDTMIG V3.3 VARIABLES,
                       var=dm.studyid,
                       macvar=a_studyid)
  
    %m_read_sdtmig_var(var=dm.siteid,
                       macvar=a_siteid)
    %m_read_sdtmig_var(var=dm.usubjid,
                       macvar=a_usubjid)
    %m_read_sdtmig_var(var=dm.subjid,
                       macvar=a_subjid)
    %m_read_sdtmig_var(var=dm.armcd,
                       macvar=a_armcd)
    %m_read_sdtmig_var(var=dm.arm,
                       macvar=a_arm)

  *--- Generate subjects in weighted arms ;
    data dm (keep=studyid siteid usubjid subjid armcd arm);
      sitedenom = sum(0 %do idx = 1 %to &cf_siten; , &&cf_sitewgt&idx %end;);
      armdenom  = sum(0 %do idx = 1 %to &ta_armn; , &&ta_wgt&idx %end;);

      *---Note: Length of SUBJID, below, is set by "-z5." construct (6 char suffix);
      &a_STUDYID length=$%length(&studyid) ;
      &a_SITEID  length=$&cf_sitelen ;
      &a_USUBJID length=$%eval(%length(&studyid)+1+&cf_sitelen+5+1) ;
      &a_SUBJID  length=$%eval(&cf_sitelen+5+1) ;

      &a_ARMCD   length=$&ta_armcdlen ;
      &a_ARM     length=$&ta_armlen ;
      ;

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

          if nxtsubj < &ta_wgt1/armdenom then armcd = "&ta_arm1";
            %if &ta_armn > 2 %then %do idx = 2 %to %eval(&ta_armn-1);
              else if nxtsubj < sum(0 %do jdx= 1 %to &idx;, &&ta_wgt&jdx %end;)
                      /armdenom then armcd = "&&ta_arm&idx";
            %end;
          else armcd = "&&ta_arm&ta_armn";

        arm = strip(put(armcd, $ta_arm.));

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
    proc freq data=tdfdata.dm;
      tables siteid armcd arm / list missing nocol nocum;
    run;
%quick_exit:
%mend generate_dmcore;
