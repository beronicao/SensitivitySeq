# Load required libraries
library(keras)
library(tensorflow)
library(tibble)
library(reshape2)
library(ggplot2)
library(yardstick)
library(verification)
library(forcats)

# Define constants
n_batch_size <- 5000
n_seed <- 1234 

# Set seed for reproducibility
set.seed(n_seed)
tensorflow::set_random_seed(seed = n_seed)

## Load pre-trained model: #
SS_model <- load_model_hdf5("SS_MLP_model_hdf5.h5")
SS_model <- load_model_weights_hdf5(SS_model, "SS_MLP_model_weights_hdf5.h5")

# Predict on new data
predict <- SS_model %>% predict(
  x = list(input_A = test_A, input_B = test_B),
  batch_size = n_batch_size
)

# Save predictions
saveRDS(predict, "predict.rds")

# Evaluate the model
score <- SS_model %>% evaluate(
  x = list(input_A = test_A, input_B = test_B),
  y = test_labels[,2],
  batch_size = n_batch_size
)

# Save the evaluation score
# saveRDS(score, "score.rds")

# Format predictions and truth for evaluation
truth <- as.factor(test_labels[,2]) %>% fct_recode(yes = "1", no = "0")
estimate <- as.vector(predict)
classes <- as.factor(ifelse(estimate >= 0.5, "yes", "no"))

estimates_keras_tbl <- tibble(
  truth = truth,
  estimate = estimate,
  classes = classes
)

# Save the estimates table
saveRDS(estimates_keras_tbl, "SS_model_estimates_keras_tbl.rds")
# write.csv(estimates_keras_tbl, "SS_model_estimates_keras_tbl.csv")

# Calculate and plot evaluation metrics
options(yardstick.event_first = FALSE)
roc.keras <- roc_auc(estimates_keras_tbl, truth, estimate, event_level = 'second')
roc_curve.keras <- roc_curve(estimates_keras_tbl, truth, estimate, event_level = 'second')

# saveRDS(roc.keras, "SS_model_roc.keras.rds")
# saveRDS(roc_curve.keras, "SS_model_roc_curve.keras.rds")

precision <- tryCatch({
  estimates_keras_tbl %>% precision(truth, classes)
}, error = function(e) { NA })

recall <- tryCatch({
  estimates_keras_tbl %>% recall(truth, classes)
}, error = function(e) { NA })

# saveRDS(precision, "SS_model_precision.rds")
# saveRDS(recall, "SS_model_recall.rds")

pr.keras <- pr_auc(estimates_keras_tbl, truth, estimate, event_level = 'second')
pr_curve.keras <- pr_curve(estimates_keras_tbl, truth, estimate, event_level = 'second')

# saveRDS(pr.keras, "SS_model_pr.keras.rds")
# saveRDS(pr_curve.keras, "SS_model_pr_curve.keras.rds")

# Confusion matrix
conf.mat <- table(truth, classes)
saveRDS(conf.mat, "SS_model_conf.mat.rds")

conf_mat_labeled <- as.data.frame.matrix(conf.mat)
rownames(conf_mat_labeled) <- c("actual_score=0", "actual_score=1")
colnames(conf_mat_labeled) <- c("predicted_score=0", "predicted_score=1")
write.csv(conf.mat, "confusion_matrix.csv")

# Calculate additional metrics
FPR <- tryCatch({
  (conf.mat[1, 2]) / ((conf.mat[1, 2]) + (conf.mat[1, 1]))
}, error = function(e) { NA })

TPR <- tryCatch({
  (conf.mat[2, 2]) / ((conf.mat[2, 2]) + (conf.mat[2, 1]))
}, error = function(e) { NA })

FNR <- tryCatch({
  (conf.mat[2, 1]) / ((conf.mat[2, 2]) + (conf.mat[2, 1]))
}, error = function(e) { NA })

TNR <- tryCatch({
  (conf.mat[1, 1]) / ((conf.mat[1, 2]) + (conf.mat[1, 1]))
}, error = function(e) { NA })

# Print results
results_table <- data.frame(
  Model = "SS Model",
  Loss = round(score[1], 4),
  Accuracy = paste0(round(score[2] * 100, 2), "%"),
  AUROC = tryCatch({ paste0(round(roc.keras$.estimate * 100, 2), "%") }, error = function(e) { NA }),
  AUPR = tryCatch({ paste0(round(pr.keras$.estimate * 100, 2), "%") }, error = function(e) { NA }),
  Precision = tryCatch({ paste0(round(precision$.estimate * 100, 2), "%") }, error = function(e) { NA }),
  Sensitivity = tryCatch({ paste0(round(TPR * 100, 2), "%") }, error = function(e) { NA }),
  Specificity = tryCatch({ paste0(round(TNR * 100, 2), "%") }, error = function(e) { NA })
)

# saveRDS(results_table, "results_table.SS_model.rds")
write.csv(results_table, "results_table.SS_model.csv", row.names = FALSE)

# Plot results
plot(history.fit)
hist(predict)

roc_curve(estimates_keras_tbl, truth, estimate) %>% autoplot()

pr_curve(estimates_keras_tbl, truth, estimate) %>% autoplot()

# Save model history plot as a PDF file
pdf("history_fit_plot.pdf")
plot(history.fit)
dev.off()

# Save histogram of model predictions as a PDF file
pdf("predict_hist_plot.pdf")
hist(predict)
dev.off()

# Save ROC curve plot as a PDF file
pdf("roc_curve_plot.pdf")
roc_curve(estimates_keras_tbl, truth, estimate, event_level = 'second') %>% autoplot()
dev.off()

# Save precision-recall curve plot as a PDF file
pdf("pr_curve_plot.pdf")
pr_curve(estimates_keras_tbl, truth, estimate, event_level = 'second') %>% autoplot()
dev.off()



