


source("R/colony-comp-funcs.R")

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
                                         to = paste("outputs/", x, "_full-colony.BestFSFamily", sep=""))
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

colony_drop_loc_df_list <- lapply(Col.List.Drop.Loc, function(x) {
  x$Prob <- x$ProbExc
  sib_list_to_data_frame(x, TrueSibgroups)
})



#### Here we make summaries of the fullsniplings results  ####
fs_drop_loc_df_list <- lapply(
  fullsnip_loc_drop_summaries, function(x) {
    sib_list_to_data_frame(x, TrueSibgroups)
})





#### Here we can make some bugle plots   ####

# fullsniplings bugle plots
lapply(names(fs_drop_loc_df_list), function(y) { 
  pdf(file = paste("drop-loc-bugle-plot-fullsnip-", y, ".pdf", sep=""), width = 9.7, height = 6)
  x <- fs_drop_loc_df_list[[y]]
  inferred_sibs_bugle_plot(x, lscale = .04, main = paste("Fullsniplings    ---     Number of Loci:", y))
  dev.off()
})

# colony bugle plots
lapply(names(colony_drop_loc_df_list), function(y) { 
  pdf(file = paste("drop-loc-bugle-plot-colony-", y, ".pdf", sep=""), width = 9.7, height = 6)
  x <- colony_drop_loc_df_list[[y]]
  inferred_sibs_bugle_plot(x, lscale = .04, main = paste("Colony   ---     Number of Loci:", y))
  dev.off()
})

# copy files and then make the latex calls for them
dl_files <- dir(pattern = "^drop-loc*")
file.copy(dl_files, "../images/", overwrite = TRUE)
cat(sapply(rev(dl_files[grep(pattern = "colony", dl_files)]), function(i) {
  paste("\\begin{frame}{{\\sc colony} with decreasing number of loci} \\includegraphics[width=\\textwidth]{../images/", i,"} \\end{frame}", sep="")
}), sep="\n\n")



cat(sapply(rev(dl_files[grep(pattern = "fullsnip", dl_files)]), function(i) {
  paste("\\begin{frame}{{\\sc fullsniplings} with decreasing number of loci} \\includegraphics[width=\\textwidth]{../images/", i,"} \\end{frame}", sep="")
}), sep="\n\n")
