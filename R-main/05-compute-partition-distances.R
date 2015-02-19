
REDO_PDS = FALSE

load("outputs/InferredSibgroups.Rda")
load("outputs/TrueSibgroups.Rda")
load("outputs/PartitionDistances.Rda")
source("R/colony-comp-funcs.R")



# just for giggles, get the mean size of the Colony inferred sibgroups (about 3.07)
mean(sapply(InferredSibgroups$Full.colony$sets, length))

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


global_nn <<- 0
NNnames <- c("Colony", "Colony-pairwise", "Colony (with sib-prior = 3.07)", "Colony 25 Loci with Sib Prior", "Fullsniplings", "Fullsnip_100")
lapply(sib_group_df_list, function(x) {
  global_nn <<- global_nn + 1
  pdf(file = paste("bugle-plot-", NNnames[global_nn], ".pdf", sep=""), width = 9.7, height = 6)
  inferred_sibs_bugle_plot(x, lscale=.04, main=paste(NNnames[global_nn])) #, "     PD:", PartitionDistances[global_nn, "pd"]))
  dev.off()
  })

# copy two of those files to an images directory
file.copy(from = c("bugle-plot-Fullsniplings.pdf", "bugle-plot-Colony.pdf", "bugle-plot-Colony (with sib-prior = 3.07).pdf"), to = "../images/", overwrite = TRUE)

