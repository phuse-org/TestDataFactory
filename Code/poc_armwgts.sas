/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       dditommaso
  Program Date:       2019-09-28

  Description:        Read in user-specified study details and create
                      Subject IDs and Treatment Arm Codes, according to treatment arm weighting

  Input(s):           ARMCD  from user-specified for TA (Trial Design Matrix workbook)
                      ARMWGT from user-specified SDTM_Configufation (TDF-extended TDM wkbk)
  Output(s):          DM dataset with 2 vars: SUBJID, ARMCD

  Comments:           Just a first step for now

  Revision History:   
  Date:    Author:    Description of Change:
***/

%macro generate_subjids(libin=tdfstudy, armvar=armcd, bign=10);
  *--- Number of arms defined, and they Codes ;
  *--- See SDTM IG "Variable-Naming Conventions" ;
  *--- "ARMCD is limited to 20 characters and 
        does not have the character restrictions that apply to --TESTCD" ;
  proc sql noprint;
    select distinct(compress(upcase(&armvar))) into: ta_arms separated by '|'
    from tdfstudy.ta
    where not missing(&armvar);

    select count(distinct(&armvar)) into: ta_armn trimmed
    from tdfstudy.ta
    where not missing(&armvar);

    select max(length(&armvar)) into: ta_armlen trimmed
    from tdfstudy.ta
    where not missing(&armvar);
  quit;
  %put NOTE: Detected [&ta_armn] arms as [&ta_arms];

  *--- Default arm weights to balanced, 1 each ;
  data _null_;
    do idx = 1 to &ta_armn;
      call symput('ta_arm'!!put(idx,best.-L), scan("&ta_arms",idx,'|'));
      call symput('ta_wgt'!!put(idx,best.-L), '1');
    end;
  run;

  *--- Update with any user-defined non-default weights ;
  data _null_;
    set tdfstudy.sdtm_configuration
        (where=( upcase(cfparmcd) = 'ARMWGT' ));

    idx = 1;

    do while (scan(cfval, idx, ',') ne ' ');
      nxt = scan(cfval, idx, ',');
      nxtarm = left(scan(nxt, 1, '='));
      nxtwgt = left(scan(nxt,-1, '='));

      *--- If this one one of the known ARMCDs, update weight ;
      do jdx = 1 to &ta_armn;
        if upcase(compress(nxtarm)) = symget('ta_arm'!!put(jdx,best.-L)) then do;
          call symput('ta_wgt'!!put(jdx,best3.-L), nxtwgt);
        end;
      end;

      idx+1;
    end;
  run;

  %put NOTE: Detected [&ta_armn] treatment arms in &libin..sdtm_configuration.;
  %do idx = 1 %to &ta_armn;
    %put NOTE-  Arm &idx: &&ta_arm&idx with weight &&ta_wgt&idx ;
  %end;

  *--- Generate subjects in weighted arms ;
  data dm (keep=subjid &armvar);
    denom = sum(0 %do idx = 1 %to &ta_armn; , &&ta_wgt&idx %end;);

    attrib subjid  length=$15 label='Subject Identifier for the Study';
    attrib &armvar length=$&ta_armlen label='Planned Arm Code';

    do idx = 1 to &bign;
      subjid = 'SUBJECT_'!!put(idx,z4.-L);
      nxtsbj = ranuni(41539);

      if nxtsbj < &ta_wgt1/denom then &armvar = "&ta_arm1";
        %if &ta_armn > 2 %then %do idx = 2 %to %eval(&ta_armn-1);
          else if nxtsbj < sum(0 %do jdx= 1 %to &idx;, &&ta_wgt&jdx %end;)
                  /denom then &armvar = "&&ta_arm&idx";
        %end;
      else &armvar = "&&ta_arm&ta_armn";

      OUTPUT;
    end;
  run;

  proc freq data=dm;
    tables &armvar / list missing nocol nocum;
  run;

%mend generate_subjids;

%generate_subjids(bign=100)
*;
