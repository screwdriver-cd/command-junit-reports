# command-junit-reports
Shared command to parse Junit reports

Description:
  Process junit reports in surefire or touchstone format to compute total number of pass, failed tests, archive in artifact directory for each run and optionally update SDV4 build UI with test results

Usage:
  sd-cmd exec screwdriver-cd/junit-tests@<VERSION|TAG> <JUNIT REPORTS DIRECTORY> <UPDATE SD UI [TRUE|FALSE] >
  Args:
          DIRECTORY             Directory to surefire reports [surefire | touchstone].
          SDUI                  Update SDV4 UI in a format fail/total tests.
 
