
#### load libraries and data and code
library(ggplot2)
source("R/colony-comp-funcs.R")
load("outputs/DropLocSummaries.rda")
D <- DropLocSummaries

# make an output directory
dir.create("final_figures", showWarnings = FALSE)


#### Make the first colony-compare figure (3-panels of bugle plots)  ####
par(mfrow=c(1,3))
final_bugle_plot(D$fullsnip_df_list$"95", lscale = .04)
final_bugle_plot(D$colony_ewens_df_list$"95", lscale = .04)
final_bugle_plot(D$colony_df_list$"95", lscale = .04)



#### Now make the drop-loc figures on a 7 x 3 grid.

par(mfrow = c(4,3))
lapply(as.character(seq(85, 55, -10)), function(x) {
  lapply(c("fullsnip_df_list", "colony_ewens_df_list", "colony_df_list"), function(y){
    final_bugle_plot(D[[y]][[x]], lscale = .04, 
                     XLAB = "",
                     YLAB = "")
  })
})




#### Put the results into a long-format data frame for ggplot  ####
proglist <- c("fullsnip_df_list", "colony_ewens_df_list", "colony_df_list")
prognames <- c("fullsniplings", "colony with sib-prior", "colony-without-sib-prior")
names(prognames) <- proglist

# first, rbind them up and add identifier columns
df <- do.call(rbind, lapply(as.character(seq(95, 25, -10)), function(x) {
  do.call(rbind, lapply(proglist, function(y){
    tmp <- D[[y]][[x]]
    rownames(tmp) <- NULL
    tmp$NumSNPs <- as.numeric(x)
    tmp$Program <- prognames[y]
    tmp$Index <- 1:nrow(tmp)
    tmp
  }))
})
)


# then modify columns and make new ones for plotting with ggplot
df$Program <- factor(df$Program, levels = prognames)  # order these so they come out right
df$Status <- ifelse(df$Correct, "Correctly-inferred sibling group", 
                    ifelse(df$AveNumNonSibs >= 0.0001, "Grouping of non-siblings", "Incomplete sibling group"))
df$Status <- factor(df$Status, levels = c("Correctly-inferred sibling group", "Incomplete sibling group", "Grouping of non-siblings"))



#### Design a ggplot theme for these figures ####
bugle_theme <- function (base_size = 12, base_family = "") 
{
  theme_grey(base_size = base_size, base_family = base_family) %+replace% 
    theme(axis.text = element_text(size = rel(0.8)), 
          axis.ticks = element_line(colour = "black"), 
          legend.key = element_rect(colour = "grey50"), 
          legend.position = "bottom",
          panel.background = element_rect(fill = "white",
                                          colour = NA), 
          panel.border = element_rect(fill = NA, 
                                      colour = "grey50"), 
          panel.grid.major = element_line(colour = "grey98", 
                                          size = 0.2), 
          panel.grid.minor = element_line(colour = "grey98", 
                                          size = 0.5), 
          strip.background = element_rect(fill = "grey80", 
                                          colour = "grey50", size = 0.2)
          )
}


#### Here is a function of ggplot stuff to use ####
lscale = 0.02  # this is hacky...
ggbugle <- function(df, lscale = .02) {
  ggplot(df, aes(x = Index, y = Posterior)) + 
    geom_linerange(aes(ymin = Posterior - lscale * NumSibs,
                       ymax = Posterior + lscale * NumSibs,
                       colour = Status),
                   size = 0.1) +
    geom_line(size = 0.15) +
    scale_color_manual(values = c("grey85",  "blue", "darkorange")) +
    bugle_theme()
}

#### Do the first figure  ####
df1 <- df[df$NumSNPs ==  95, ]
ggbugle(df1) +
  facet_wrap(~ Program, ncol = 3)

ggsave(file = "final_figures/bugle_trio.pdf", width = 8.5, height = 3.3)

#### Now do the 7 x 3 grid  ####
df2 <- df[df$NumSNPs <=  85, ]
df2$NumSNPs <- factor(df2$NumSNPs, levels = seq(85, 25, -10))  # to order them top to bottom
ggbugle(df2) + 
  facet_grid(NumSNPs ~ Program, scales = "free_x")

ggsave(file = "final_figures/bugle_matrix.pdf", width = 8.5, height = 10)

#### And then make the table of partition distances ####
write.table(D$partition_distances)
