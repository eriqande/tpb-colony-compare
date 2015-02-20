# tpb-colony-compare

This repository houses the code used to make a comparison between colony
and fullsniplings for a paper I am submitting to TPB.  

The code to execute to reproduce my results is in R-main in scripts that should
be run in series as numbered.   In fact, if you want to just run them all in series
then just do

```r
source("R-main/master-script.R")
```
in R, making sure that the working directory in R is set to the top-level directory
of the repository (i.e. the directory that contains `tpb-colony-compare.Rproj`)

The basic outline of what happens:

1. Run colony and fullsniplings on the chinook data set. (01, 02, 03)
2. Assess the results and summarize (04, 05, 06).  In the process, compute the
average sibship size from the colony results
3. Re-do the analyses using 25, 35, and so forth, up to all 95 of the original loci, only
this time use colony's sib-size prior set at the average size from the first run.
4. Analyze all the output and make some plots.

