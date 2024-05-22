library(shiny)
library(DT)
library(plyr)
library(dplyr)
library(data.table)

get_tumor_type_codes <- function(dir = NULL) {  
  if(is.null(dir)){
    dir <- "../../data/"
  } else {
    dir = dir
  }
  DepMap_TCGA_models <- read.csv(file = paste0(dir, "DepMap_TCGA_table.csv"), header = T, check.names = F)
  DepMap_TCGA_types <- unique(DepMap_TCGA_models$TCGA_model_src_name)
  return(DepMap_TCGA_types)
}

get_tumor_types <- function(dir = NULL) {  
  if(is.null(dir)){
    dir <- "../../data/"
  } else {
    dir = dir
  }
  TCGA_tbl <- read.csv(file = paste0(dir, "TCGA_table.csv"), header = T, check.names = F)
  return(TCGA_tbl)
}

get_predictions <- function(dir = NULL) {  
  if(is.null(dir)){
    dir <- "../../data/"
  } else {
    dir = dir
  }
  # DepMap_TCGA_types <- get_tumor_type_codes()
  # prediction_files.df <- data.frame(filename=NULL)
  # for (i in DepMap_TCGA_types[1:length(DepMap_TCGA_types)]) {
  #   prediction_files.df[i,1] <- paste(dir, i, "_prediction_estimates_model1.csv", sep = "")
  # }
  # prediction_files <- sapply( rownames(prediction_files.df), function(x) as.list(prediction_files.df[x,]) )
  percentage <- 0
all_predictions.df <- readRDS(paste(dir,"all_predictions.LINCS_LDP_links_tbl.rds",sep = ""))
return(all_predictions.df) 
}
