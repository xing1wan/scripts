# Load required packages
library(mlr3)
library(mlr3learners)

# Load the Iris dataset
data(iris)

# Split the dataset into training and testing sets
train_indices <- sample(seq_len(nrow(iris)), size = 0.7 * nrow(iris))
train_data <- iris[train_indices,]
test_data <- iris[-train_indices,]

# Create a task for the training data
train_task <- mlr3::TaskClassif$new("iris_train_task", backend = train_data, target = "Species")

# Create a learner for classification using the 'rpart' package
learner <- mlr3::lrn("classif.rpart")

# Train the model
learner$train(train_task)

# Create a new data point with Sepal.Length, Sepal.Width, Petal.Length, and Petal.Width values
new_data <- data.frame(
  Sepal.Length = 5.0,
  Sepal.Width = 3.5,
  Petal.Length = 1.5,
  Petal.Width = 0.2
)

# Make a prediction for the new data point
prediction <- learner$predict_newdata(new_data)

# View the predicted Species
print(prediction$response)

