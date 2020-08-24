# Overview
SAS and R code progress in this project, while a python implementation is a component of the [PhUSE Open Data Repository (PODR)](https://github.com/phuse-org/PODR) project.

# Code snippets
Code snippets, for now, to demonstrate reading a database configuration workbook of spreadsheets that specifies a clinical database.  

+ **m_read_tdmatrix.sas** - Macro (prefix "m_") to read into the SAS WORK folder the TA and SDTM_Config tabs, from the TDF trial design matrix workbook, updated with SDTM configuration details.
+ **gen_sitearmwgts.sas** - Generate (prefix "gen_") DM dset, with Study, Site, Subj and Arm(CD) vars as specified in those WORK data sets, above.

Result data sets are in the Data folder, at the same level as this Code folder.  

See "[TrialDesignMatrix_for_TDF_study.xlsx](../TrialDesign-Tool/TrialDesignMatrix_for_TDF_study.xlsx)" in the TrialDesign-Tool folder. This is the example clinical database specification workbook.  
