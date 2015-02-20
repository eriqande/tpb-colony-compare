
# must be run in project dirctory

load("outputs/InferredSibgroups.Rda")
source("R/colony-comp-funcs.R")


# get the mean size of the Colony inferred sibgroups (about 3.07) for use later
ColonyFirstRunMeanSibsize <- mean(sapply(InferredSibgroups$Full.colony$sets, length))


loc_vals <- seq(95, 25, by=-10)  # these are the locus values to do


# create the data sets to run and put each in their own directory
top_dir <- "colony-drop-loc-runs"

set.seed(22)  # this will set colony's seeds to a reproducible value
lapply(loc_vals, function(x) 
  createColonyRunArea(data_file = "./data/chinook_full_sibs.Rda", 
                      dir_name = file.path(top_dir, x), 
                      locus_numbers = 1:x, 
                      opt_strings = c("full-colony-ewens" = paste(" -y -d 0.0 -m 0.005 -L -f  -S", 
                                                            floor(runif(1, min = 1, max = 100000)),
                                                            " -e \"1 ", sprintf("%.6f", ColonyFirstRunMeanSibsize), 
                                                            sprintf("%.6f", ColonyFirstRunMeanSibsize), " \""
                                                            ),
                                      "full-colony" = paste(" -y -d 0.0 -m 0.005 -L -f  -S", 
                                                            floor(runif(1, min = 1, max = 100000))
                                                            )
                                      )
  )
)



# compile up a series of commands into a shell script that we will run with system().  Note that
# we are going to run it both with and without the Ewens prior that Colony provides.
# If we run it with the prior we set it at the average from the full run with 95.  
script1 <- paste("PROJDIR=$(pwd)")
script2 <- sapply(loc_vals, function(x)
  paste("cd", file.path("$PROJDIR", top_dir, x, "full-colony;"), "nohup $PROJDIR/bin/colony2s.out > colony-stdout.txt &\n",
         "cd", file.path("$PROJDIR", top_dir, x, "full-colony-ewens;"), "nohup $PROJDIR/bin/colony2s.out > colony-stdout.txt &")
)

run_scr <- file.path(top_dir, "run-script.sh")

writeLines(text = c(script1, script2), sep = "\n", con = run_scr)

# then chmod it
system(paste("chmod a+x", run_scr))

# then launch that dude!  It takes about 15 minutes with one processor for each of the 8 jobs
system(run_scr)

