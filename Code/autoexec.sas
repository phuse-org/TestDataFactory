libname library '.';
libname tdfdata '..\Data';

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
