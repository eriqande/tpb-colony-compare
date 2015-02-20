

## This should be run in the same directory that holds the RStudio project tpb-colony-compare.Rproj

# run these and then make sure that the processes have all finished
source("R-main/01-prepare-input-for-colony.R")
source("R-main/02-run-colony.R")
source("R-main/03-run-fullsniplings.R")


# then run these
source("R-main/04-collate-and-format-results.R")
source("R-main/05-compute-partition-distances.R")

# then these
source("R-main/06-do-fullsniplings-drop-loci-experiment.R")
source("R-main/07-do-colony-drop-loci-experiment.R")

# and then these
source("R-main/08-analyze-drop-loci-experiments.R")

