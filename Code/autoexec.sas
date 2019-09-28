libname tdfstudy xlsx '..\TrialDesign-Tool\TrialDesignMatrix_for_TDF_study.xlsm' access=readonly;

libname library  '.';

options
  formchar = "|----|+|---+=|-/\<>*"
  ps=max ls=125
  nofmterr
  mergenoby = warn
  msglevel = i
  mprint
  mrecall 
  mautosource
  ;

options
  mprint
  mrecall 
  mautosource
  sasautos = ('.', sasautos)
  fmtsearch = (work library);
