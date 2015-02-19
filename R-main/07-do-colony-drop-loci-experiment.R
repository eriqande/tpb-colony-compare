
# must be run in project dirctory


source("R/colony-comp-funcs.R")


loc_vals <- seq(95, 25, by=-10)  # these are the locus values to do


# create the data sets to run and put each in their own directory
top_dir <- "colony-drop-loc-runs"

lapply(loc_vals, function(x) 
  createColonyRunArea(data_file = "./data/chinook_full_sibs.Rda", 
                      dir_name = file.path(top_dir, x), 
                      locus_numbers = 1:x, 
                      opt_strings = c("full-colony" = " -y -d 0.0 -m 0.005 -L -f ")
  )
)



# compile up a series of commands into a shell script that we will run with system()
script1 <- paste("PROJDIR=$(pwd)")
script2 <- sapply(loc_vals, function(x)
  paste("cd", file.path("$PROJDIR", top_dir, x, "full-colony;"), "nohup $PROJDIR/bin/colony2s.out > colony-stdout.txt &")
)

run_scr <- file.path(top_dir, "run-script.sh")

writeLines(text = c(script1, script2), sep = "\n", con = run_scr)

# then chmod it
system(paste("chmod a+x", run_scr))

# then launch that dude!  It takes about 15 minutes with one processor for each of the 8 jobs
system(run_scr)

