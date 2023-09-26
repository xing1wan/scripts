### nested Cross-validation (resampling)
# Load required libraries
library(mlr3)
library(mlr3tuning)
# Create a task
train_task2 <- mlr3::TaskClassif$new("laccases", backend = train_data2, target = "ph_scale")
# Create a learner
learner <- lrn("classif.rpart")
# Define resampling for inner CV, with 5 iterations 
resampling_inner <- rsmp("cv", folds = 5)
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

# Define a tuner
tuner <- tnr("grid_search", resolution = 10)
# Tune hyperparameters using inner CV
res <- tune(learner, task=train_task2, resampling = resampling_inner, measure = msr("classif.ce"), search_space = param_set, terminator = trm("none"), tuner = tuner)
# Check best hyperparameters from the inner CV (the optimal cp value)
res$result_x_domain$cp
# The result from e.g. train_task2 is [1] 0.089 

# Define resampling for outer CV, with 3 iterations
resampling_outer <- rsmp("cv", folds = 3)
# Create a learner
learner <- lrn("classif.rpart")
# Set the optimal cp value from inner CV to the learner, i.e. 0.089
learner$param_set$values = list(cp = res$result_x_domain$cp)
# Assess performance using outer CV with optimal cp value
rr <- resample(train_task2, learner, resampling_outer)
# Print performance
rr$aggregate()
# classif.ce is 0.1488889 which means on average, the classifier made an incorrect prediction approximately 14.89% of the time across all the folds of the outer CV.

# Set the optimal cp value from inner CV to the learner
learner <- lrn("classif.rpart", cp = res$result_x_domain$cp)
# predict your dataset <pred_data2_NA>
task <- TaskClassif$new(id = "pred_data2", backend = pred_data2, target = "ph_scale")
predictions_rpart_tune <- learner$predict(task)


