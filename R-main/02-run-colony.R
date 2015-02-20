
# make a short script to do these two runs and then call it from the system
top_dir <- "colony-runs"
subdirs <- c("full-colony", "pairwise-colony")
script1 <- paste("PROJDIR=$(pwd)")
script2 <- sapply(subdirs, function(x)
  paste("cd", file.path("$PROJDIR", top_dir, x, ";"), "nohup $PROJDIR/bin/colony2s.out > colony-stdout.txt &")
)

run_scr <- file.path(top_dir, "first-run-script.sh")

writeLines(text = c(script1, script2), sep = "\n", con = run_scr)

# then chmod it
system(paste("chmod a+x", run_scr))

system(run_scr)
