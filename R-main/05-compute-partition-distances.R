
REDO_PDS = TRUE  # set to false if you have already computed the partition distances

load("outputs/InferredSibgroups.Rda")
load("outputs/TrueSibgroups.Rda")
if(!REDO_PDS) {
  load("outputs/PartitionDistances.Rda")
}
source("R/colony-comp-funcs.R")



# et the mean size of the Colony inferred sibgroups (about 3.07) for use later
ColonyFirstRunMeanSibsize <- mean(sapply(InferredSibgroups$Full.colony$sets, length))

if(REDO_PDS) {
  message("compiling up glpk components to use as a dyn.load")
  system("R CMD INSTALL partition-distance-calculation/glpk")
  
  pd_path <- "partition-distance-calculation"
  source(file.path(pd_path, "R/SibAssessRfunctions.R"));
  
  PartitionDistances <- t(sapply(InferredSibgroups, function(x) PD(truth = TrueSibgroups, est = x)))
  
  save(PartitionDistances, file = "outputs/PartitionDistances.Rda")
}

# make some bugle plts here too
sib_group_df_list <- lapply(InferredSibgroups, function(x) {
  if(!("Prob" %in% names(x))) x$Prob <- x$ProbExc  # deal with colony having two types of posteriors
  sib_list_to_data_frame(I = x, TR = TrueSibgroups)}
  )


dir.create("plots", showWarnings = FALSE)
global_nn <<- 0
NNnames <- c("Colony", "Colony-pairwise", "Fullsniplings", "Fullsnip_100")
lapply(sib_group_df_list, function(x) {
  global_nn <<- global_nn + 1
  pdf(file = paste("plots/bugle-plot-", NNnames[global_nn], ".pdf", sep=""), width = 9.7, height = 6)
  inferred_sibs_bugle_plot(x, lscale=.04, main=paste(NNnames[global_nn])) #, "     PD:", PartitionDistances[global_nn, "pd"]))
  dev.off()
  })


