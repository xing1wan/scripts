### nested Cross-validation (resampling)
# Load required libraries
library(mlr3)
library(mlr3tuning)
library(mlr3measures)
# Create a task
train_task2 <- mlr3::TaskClassif$new("laccases", backend = train_data2, target = "ph_scale")
# Define a search space for hyperparameters
# tune only cp 
# param_set <- ParamSet$new(list(ParamDbl$new("cp", lower = 0.001, upper = 0.1)))
# tuning also other important hyperparameters for the classif.rpart learner
param_set <- ParamSet$new(list(
  ParamDbl$new("cp", lower = 0.001, upper = 0.1),
  ParamInt$new("minsplit", lower = 5, upper = 50),
  ParamInt$new("minbucket", lower = 3, upper = 25),
  ParamInt$new("maxdepth", lower = 1, upper = 10)
))

# Create a learner
learner <- lrn("classif.rpart")

# Define resampling for inner CV, with 5 iterations 
resampling_inner <- rsmp("cv", folds = 5)

# Define a tuner
tuner <- tnr("grid_search", resolution = 10)

# # Tune hyperparameters using inner CV
# res <- tune(learner, task=train_task2, resampling = resampling_inner, measure = msr("classif.ce"), search_space = param_set, terminator = trm("none"), tuner = tuner)
# # Check best hyperparameters from the inner CV (the optimal cp value)
# res$result_x_domain$cp
# # The result from e.g. train_task2 is [1] 0.089 

# Define resampling for outer CV, with 3 iterations
resampling_outer <- rsmp("cv", folds = 3)
rr <- resample(train_task2, learner, resampling_outer, store_models = TRUE, 
               tuner = tuner, measure = msr("classif.ce"), search_space = param_set, 
               resampling = resampling_inner)
			   
rr$result_x_domain			   

#reset the learner
learner <- lrn("classif.rpart")

# Set the optimal values from inner CV to the learner
learner$param_set$values = list(cp = res$result_x_domain$cp, minsplit = res$result_x_domain$minsplit, minbucket = res$result_x_domain$minbucket, maxdepth = res$result_x_domain$maxdepth)

# Now, you can train the model on your training task or evaluate it using resampling strategies like CV
# Example: Training the learner on the entire training task
learner$train(train_task2)

# Make predictions on the test set using the trained, tuned learner
predictions <- learner$predict(test_task2)

# Evaluate the performance of the model on the test set using different measures
accuracy <- msr("classif.acc")$score(predictions)
precision <- msr("classif.precision")$score(predictions)
recall <- msr("classif.recall")$score(predictions)
specificity <- msr("classif.specificity")$score(predictions)
f1_score <- msr("classif.f1")$score(predictions)
auc <- msr("classif.auc")$score(predictions)

# Print the results
cat("Accuracy:", accuracy, "\n")
cat("Precision:", precision, "\n")
cat("Recall:", recall, "\n")
cat("Specificity:", specificity, "\n")
cat("F1 Score:", f1_score, "\n")
cat("AUC:", auc, "\n")

# predict your dataset e.g. <pred_data2>
task <- TaskClassif$new(id = "pred_data2", backend = pred_data2, target = "ph_scale")
predictions_rpart_tune <- learner$predict(task)
