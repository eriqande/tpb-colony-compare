


source("R/colony-comp-funcs.R")
pd_path <- "partition-distance-calculation"
source(file.path(pd_path, "R/SibAssessRfunctions.R"));

load("outputs/TrueSibgroups.Rda")
load("outputs/fullsnip_loc_drop_summaries.Rda")
load("./data/chinook_full_sibs.Rda")  # get the data set too.



loc_vals <- seq(95, 25, by=-10)  # these are the locus values to do

#### Here we slurp up the colony results produced in script 07  ####
# make the outputs directory.  Don't worry if it already exists
dir.create("outputs", showWarnings = FALSE)


# copy over the raw colony output parts that we need.  Only do this if there is a
# colony-drop-loc-runs directory
if(file.exists("colony-drop-loc-runs")) {
  lapply(loc_vals, function(x) file.copy(from = paste("colony-drop-loc-runs/", x, "/full-colony/", x, "_full-colony.BestFSFamily", sep=""),
                                         to = paste("outputs/", x, "_full-colony.BestFSFamily", sep=""),
                                         overwrite = TRUE)
  )
  
  # copy over the ones that have the ewens prior too
  lapply(loc_vals, function(x) file.copy(from = paste("colony-drop-loc-runs/", x, "/full-colony-ewens/", x, "_full-colony-ewens.BestFSFamily", sep=""),
                                         to = paste("outputs/", x, "_full-colony-ewens.BestFSFamily", sep=""),
                                         overwrite = TRUE)
  )
}



# get the names of the fish
chinook_indices <- 1:nrow(chinook_full_sibs_genos)
names(chinook_indices) <- rownames(chinook_full_sibs_genos)


# now slurp the colony results into a list of lists (our standard output format lists)
Col.List.Drop.Loc <- lapply(loc_vals, function(y) {
  x <- paste("outputs/", y, "_full-colony.BestFSFamily", sep="")
  slurpColonyResults(file = x, indices = chinook_indices)
})
names(Col.List.Drop.Loc) <- loc_vals


# do the same for the ones that use the ewens prior
Col.List.Drop.Loc.Ewens <- lapply(loc_vals, function(y) {
  x <- paste("outputs/", y, "_full-colony-ewens.BestFSFamily", sep="")
  slurpColonyResults(file = x, indices = chinook_indices)
})
names(Col.List.Drop.Loc.Ewens) <- loc_vals


# Then make a data frame of the results for each
colony_drop_loc_df_list <- lapply(Col.List.Drop.Loc, function(x) {
  x$Prob <- pmin(x$ProbExc, x$ProbInc)  # always take the lowest of the two values
  sib_list_to_data_frame(x, TrueSibgroups)
})

colony_drop_loc_df_list_ewens <- lapply(Col.List.Drop.Loc.Ewens, function(x) {
  x$Prob <- pmin(x$ProbExc, x$ProbInc)  # always take the lowest of the two values
  sib_list_to_data_frame(x, TrueSibgroups)
})



# then, let's compute the partition distances as well:
colony_drop_loc_pds <- sapply(Col.List.Drop.Loc, function(x) PD(truth = TrueSibgroups, est = x)$pd)
colony_drop_loc_pds_ewens <- sapply(Col.List.Drop.Loc.Ewens, function(x) PD(truth = TrueSibgroups, est = x)$pd)


#### Here we make summaries of the fullsniplings results  ####

# get the fullsnip PDs
fullsnip_drop_loc_pds <- sapply(fullsnip_loc_drop_summaries, function(x) PD(truth = TrueSibgroups, est = x)$pd)

# then make a data frame of the results
fs_drop_loc_df_list <- lapply(
  fullsnip_loc_drop_summaries, function(x) {
    sib_list_to_data_frame(x, TrueSibgroups)
})





#### Here we can make some bugle plots   ####


# fullsniplings bugle plots
lapply(names(fs_drop_loc_df_list), function(y) { 
  pdf(file = paste("plots/drop-loc-bugle-plot-fullsnip-", y, ".pdf", sep=""), width = 9.7, height = 6)
  x <- fs_drop_loc_df_list[[y]]
  inferred_sibs_bugle_plot(x, lscale = .04, main = paste("Fullsniplings    ---     Number of Loci:", y))
  dev.off()
})

# colony bugle plots
lapply(names(colony_drop_loc_df_list), function(y) { 
  pdf(file = paste("plots/drop-loc-bugle-plot-colony-", y, ".pdf", sep=""), width = 9.7, height = 6)
  x <- colony_drop_loc_df_list[[y]]
  inferred_sibs_bugle_plot(x, lscale = .04, main = paste("Colony   ---     Number of Loci:", y))
  dev.off()
})

# colony-ewens bugle plots
lapply(names(colony_drop_loc_df_list_ewens), function(y) { 
  pdf(file = paste("plots/drop-loc-bugle-plot-colony-ewens", y, ".pdf", sep=""), width = 9.7, height = 6)
  x <- colony_drop_loc_df_list[[y]]
  inferred_sibs_bugle_plot(x, lscale = .04, main = paste("Colony - Ewens   ---     Number of Loci:", y))
  dev.off()
})
