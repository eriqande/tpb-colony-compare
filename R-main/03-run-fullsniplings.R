

# must be run in the project directory. (the one that has colony_compare.Rproj in it)



# install fullsniplings
devtools::install_github(repo = "fullsniplings", username = "eriqande")
library(fullsniplings)


# load the data:
load("data/chinook_full_sibs.Rda")

# count up how many true sibgroups of every size there are
library(plyr)
cnts <- table(count(chinook_full_sibs_pedigree[,c("Pa", "Ma")])$freq)
paste(names(cnts), collapse = "  &  ")
paste(cnts, collapse = "  &  ")


# look at the true average sibgroup size.  It is about 2.68
true.average.sibgroup.size <- mean(count(chinook_full_sibs_pedigree[,c("Pa", "Ma")])$freq)


# run fullsniplings.  
set.seed(5)  # this ensures reproducibility
fullsnip_time <-  system.time(fullsniplings_chinook_results <- run_mcmc(chinook_full_sibs_genos, burn_in = 100, num_sweeps = 500))


# now, let's see if another run with a less demanding pair_prob_cutoff is any faster (and how much less accurate)
set.seed(15)
pp100_fullsnip_time <-  system.time(pp100_fullsniplings_chinook_results <- run_mcmc(chinook_full_sibs_genos, burn_in = 100, num_sweeps = 500, pair_prob_cutoff = 0.01))


# make a directory to put the results into
dir.create("outputs", showWarnings = FALSE)
save(fullsnip_time, fullsniplings_chinook_results, pp100_fullsnip_time, pp100_fullsniplings_chinook_results, file = "outputs/fullsniplings_chinook_results.Rda", compress = "xz")






 