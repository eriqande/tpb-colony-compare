
#### load libraries and data and code
library(ggplot2)
library(plyr)
source("R/colony-comp-funcs.R")
load("outputs/DropLocSummaries.rda")
D <- DropLocSummaries

# make an output directory
dir.create("final_figures", showWarnings = FALSE)


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


#### Here we make a data frame that will serve as the values for the "legend" for sibship size ####
sibsize_key <- function(lscale, vals = seq(12, 1, by = -1), start.pos = 50, stop.pos = 350, height = 0.3,
                        NumSNPs = 95, Program = "colony with sib-prior") {
  data.frame(xpos = seq(start.pos, stop.pos, length.out = length(vals)),
             ylo = height - vals * lscale,
             yhi = height + vals * lscale,
             sibsize = as.character(vals),
             NumSNPs = NumSNPs,
             Program = Program,
             centre = height
             )
}

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
  df$ylo = df$Posterior - lscale * df$NumSibs
  df$yhi = df$Posterior + lscale * df$NumSibs
  ggplot(df, aes(x = Index, y = Posterior)) + 
    geom_linerange(aes(ymin = ylo,
                       ymax = yhi,
                       colour = Status),
                   size = 0.1) +
    geom_line(size = 0.15) +
    scale_color_manual(values = c("grey85",  "blue", "darkorange")) +
    bugle_theme()
}

#### Do the first figure  ####
sibkey <- sibsize_key(lscale)
df1 <- df[df$NumSNPs ==  95, ]

ggbugle(df1) +
  facet_wrap(~ Program, ncol = 3) +
  geom_text(aes(xpos, yhi, label = sibsize), data = sibkey, size = 2.0, vjust = -1) +
  geom_linerange(aes(x = xpos, ymin = ylo, ymax = yhi, y = NULL), data = sibkey, color = "black", size = 0.1) + # this adds the sibsize "key" in the appropiate panel
  geom_line(aes(x = xpos, y = centre), data = sibkey, size = 0.15)
  

ggsave(file = "final_figures/bugle_trio.pdf", width = 8.5, height = 3.3)

#### Now do the 7 x 3 grid  ####
df2 <- df[df$NumSNPs <=  85, ]
df2$NumSNPs <- factor(df2$NumSNPs, levels = seq(85, 25, -10))  # to order them top to bottom
sibkey2 <- sibsize_key(lscale, 
                       NumSNPs = 85,
                       vals = seq(max(df$NumSibs), min(df$NumSibs), by = -1),
                       start.pos = 50,
                       stop.pos = 350,
                       height = 0.2)
sibkey2$NumSNPs <- factor(sibkey2$NumSNPs, levels = seq(85, 25, -10))

ggbugle(df2) + 
  facet_grid(NumSNPs ~ Program, scales = "free_x") +
  geom_text(aes(xpos, yhi, label = sibsize), data = sibkey2, size = 2.0, vjust = -1) +
  geom_linerange(aes(x = xpos, ymin = ylo, ymax = yhi, y = NULL), data = sibkey2, color = "black", size = 0.1) + # this adds the sibsize "key" in the appropiate panel
  geom_line(aes(x = xpos, y = centre), data = sibkey2, size = 0.15)

ggsave(file = "final_figures/bugle_matrix.pdf", width = 8.5, height = 10)

#### And then make the table of partition distances ####
write.table(D$partition_distances)
