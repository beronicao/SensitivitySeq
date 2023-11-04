library(plyr)
library(dplyr)

get_tumor_types <- function(dir = NULL) {  
  if(is.null(dir)){
    dir <- "../data/"
  } else {
    dir = dir
  }
  DepMap_TCGA_models <- read.csv(file = paste0(dir, "DepMap_TCGA_table.csv"), header = T)
  DepMap_TCGA_types <- unique(DepMap_TCGA_models$TCGA_model_src_name)
  return(DepMap_TCGA_types)
}

get_predictions <- function(dir = NULL) {  
  if(is.null(dir)){
    dir <- "../data/"
  } else {
    dir = dir
  }
  DepMap_TCGA_types <- get_tumor_types()
  prediction_files.df <- data.frame(filename=NULL)
  for (i in DepMap_TCGA_types[1:length(DepMap_TCGA_types)]) {
    prediction_files.df[i,1] <- paste(dir, i, "_prediction_estimates_model1.csv", sep = "")
  }
  prediction_files <- sapply( rownames(prediction_files.df), function(x) as.list(prediction_files.df[x,]) )
  percentage <- 0
  predictions_list <- llply(names(prediction_files), function(y){ 
    percentage <<- percentage + 1/length(prediction_files)*100
    incProgress(1/length(prediction_files), detail = paste0(" Progress: ",round(percentage,2),"%"))
    read.csv(file=prediction_files[[y]]) %>% 
      split(., f = .$pert_cmap_iname) 
  } )
  predictions_list <- setNames(predictions_list, names(prediction_files))
  return(predictions_list)
}
