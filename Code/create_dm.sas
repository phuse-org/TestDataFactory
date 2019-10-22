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
%m_read_tdmatrix(path=..\TrialDesign-Tool\, file=TrialDesignMatrix_for_TDF_study.xlsm)


*--- Generate foundational DM vars (study, site, subj, arms) ;
%generate_dmcore()
*;


*--- Generate foundational dates ;
%generate_dates(updateds=dm, prefix=rf)
%generate_dates(updateds=dm, prefix=rfx)
*;
