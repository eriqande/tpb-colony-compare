

# must be run in the project directory. (the one that has colony_compare.Rproj in it)

# this script collects the results from colony and fullsniplings runs.
# it places  the relevant outputs into the outputs directory and then it
# reads them in and formats stuff and grabs the true pedigree as well
# and assesses correctness (maybe, unless I do that with another script.)


source("R/colony-comp-funcs.R")  # this holds some functions that we use here
load("./data/chinook_full_sibs.Rda")  # get the data set too.


# make the outputs directory.  Don't worry if it already exists
dir.create("outputs", showWarnings = FALSE)


# copy the BestFSFamily files over to a place we will actually keep under version control
# so we have these intermediates
file.copy(from = "colony-runs/full-colony/colony-runs_full-colony.BestFSFamily", to = "outputs/colony-runs_full-colony.BestFSFamily")
file.copy(from = "colony-runs/pairwise-colony/colony-runs_pairwise-colony.BestFSFamily", to = "outputs/colony-runs_pairwise-colony.BestFSFamily")

# load the fullsnipling results
load("outputs/fullsniplings_chinook_results.Rda")


#### Get the Run Times ####
RunTimes <- data.frame(Method = c("Full.colony", "Pairwise.colony"), 
           Minutes = unname(sapply(c("colony-runs/full-colony/colony-stdout.txt", "colony-runs/pairwise-colony/colony-stdout.txt"), getColonyRunTime))
          )

RunTimes <- rbind(RunTimes, data.frame(Method = c("FullSnip", "FullSnip_pp100"),
                           Minutes = c(fullsnip_time["elapsed"]/60, pp100_fullsnip_time["elapsed"]/60)))


#### Get the true sibling groups in a convenient form (a list of base-1 indices) ####
# we are going to turn all the individuals into indices from 1 up to the number of indivs
chinook_indices <- 1:nrow(chinook_full_sibs_genos)
names(chinook_indices) <- rownames(chinook_full_sibs_genos)

# do that to the true pedigree here
ped <- chinook_full_sibs_pedigree
ordered.kids <- rownames(chinook_full_sibs_genos)
ped$kididx <- chinook_indices[ped$Kid]
kid.split <- lapply(split(ped$kididx, paste(ped$Pa, "---", ped$Ma, sep="")), sort)  # the lapply here sorts indices within sibgroups

# now order by size and then by index of first individual
TrueSibgroups <- kid.split[ order(sapply(kid.split, length), -sapply(kid.split, function(x) x[1]), decreasing = T)]
ul <- unlist(TrueSibgroups)
TrueSibgroups <- list(sets = TrueSibgroups,
              num.entries=length(ul),
              num.distinct=length(unique(ul)),
              num.more.than.once=sum(table(ul)>1)
              )

save(TrueSibgroups, file = "outputs/TrueSibgroups.Rda", compress = "xz")

#### Collate inferred sibling groups in a standardized form ####


# get the colony-inferred ones
Col.List <- lapply(c(Full.colony = "outputs/colony-runs_full-colony.BestFSFamily", 
                     Pairwise.colony = "outputs/colony-runs_pairwise-colony.BestFSFamily",
                     SibPri3.07.colony = "outputs/colony-sib-prior-runs_colony-sib-pri-3_07.BestFSFamily",
                     SibPri_dl_25_sib_pri3.07.colony25 = "outputs/colony-drop-loc-25-sib-pri-3_07.BestFSFamily"),
       function(x) slurpColonyResults(file = x, indices = chinook_indices))



# Now collate the fullsnipling-inferred sibling groups in the same standardized way ####
FS.List <- lapply(list(FullSnip = fullsniplings_chinook_results, FullSnip_pp100 = pp100_fullsniplings_chinook_results), 
                  function(x) slurpFullSniplingsResults(x, 500)
                  )

# put them all together
InferredSibgroups <- c(Col.List, FS.List)


# now, we need to make another summary of it that we can use in the "sib_result_plot" function.


save(InferredSibgroups, file = "outputs/InferredSibgroups.Rda", compress = "xz")

