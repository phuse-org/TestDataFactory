/*** Standard PhUSE Test Data Factory Program Header 
Project:            PhUSE Test Data Factory 
Program Name:       m_read_igmeta.sas 
SAS Version:        SAS Sever 9.4 1M3 
Operating System:   MS Window Sever 2016 
Authors Name:       jdai 
Program Date:       10OCT2019 
 
Description:        Read in SDTM IG 3.3 xls metadata to create shell of dataset 

Input(s):           sdtmig-3-3-excel.xlsx 
 
Output(s):          
 
Comments:            
  
Revision History:    
Date:    Author:    Description of Change: 
***/ 

/****************************************
Create metadata
****************************************/
%macro m_read_igmeta(path= , file= , domain= );
/* read in xls file */
proc import datafile = "&path./&file."
	out = metadata dbms = xlsx replace;
    sheet   = "SDTMIG v3.3 Variables";
    getnames= Yes;
run;

/* Create attributes assignment statement */
data attrib0(keep=attrib);
   set work.metadata;
   where domain_prefix = "&domain";
   length attrib $1000;
   if type = "Char" then length = "$200";
   else length = "8";
   attrib = compbl(variable_name || ' length = ' || length || ' label = ' || quote(strip(variable_label)));
run;

proc sql noprint;
   select attrib into :attribvars separated by ' ' from attrib0;
quit;

/* Create domain shell */
data &domain;
   attrib &attribvars;
   if 0;
run;
%mend;

/*** test 
%m_read_igmeta(path=Z:\CDISC\PHUSE-CSWG\Test Data Factory\Metadata,
               file=sdtmig-3-3-excel.xlsx,
               domain=DM
              );
***/
