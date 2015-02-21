

# compile up a data set to run colony
#' @param data_file file with the data in it to use
#' @param dir_name the main subdirectory to put stuff into.  Can have a / denoting subdirectory.
#' @param locus_numbers indices of loci to include
#' @param opt_strings named vector of options strings to pass to SimpleColonyRun.sh.  The names
#' of the vector must be the names of the subdirectories you want to put the corresponding colony runs into
createColonyRunArea <- function(data_file = "./data/chinook_full_sibs.Rda", 
                                dir_name = "colony-runs", 
                                locus_numbers = 1:95, 
                                opt_strings = c("full-colony" = paste(" -y -d 0.0 -m 0.005 -L -f -S", floor(runif(1, min = 1, max = 100000))),
                                                "pairwise-colony" = paste(" -y -d 0.0 -m 0.005 -L -f  -x  -S", floor(runif(1, min = 1, max = 100000)))
                                )
) {
  # load the data:
  load(data_file)
  
  # make a directory to put the results
  dir.create(dir_name, recursive = TRUE, showWarnings = FALSE)
  
  # get the locus columns from the indices
  loc_cols <- as.vector(rbind(locus_numbers*2-1, locus_numbers*2))
  
  # write it out to a nice file with 0's for missing data
  write.table(chinook_full_sibs_genos[, loc_cols], file = file.path(dir_name, "genotypes.txt"), quote = FALSE, na = "0", col.names = FALSE)
  
  
  
  comm_lines <- paste("./script/SimpleColonyRun.sh ", opt_strings, dir_name, names(opt_strings), "input 0" )
  
  lapply(comm_lines, function(x) system(x)) 
}
                                


# read the colony stdout files to get the start and end times and so compute the total execution time.
getColonyRunTime <- function(tt) {
  L <- readLines(tt)
  LL <-  L[max(grep(pattern = "TotalRunningTime", L))]
  times <- strsplit(x = LL, "  *")[[1]]
  ret <- as.numeric(times[length(times)])
  names(ret) <- "Minutes"
  ret
}


#' read the colony BestFSFamily file and get the inferred sibships into a standardized format
#' 
#' The standardized format is a list of sibships where the individuals are named by index 
#' (i.e, 1, 2, 3...) according to data set order, rather than by their ID.
#' 
#' 
#'  @param file path to the colony output file
#'  @param indices A vector of indexes (starting from 1) of the individuals in the data set.
#'  the names of the indices must be the names of the individuals in the data set.
slurpColonyResults <- function(file, indices) {
  ss <- strsplit(readLines(file)[-1], "  *")  # the -1 there drops the header line
  ProbInc <- as.numeric(sapply(ss, function(x) x[3]))
  ProbExc <- as.numeric(sapply(ss, function(x) x[4]))
  SibsByNames <- lapply(ss, function(x) x[-(1:4)])
  Sibs <- lapply(SibsByNames, function(x) sort(unname(indices[x])))  # these are the indices, sorted nicely.
  
  # now for convenience order by sibship size and then index of the first indiv
  ord <- order(sapply(Sibs, length), -sapply(Sibs, function(x) x[1]), decreasing = T)
  
  list(ProbInc = ProbInc[ord], 
       ProbExc = ProbExc[ord], 
       sets = Sibs[ord],
       num.entries=length(unlist(Sibs)),
       num.distinct=length(unique(unlist(Sibs))),
       num.more.than.once=sum(table(unlist(Sibs))>1)
  )
}




#' read the fullsniplings results into our standardized format 
#' 
#' @param fsr  The fullsniplings result object as returned by run_mcmc
#' @param NumReps  The number of MCMC sweeps
slurpFullSniplingsResults <- function(fsr, NumReps = 500) {
  Sibs <- lapply(strsplit(rownames(fsr$Partition), "-"), function(x) as.numeric(x)+1)
  Prob <- fsr$Partition$Visits / NumReps
  
  # then order them
  ord <- order(sapply(Sibs, length), -sapply(Sibs, function(x) x[1]), decreasing = T)
  
  ul <- unlist(Sibs)
  list(Prob = Prob[ord],
       sets = Sibs[ord],
       num.entries=length(ul),
       num.distinct=length(unique(ul)),
       num.more.than.once=sum(table(ul)>1)
  )
}




#' computes the average number of non-sibs in inferred sibships
#' 
#' And also computes the average number of sibs missing.  
#' For each individual i in an inferred sibship this function counts the
#' average number of "errors of commission" (number of individuals 
#' incorrectly declared to be i's sibling.  And it averages over i.
#' It also computes for each individual i the number of his true sibs
#' missing from the sibroup he is inferred to be in.
#' This function operates on a list of sibships
#' @param I our standard inferred sibships output list
#' @param TR our standard true sibships output list 
#' if \code{Ind} is the base-1 index of an individual then 
#' \code{sg.list[[Ind+1]]} is a vector of the base-1 indices of all of its full siblings
#' @export
ave_errors_of_commission_and_omission <- function(I, TR) {
  
  # make a list such that element i is all the individuals that are in the full sibship of i 
  # (include i itself)
  sibs_of_i <- list()
  for(S in TR$sets) for(i in S) sibs_of_i[[i]] <- S
  
  # define a quick function that computes the mean on a single inferred sibgroup with 
  # elements x
  om_mean <- function(x) {mean(sapply(x, function(z) length(setdiff(sibs_of_i[[z]], x))))}
  com_mean <- function(x) {mean(sapply(x, function(z) length(setdiff(x, sibs_of_i[[z]]))))}
  
  # then lapply that function over S
  list(AveNumSibsMissing = sapply(I$sets, om_mean), AveNumNonSibs = sapply(I$sets, com_mean))
  
}





