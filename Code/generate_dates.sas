/*** Standard PhUSE Test Data Factory Program Header
  Project:            PhUSE Test Data Factory
  Program Name:       generate_dates.sas
  SAS Version:        SAS Sever 9.4 M5
  Operating System:   MS Window Sever 2016
  Authors Name:       dditommaso
  Program Date:       2019-10-22

  Description:        Just a stub, placeholder for now
                      
  Input(s):           

  Output(s):          

  Comments:           

  Revision History:
  Date:     Author:    Description of Change:
  21FEB2020 J.Dai      Update to use rand uniform, changed date ranges
***/

%macro generate_dates(inds= ,outds= ,prefix= ,basedt= , dtrnglo= ,dtrnghi= )
                     / minoperator ;

data &outds;
  set &inds;

    /*Initiate seed*/
    *call streaminit(1234);
	
	%if &basedt =  %then %do;
	/*Create date between date range lo and high specified in create_[domain] program */ 
	&prefix.dtc = put(rand('uniform',&dtrnglo,&dtrnghi),yymmdd10.);
	%end;

	%else %do;
	/*Create date a varying number of days after base date*/
	&prefix.dtc = put(input(&basedt,yymmdd10.) + rand('uniform',&dtrnglo,&dtrnghi), yymmdd10.);
	%end;
run;

%quick_exit:
%mend generate_dates;
