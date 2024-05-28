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
input_A = Input(shape=(969,), dtype='float32', name='input_A')
# Define the dense layers for x_out.v8
out_A = Dense(units=969, activation='relu')(input_A)
out_A = Dense(units=512, activation='relu')(out_A)
out_A = Dense(units=256, activation='relu')(out_A)
out_A = Dense(units=128, activation='relu')(out_A)
out_A = Dense(units=64, activation='relu')(out_A)
out_A = Dense(units=32, activation='linear')(out_A)

# Define the input layer for y_input.v8
input_B = Input(shape=(969,), dtype='float32', name='input_B')
# Define the dense layers for y_out.v8
out_B = Dense(units=969, activation='relu')(input_B)
out_B = Dense(units=512, activation='relu')(out_B)
out_B = Dense(units=256, activation='relu')(out_B)
out_B = Dense(units=128, activation='relu')(out_B)
out_B = Dense(units=64, activation='relu')(out_B)
out_B = Dense(units=32, activation='linear')(out_B)

# Concatenate the outputs of x_out.v8 and y_out.v8
output = Concatenate()([out_A, out_B])
# Add dense and dropout layers after concatenation
output = Dense(units=64, activation='relu')(output)
output = Dropout(rate=0.15)(output)
output = Dense(units=64, activation='relu')(output)
output = Dropout(rate=0.15)(output)
output = Dense(units=64, activation='relu')(output)
output = Dropout(rate=0.15)(output)
output = Dense(units=1, activation='sigmoid', name='output')(output)

# Define the model with the specified inputs and outputs
SS_model = Model(inputs=[input_A, input_B], outputs=[output])

# Print the model summary
SS_model.summary()


# Compile the model
SS_model.compile(
    optimizer='adam',
    loss={'output': 'binary_crossentropy'},
    loss_weights={'output': 1.0},
    metrics=['binary_accuracy']
)


# Fit the model
history_fit = SS_model.fit(
    x={'input_A': train_A, 'input_B': train_B},
    y=train_labels.iloc[:, 1],
    epochs=n_epochs,
    batch_size=n_batch_size,
    validation_data=({'input_A': val_A, 'input_B': val_B}, val_labels.iloc[:, 1])
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
SS_model.save("SS_MLP_model.h5")

# Save model weights
SS_model.save_weights("SS_MLP_model_weights.h5")


# Generate predictions
predictions = SS_model.predict(
    x={'input_A': test_A, 'input_B': test_B},
    batch_size=n_batch_size
)


# Evaluate the model
score = SS_model.evaluate(
    x={'input_A': test_A, 'input_B': test_B},
    y=test_labels.iloc[:, 1],
    batch_size=n_batch_size
)



