# AhkScriptRunner

This script is intended to allow running multiple AHK scripts as one.

To make a component script:

1) The file should be named <i>componentName</i>.part

2) The auto execute section should be in a subroutine called <i>componentName</i>_Auto, if your script does not do anything on startup, create the subroutine and leave it blank.

3) The exit subroutine should be in a subroutine called <i>componentName</i>_Exit, if your script does not do anything on exit, create the subroutine and leave it blank.

4) Variables should have disrinct names so as not to cause conflicts with other scripts. It is recommended that all variables should have the component name or a contraction of it as a prefix: <i>componentNameOrContraction</i>_<i>yourVarName</i>
