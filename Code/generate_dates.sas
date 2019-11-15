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
  Date:    Author:    Description of Change:
***/

/* SAS macro that duplicates the Excel RANDBETWEEN function */
%macro RandBetween(min, max);
   (&min + floor((1+&max-&min)*rand("uniform")))
%mend;
* rand('UNIform',a,b);

%macro generate_dates(updateds=, prefix=)
                     / minoperator ;
   datest = input("&date_ref_st",yymmdd10.);
   dateen = input("&date_ref_en",yymmdd10.);
   
	 rfstdtc = put(%randbetween(datest,dateen),yymmdd10.);
	 rfendtc = put(input(rfstdtc,yymmdd10.) + &num_days, yymmdd10.);
%quick_exit:
%mend generate_dates;
