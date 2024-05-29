library(keras)

# Define a few parameters to be used in the model: 
n_batch_size <- 5000
n_epochs <- 25
# class_weights = list('0'=1, '1'=5) 
n_seed <- 1234 

# Load/import data
train_A <- readRDS("train_A.rds")
train_B <- readRDS("train_B.rds")
val_A <- readRDS("val_A.rds")
val_B <- readRDS("val_B.rds")
test_A <- readRDS("test_A.rds")
test_B <- readRDS("test_B.rds")

train_labels <- readRDS("train_labels.rds")
val_labels <- readRDS("val_labels.rds")
test_labels <- readRDS("test_labels.rds")

# Set seed
set.seed(n_seed)
tensorflow::set_random_seed(seed = n_seed)

# Define Model Architecture:
input_A_MLP <- layer_input(shape = c(969), dtype = 'float32', name = 'input_A_MLP')

out_A_MLP <- input_A_MLP %>%
  layer_dense(units = 969, activation = 'relu', input_shape = c(969)) %>%
  layer_dense(units = 512, activation = 'relu') %>%
  layer_dense(units = 256, activation = 'relu') %>%
  layer_dense(units = 128, activation = 'relu') %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dense(units = 32, activation = 'linear')

input_B_MLP <- layer_input(shape = c(969), dtype = 'float32', name = 'input_B_MLP')

out_B_MLP <- input_B_MLP %>% 
  layer_dense(units = 969, activation = 'relu', input_shape = c(969)) %>%
  layer_dense(units = 512, activation = 'relu') %>%
  layer_dense(units = 256, activation = 'relu') %>%
  layer_dense(units = 128, activation = 'relu') %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dense(units = 32, activation = 'linear')

output_MLP <- layer_concatenate(c(out_A_MLP, out_B_MLP)) %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dropout(rate = 0.15) %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dropout(rate = 0.15) %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dropout(rate = 0.15) %>%
  layer_dense(units = 1, activation = 'sigmoid', name = 'output_MLP')

SSeq_model <- keras_model(
  inputs = c(input_A_MLP, input_B_MLP),
  outputs = c(output_MLP)
)

SSeq_model %>% compile(
  optimizer = 'adam',
  loss = list(output = 'binary_crossentropy'),
  loss_weights = list(output = 1.0),
  metrics = c('binary_accuracy')
)

# summary(SSeq_model) # print summary of model (optional)

history.fit <- SSeq_model %>% fit(
  x = list(input_A_MLP = train_A, input_B_MLP = train_B),
  y = train_labels[,2], 
  epochs = n_epochs, 
  # class_weight = class_weights, 
  batch_size = n_batch_size,
  validation_data = list(
    x = list(input_A_MLP = val_A, input_B_MLP = val_B), 
    y = val_labels[,2]
  )
)

# plot(history.fit). # plot model training and validation (optional)

## Save model: #
save_model_hdf5(SSeq_model, "SSeq_MLP_model_hdf5.h5")

## Save model weights: #
save_model_weights_hdf5(SSeq_model, "SSeq_MLP_model_weights_hdf5.h5") 

## Load pre-trained model: #
# SSeq_model <- load_model_hdf5("SSeq_MLP_model_hdf5.h5")
# SSeq_model <- load_model_weights_hdf5(SSeq_model, "SSeq_MLP_model_weights_hdf5.h5")

## Generate predictions: #
predict <- SSeq_model %>% predict(
  x = list(input_A_MLP = test_A, input_B_MLP = test_B),
  batch_size = n_batch_size)

## Evaluate predictions: #
score <- SSeq_model %>% evaluate(
  x = list(input_A_MLP = test_A, input_B_MLP = test_B),
  y = test_labels[,2],
  batch_size = n_batch_size)
