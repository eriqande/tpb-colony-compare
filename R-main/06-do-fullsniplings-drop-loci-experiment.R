
# must be run in the project directory.

# this runs fullsniplings on the chinook data but it does so on different numbers of loci:
# 95, 85, 75, 65, 55, 45, 35, 25
library(parallel)


# install fullsniplings
devtools::install_github(repo = "eriqande/fullsniplings")
library(fullsniplings)

source("R/colony-comp-funcs.R")

NumSweeps <- 500
NumBurnIn <- 100

# load the data:
load("data/chinook_full_sibs.Rda")

loc_vals <- seq(95, 25, by=-10)

# run fullsniplings on all those
set.seed(27)

fullsnip_loc_drop_results <- mclapply(loc_vals, function(x) {
  v <- 1:x
  loc_cols <- as.vector(rbind(v*2-1, v*2))
  fullsnip_time <-  system.time(fullsniplings_chinook_results <- run_mcmc(chinook_full_sibs_genos[, loc_cols], burn_in = NumBurnIn, num_sweeps = NumSweeps))
  list(fullsnip_time = fullsnip_time,
       fullsniplings_chinook_results = fullsniplings_chinook_results)},
    mc.cores = 8
)

message("Done with the fullsnipling runs.  Now slurping.")
names(fullsnip_loc_drop_results) <- loc_vals


fullsnip_loc_drop_summaries <- lapply(fullsnip_loc_drop_results, function(x) slurpFullSniplingsResults(x$fullsniplings_chinook_results, NumSweeps))

message("Done slurping.  Now saving results...Compression may take a awhile.")

save(fullsnip_loc_drop_summaries, file = "outputs/fullsnip_loc_drop_summaries.Rda", compress = "xz")

message("Saved results into outputs/fullsnip_loc_drop_summaries.Rda")
