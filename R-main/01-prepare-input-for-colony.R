
# must be run in the project directory. (the one that has colony_compare.Rproj in it)


source("R/colony-comp-funcs.R")


set.seed(10)  # this makes sure that Colony's seed gets set reproducibly

# this makes the subdirectories "full-colony" and "pairwise-colony"
createColonyRunArea()

