
# must be run in the project directory. (the one that has colony_compare.Rproj in it)

# start the full-likelihood colony run
cd "colony-runs/full-colony/"
nohup ../../bin/colony2s.out > colony-stdout.txt &
cd ../..


# start the pairwise likelihood run
cd "colony-runs/pairwise-colony/"
nohup ../../bin/colony2s.out > colony-stdout.txt &
cd ../..

