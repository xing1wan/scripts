### nested Cross-validation (resampling)
# Load required libraries
library(mlr3)
library(mlr3tuning)
library(mlr3measures)
library(readr)

# Load your dataset for training
train_data <- read_csv("Z:/Drive_R/R/ML/data/train_data.csv")

# Clean training dataset
train_data=as.data.frame(train_data)
train_data$host=as.factor(train_data$host)
train_data$ph_scale=as.factor(train_data$ph_scale)
rownames(train_data)=train_data$laccase
train_data$laccase=NULL

# Create a task
train_task <- mlr3::TaskRegr$new("laccases", backend = train_data, target = "ph_optima")
# Uncomment use a smaller feature list
# train_task2 <- mlr3::TaskClassif$new(id = "laccases", backend = train_data[,1:15], target = "ph_scale")

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
learner <- lrn("regr.rpart")

# Define resampling for inner CV, with 5 iterations 
resampling_inner <- rsmp("cv", folds = 5)
# Define resampling for outer CV, with 3 iterations
resampling_outer <- rsmp("cv", folds = 3)

# Define a tuner
tuner <- TunerGridSearch$new()

# manually run nested CV outer loop
outer_results <- list()

# Outer loop
for (outer_fold in seq_len(resampling_outer$iters)) {
    
    # Split data for outer CV
    outer_resample <- resampling_outer$instantiate(train_task)
    
    # Inner CV for hyperparameter tuning
    tuning_result <- tune(tuner, task = train_task, learner = learner,
                          resampling = resampling_inner, measure = msr("regr.mae"),
                          search_space = param_set, term_evals = 50)
    
    # Best hyperparameters
    best_params <- tuning_result$result_x_domain
    
    # Train model using best hyperparameters on entire training set
    learner$param_set$values <- best_params
    learner$train(train_task, row_ids = outer_resample$train_set(outer_fold))
    
    # Validate model on the validation set
    predictions <- learner$predict(train_task, row_ids = outer_resample$test_set(outer_fold))
    performance <- msr("regr.mae")$score(predictions)
    
    outer_results[[outer_fold]] <- list(best_params = best_params, performance = performance)
}

# Print the results
outer_results

#reset the learner
learner <- lrn("regr.rpart")

# Set the optimal values from inner CV to the learner, based on the outer_results
learner$param_set$values = list(cp = xxx, minsplit = xxx, minbucket = xxx, maxdepth = xxx)

# Now, you can train the model on your training task or evaluate it using resampling strategies like CV
# Example: Training the learner on the entire training task
learner$train(train_task)

# predict your dataset e.g. <pred_data2>
task <- TaskClassif$new(id = "pred_data2", backend = pred_data2, target = "ph_scale")
predictions_rpart_tune <- learner$predict(task)


