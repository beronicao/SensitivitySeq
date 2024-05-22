library(keras)

set.seed(1234)

# Define a few parameters to be used in the model: 
n_batch_size <- 5000
n_epochs <- 25
# class_weights = list('0'=1, '1'=5) 

# Define Model Architecture:
input_A <- layer_input(shape = c(969), dtype = 'float32', name = 'input_A')

out_A <- input_A %>%
  layer_dense(units = 969, activation = 'relu', input_shape = c(969)) %>%
  layer_dense(units = 512, activation = 'relu') %>%
  layer_dense(units = 256, activation = 'relu') %>%
  layer_dense(units = 128, activation = 'relu') %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dense(units = 32, activation = 'linear')

input_B <- layer_input(shape = c(969), dtype = 'float32', name = 'input_B')

out_B <- input_B %>% 
  layer_dense(units = 969, activation = 'relu', input_shape = c(969)) %>%
  layer_dense(units = 512, activation = 'relu') %>%
  layer_dense(units = 256, activation = 'relu') %>%
  layer_dense(units = 128, activation = 'relu') %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dense(units = 32, activation = 'linear')

output <- layer_concatenate(c(out_A, out_B)) %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dropout(rate = 0.15) %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dropout(rate = 0.15) %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dropout(rate = 0.15) %>%
  layer_dense(units = 1, activation = 'sigmoid', name = 'output')

SS_model <- keras_model(
  inputs = c(input_A, input_B),
  outputs = c(output)
)

SS_model %>% compile(
  optimizer = 'adam',
  loss = list(output = 'binary_crossentropy'),
  loss_weights = list(output = 1.0),
  metrics = c('binary_accuracy')
)

# summary(SS_model) # print summary of model (optional)

history.fit <- SS_model %>% fit(
  x = list(input_A = train_A, input_B = train_B),
  y = train_labels[,2], 
  epochs = n_epochs, 
  # class_weight = class_weights, 
  batch_size = n_batch_size,
  validation_data = list(
    x = list(input_A = val_A, input_B = val_B), 
    y = val_labels[,2]
  )
)

# plot(history.fit). # plot model training and validation (optional)

## Save model: #
save_model_hdf5(SS_model, "SS_CNN_model_hdf5.h5")

## Save model weights: #
save_model_weights_hdf5(SS_model, "SS_CNN_model_weights_hdf5.h5") 

## Load pre-trained model: #
# SS_model <- load_model_hdf5("SS_CNN_model_hdf5.h5")
# SS_model <- load_model_weights_hdf5(SS_model, "SS_CNN_model_weights_hdf5.h5")

## Generate predictions: #
predict <- SS_model %>% predict(
  x = list(input_A = test_A, input_B = test_B),
  batch_size = n_batch_size)

## Generate predictions: #
score <- SS_model %>% evaluate(
  x = list(input_A = test_A, input_B = test_B),
  y = test_labels[,2],
  batch_size = n_batch_size)