#' take a list of inferred siblings and a list of true sibgroups and convert to a data frame
#' 
#' Output has a column for false-positives and another for whether the sib group is complete
#' @param I  The Inferred sibgroups in a list with each sibgroup sorted by number (our standard output list)
#' @param TR The true sibgroups in our standard output list
sib_list_to_data_frame <- function(I, TR) {
  ret <- data.frame(Posterior = I$Prob, NumSibs = sapply(I$sets, length))
  rownames(ret) <- sapply(I$sets, function(x) paste(sort(x), collapse="-"))
   
  # now, make names of the true sibgroups and store them in a vector
  true_sibgroups_as_strings <- sapply(TR$sets, function(x) paste(sort(x), collapse="-"))
  
  
  # then get average errors of commission and omission
  OmAndCom <- ave_errors_of_commission_and_omission(I, TR)
  ret$AveNumNonSibs <- OmAndCom$AveNumNonSibs
  ret$AveNumSibsMissing <- OmAndCom$AveNumSibsMissing
  
  # now put them in order by posterior and then size
  ord <- order(ret$Posterior, ret$NumSibs, decreasing = T)
  ret <- ret[ord, ]
  
  # now, add columns for Correct sibgroups as well as cumulative number of indivs in correct v incorrect sibgroups
  ret$Correct <- rownames(ret) %in% true_sibgroups_as_strings
  ret$CumulCorrectSibs <- cumsum(ret$NumSibs * ret$Correct)
  ret$CumulSibsInIncorrectSibships <- cumsum(ret$NumSibs * (1-ret$Correct))
  
  ret
  
}


#' plot posterior bars and compare to correct or incorrect
#' 
#' Makes a nice plot. 
#' @param ISG  an inferred sibling group data frame as gets made by sib_list_to_data_frame
#' @param SS vector of sibsizes
#' @param post  vector of posteriors associated with each sibship (between 0 and 1)
#' @param false_positive A logical vector indicating whether the sibship included
#' any non-sibs
#' @param lscale how big should the lengths be on the y-scale. i.e. one sibling = lscale
#' @param correct  logical vector saying whether each inferred sibship is correct or not
#' @param add TRUE means add to existing plot
#' @export
inferred_sibs_bugle_plot <- function(ISG, lscale = .01, add = FALSE, ...) {

  L <- nrow(ISG)
  
  SS <- ISG$NumSibs
  post <- ISG$Posterior
  false_positive <- ISG$AveNumNonSibs > 0 
  correct <- ISG$Correct
  
  # tops and bottoms of our segments
  bots <- post - lscale * SS / 2
  tops <- post + lscale * SS / 2
  
  # set up plot area
  if(add == FALSE) plot(c(1,L), c(0,1.2), type="n", 
                        ylab = "Estimated Posterior Probability of Inferred Sibling Group", 
                        xlab = "Index of Inferred Sibling Group (Ordered by Posterior, Size)",
                        ...)
  
  # plot the segments 
  segments(x0 = 1:L, y0 = bots, x1 = 1:L, y1 = tops, col=c("gray", "blue", "red")[(!correct) + 1 + false_positive])
  lines(1:L, post)
  
  # put the legend in the lower right
  legend("bottomleft", 
         legend = c("Correctly-inferred sibling group", "Incomplete sibling group", "Grouping of non-siblings"), 
         col = c("gray", "blue", "red"), lty = "solid"
  )
}






#' plot posterior bars and compare to correct or incorrect
#' 
#' Makes a nice plot. 
#' @param ISG  an inferred sibling group data frame as gets made by sib_list_to_data_frame
#' @param SS vector of sibsizes
#' @param post  vector of posteriors associated with each sibship (between 0 and 1)
#' @param false_positive A logical vector indicating whether the sibship included
#' any non-sibs
#' @param lscale how big should the lengths be on the y-scale. i.e. one sibling = lscale
#' @param correct  logical vector saying whether each inferred sibship is correct or not
#' @param add TRUE means add to existing plot
#' @export
final_bugle_plot <- function(ISG, lscale = .01, add = FALSE, 
                             XLAB = "Index of Inferred Sibling Group", 
                             YLAB = "Estimated Posterior Probability",
                             ...) {
  
  L <- nrow(ISG)
  
  SS <- ISG$NumSibs
  post <- ISG$Posterior
  false_positive <- ISG$AveNumNonSibs > 0 
  correct <- ISG$Correct
  
  # tops and bottoms of our segments
  bots <- post - lscale * SS / 2
  tops <- post + lscale * SS / 2
  
  # set up plot area
  if(add == FALSE) plot(c(1,L), c(0,1.2), type="n", 
                        ylab = YLAB, 
                        xlab = XLAB,
                        ...)
  
  # plot the segments 
  segments(x0 = 1:L, y0 = bots, x1 = 1:L, y1 = tops, col=c("lightgray", "blue", "darkorange")[(!correct) + 1 + false_positive])
  lines(1:L, post)
  
  # put the legend in the lower right
  #legend("bottomleft", 
  #       legend = c("Correctly-inferred sibling group", "Incomplete sibling group", "Grouping of non-siblings"), 
  #       col = c("lightgray", "blue", "red"), lty = "solid"
  #)
}
