# test keras and tensor flow
# based on https://keras.rstudio.com/

library(keras)

# download the data
mnist <- dataset_mnist()

# prepare
x_train <- mnist$train$x
y_train <- mnist$train$y
x_test <- mnist$test$x
y_test <- mnist$test$y

# reshape
x_train <- array_reshape(x_train, c(nrow(x_train), 784))
x_test <- array_reshape(x_test, c(nrow(x_test), 784))
# rescale
x_train <- x_train / 255
x_test <- x_test / 255

# one hot encoding
y_train <- to_categorical(y_train, 10)
y_test <- to_categorical(y_test, 10)

# model
model <- keras_model_sequential() 
model %>% 
    layer_dense(units = 256, activation = 'relu', input_shape = c(784)) %>% 
    layer_dropout(rate = 0.4) %>% 
    layer_dense(units = 128, activation = 'relu') %>%
    layer_dropout(rate = 0.3) %>%
    layer_dense(units = 10, activation = 'softmax')
summary(model)

# compile
model %>% 
    compile(
        loss = 'categorical_crossentropy',
        optimizer = optimizer_rmsprop(),
        metrics = c('accuracy')
    )

# train
# check host using `watch -n 1 nvidia-smi`
history <- model %>% fit(
  x_train, y_train, 
  epochs = 5, batch_size = 128, 
  validation_split = 0.2
)

# evaluate
model %>% 
    evaluate(x_test, y_test) %>%
    print()
