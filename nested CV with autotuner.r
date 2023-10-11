### nested Cross-validation (resampling)
# Load required libraries
library(mlr3)
library(mlr3tuning)
library(mlr3measures)
library(readr)

# Load your dataset for training, including secondary structures, and amino acid composition/grouping
train_data <- read_csv("Z:/Drive_R/R/ML/data/train_data2.csv")

# Clean training dataset
train_data <- as.data.frame(train_data)
train_data$host <- as.factor(train_data$host)
levels(train_data$host) <- c(levels(train_data$host), "other")
rownames(train_data) <-train_data$laccase
train_data$laccase <-NULL

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
#learner <- lrn("regr.lightgbm")

# Define resampling for inner CV, with 5 iterations 
resampling_inner <- rsmp("cv", folds = 5)
# Define resampling for outer CV, with 3 iterations
resampling_outer <- rsmp("cv", folds = 3)

# Define a tuner, using default setting works with most of the cases
tuner <- tnr("grid_search")
#tuner <- tnr("grid_search", resolution = 5, batch_size=10)


# Set up the AutoTuner, which will be used in the outer loop
at <- AutoTuner$new(learner = learner, resampling = resampling_inner, measure = msr("regr.rmse"), search_space = param_set, terminator = trm("none"), tuner = tuner, store_tuning_instance = TRUE)

# Resample using the AutoTuner and outer resampling
rr <- resample(train_task, at, resampling_outer, store_models = TRUE)

# Check the results
extract_inner_tuning_results(rr)[,1:6]
# extract_inner_tuning_results(rr)[,1:6]
# 	  iteration    cp minsplit minbucket maxdepth regr.rmse
# 1:         1 0.056       10         3        8  1.311309
# 2:         2 0.045       35         5        1  2.019413
# 3:         3 0.078       45        13        7  2.482061

# Set the optimal values from inner CV to the learner, based on the outer tuning, replace x with the best para_set 1 or 2 or 3, from the previous result, #1 is the best (lowest rmse value)
learner$param_set$values <- extract_inner_tuning_results(rr)$x_domain[[1]]

#### If any parameter still needs to be narrow-tuned
param_set <- ParamSet$new(list(
  ParamDbl$new("cp", lower = 0.05, upper = 0.06),
  ParamInt$new("minsplit", lower = 8, upper = 12),
  ParamInt$new("minbucket", lower = 1, upper = 10),
  ParamInt$new("maxdepth", lower = 7, upper = 9)
))

at <- AutoTuner$new(learner = learner, resampling = resampling_inner, measure = msr("regr.rmse"), search_space = param_set, terminator = trm("none"), tuner = tuner, store_tuning_instance = TRUE)

rr <- resample(train_task, at, resampling_outer, store_models = TRUE)
#### end of narrow tuning


# Now, you can train the model on your training task or evaluate it using resampling strategies like CV
# Example: Training the learner on the entire training task
learner$train(train_task)

#Generate Predictions
predictions <- learner$predict(train_task)
#### visualising the learner with plots####
# Given data
row_ids <- predictions$row_ids
actual_values <- train_data[predictions$row_ids,]$ph_optima
predicted_values <- predictions$response

# Create the base plot
p <- ggplot() +
  geom_point(aes(row_ids, actual_values), color="blue", size=3) +
  geom_point(aes(row_ids, predicted_values), color="red", size=3) +
  labs(x="Row IDs", y="pH") +
  theme_minimal()
 
# Add the polynomial curve
poly_fit <- lm(predicted_values ~ poly(row_ids, 2))
poly_df <- data.frame(row_ids = seq(min(row_ids), max(row_ids), length.out=100))
poly_df$predicted_values <- predict(poly_fit, newdata=data.frame(row_ids=poly_df$row_ids))

p + geom_line(data=poly_df, aes(row_ids, predicted_values), color="red", linetype=2) + ggtitle("tuned")
#### end of visualisation####

# predict your dataset e.g. <test_data>
test_data <- read_csv("Z:/Drive_R/R/ML/data/test_data.csv")
# Clean testing dataset
test_data <- as.data.frame(test_data)
test_data$host <- as.character(test_data$host)
test_data$host <- ifelse(test_data$host %in% levels(train_data2$host), test_data$host, "other")
test_data$host <- as.factor(test_data$host)
rownames(train_data) <-train_data$laccase
train_data$laccase <-NULL
# set the learner with the best parameters
learner2 <- lrn("regr.rpart", cp = 0.056, minsplit = 10, maxdepth = 8, minbucket = 3)
learner2$train(train_task)
task <- TaskRegr$new(id = "laccases", backend = pred_data, target = "ph_optima")
predictions_rpart_tune <- learner2$predict(task)

# Select the alkaline laccases
selected_rows <- which(predictions_rpart_tune$response >= 7)

