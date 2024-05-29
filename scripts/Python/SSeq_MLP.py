import os
import keras
import pandas as pd
import numpy as np
import tensorflow as tf

print(keras.__version__)
# 2.11.0

# Set seed
n_seed = 1234
np.random.seed(n_seed)
tf.random.set_seed(n_seed)

# Define a few parameters to be used in the model: 
n_batch_size = 5000
n_epochs = 25

# Load train, valid, test sets and their labels (csv files)

from tensorflow.keras.layers import Input, Dense, Concatenate, Dropout
from tensorflow.keras.models import Model
from tensorflow.keras.models import load_model

# Define the input layer for x_input.v8
input_A_MLP = Input(shape=(969,), dtype='float32', name='input_A_MLP')
# Define the dense layers for x_out.v8
out_A_MLP = Dense(units=969, activation='relu')(input_A_MLP)
out_A_MLP = Dense(units=512, activation='relu')(out_A_MLP)
out_A_MLP = Dense(units=256, activation='relu')(out_A_MLP)
out_A_MLP = Dense(units=128, activation='relu')(out_A_MLP)
out_A_MLP = Dense(units=64, activation='relu')(out_A_MLP)
out_A_MLP = Dense(units=32, activation='linear')(out_A_MLP)

# Define the input layer for y_input.v8
input_B_MLP = Input(shape=(969,), dtype='float32', name='input_B_MLP')
# Define the dense layers for y_out.v8
out_B_MLP = Dense(units=969, activation='relu')(input_B_MLP)
out_B_MLP = Dense(units=512, activation='relu')(out_B_MLP)
out_B_MLP = Dense(units=256, activation='relu')(out_B_MLP)
out_B_MLP = Dense(units=128, activation='relu')(out_B_MLP)
out_B_MLP = Dense(units=64, activation='relu')(out_B_MLP)
out_B_MLP = Dense(units=32, activation='linear')(out_B_MLP)

# Concatenate the outputs of x_out.v8 and y_out.v8
output_MLP = Concatenate()([out_A_MLP, out_B_MLP])
# Add dense and dropout layers after concatenation
output_MLP = Dense(units=64, activation='relu')(output_MLP)
output_MLP = Dropout(rate=0.15)(output_MLP)
output_MLP = Dense(units=64, activation='relu')(output_MLP)
output_MLP = Dropout(rate=0.15)(output_MLP)
output_MLP = Dense(units=64, activation='relu')(output_MLP)
output_MLP = Dropout(rate=0.15)(output_MLP)
output_MLP = Dense(units=1, activation='sigmoid', name='output_MLP')(output_MLP)

# Define the model with the specified inputs and outputs
SSeq_model = Model(inputs=[input_A_MLP, input_B_MLP], outputs=[output_MLP])

# Print the model summary
SSeq_model.summary()

# Compile the model
SSeq_model.compile(
    optimizer='adam',
    loss={'output': 'binary_crossentropy'},
    loss_weights={'output': 1.0},
    metrics=['binary_accuracy']
)

# Fit the model
history_fit = SSeq_model.fit(
    x={'input_A_MLP': train_A, 'input_B_MLP': train_B},
    y=train_labels.iloc[:, 1],
    epochs=n_epochs,
    batch_size=n_batch_size,
    validation_data=({'input_A_MLP': val_A, 'input_B_MLP': val_B}, val_labels.iloc[:, 1])
)

# Use matplotlib to plot the history (optional)
import matplotlib.pyplot as plt

# Plot training & validation accuracy values
plt.figure(figsize=(10, 5))
plt.plot(history_fit.history['binary_accuracy'])
plt.plot(history_fit.history['val_binary_accuracy'])
plt.title('Model accuracy')
plt.ylabel('Accuracy')
plt.xlabel('Epoch')
plt.legend(['Train', 'Validation'], loc='upper left')
plt.savefig('accuracy_plot.png')

# Plot training & validation loss values
plt.figure(figsize=(10, 5))
plt.plot(history_fit.history['loss'])
plt.plot(history_fit.history['val_loss'])
plt.title('Model loss')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['Train', 'Validation'], loc='upper left')
plt.savefig('loss_plot.png')

# Save the entire model
SSeq_model.save("SSeq_MLP_model.h5")

# Save model weights
SSeq_model.save_weights("SSeq_MLP_model_weights.h5")

# Generate predictions
predictions = SSeq_model.predict(
    x={'input_A_MLP': test_A, 'input_B_MLP': test_B},
    batch_size=n_batch_size
)

# Evaluate the model
score = SSeq_model.evaluate(
    x={'input_A_MLP': test_A, 'input_B_MLP': test_B},
    y=test_labels.iloc[:, 1],
    batch_size=n_batch_size
)
