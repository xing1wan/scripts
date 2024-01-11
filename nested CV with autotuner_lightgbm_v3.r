### nested Cross-validation (resampling)
# Load required libraries
library(mlr3)
library(mlr3tuning)
library(mlr3measures)
library(readr)
library(dplyr)
library(caret)

#######################
#### Data cleaning ####
#######################

# Load your dataset for training, including secondary structures, and amino acid composition/grouping
combined_data <- read_csv("Z:/Drive_R/R/ML/data/combined_data2.csv")
combined_data <- as.data.frame(combined_data)
rownames(combined_data) <- combined_data$laccase
# Get train_data set and clean it
train_data <- combined_data %>% filter(ml_status == "train")
train_data[,1:2]=NULL
train_data$host <- as.factor(train_data$host)
levels(train_data$host) <- c(levels(train_data$host), "other")
# one-hot encode factor features
one_hot <- model.matrix(~ host - 1, data = train_data)
one_hot2 <- model.matrix(~ env - 1, data = train_data)
train_data2 <- cbind(one_hot, one_hot2, train_data)
colnames(train_data2) <- gsub("-", "_", tolower(colnames(train_data2)))

##################################################################
####   define training, tuning, and validation sets and tasks ####
##################################################################

# To test untuned model, train the untuned model with shuffled dataset
set.seed(123)
splitIndex <- createDataPartition(train_data2$ph_optima, p = 0.8, list = FALSE)
# manually check if in validation task, there are data with high ph_optima 
train_set <- train_data2[splitIndex, ]
train_task <- mlr3::TaskRegr$new("laccases", backend = train_set, target = "ph_optima")
learner$train(train_task)
# generate shuffled train_set for training the tuned model
rdm_set <- train_set[sample(nrow(train_set)), ]
rdm_task <- mlr3::TaskRegr$new("laccases", backend = rdm_set, target = "ph_optima")

#Generate Predictions for visualisation
validation_set <- train_data2[-splitIndex,]
# validation_set <- validation_set[order(validation_set$ph_optima),]
validation_task <- mlr3::TaskRegr$new("laccases", backend = validation_set, target = "ph_optima")
predictions <- learner$predict(validation_task)



###########################################
#### visualising the learner with plots####
###########################################

# #Generate Predictions for visualisation
# train_data_order <- train_data[order(train_data$ph_optima),]
# train_task <- mlr3::TaskRegr$new("laccases", backend = train_data_order, target = "ph_optima")
# predictions <- learner$predict(train_task)
# # Given data
# row_ids <- predictions$row_ids
# actual_values <- predictions$truth
# predicted_values <- predictions$response

# # Create the base plot
# p <- ggplot() +
  # geom_point(aes(row_ids, actual_values), color="blue", size=3) +
  # geom_point(aes(row_ids, predicted_values), color="red", size=3) +
  # labs(x="laccase IDs", y="pH") +
  # theme_minimal()
  
# # Add the vertical lines
# p <- p + geom_segment(aes(x=row_ids, y=actual_values, xend=row_ids, yend=predicted_values), linetype="dotted", color="black")
 
# # Add the polynomial curve
# poly_fit <- lm(predicted_values ~ poly(row_ids, 2))
# poly_df <- data.frame(row_ids = seq(min(row_ids), max(row_ids), length.out=100))
# poly_df$predicted_values <- predict(poly_fit, newdata=data.frame(row_ids=poly_df$row_ids))

# p + geom_line(data=poly_df, aes(row_ids, predicted_values), color="red", linetype=2) + ggtitle("untuned lightgbm")
# #### end of visualisation####



################################
####      Broad tuning      ####
################################

# Uncomment use a smaller feature list
# train_task2 <- mlr3::TaskClassif$new(id = "laccases", backend = train_data[,1:15], target = "ph_scale")

# Define a search space for hyperparameters
# tuning also other important hyperparameters for the learner
param_set <- ParamSet$new(list(
  ParamDbl$new("learning_rate", lower = 0.01, upper = 0.3),
  ParamInt$new("num_leaves", lower = 15, upper = 60),
  ParamInt$new("min_data_in_leaf", lower = 10, upper = 100),
  ParamInt$new("max_depth", lower = 4, upper = 15)
))

# Create a learner
learner <- lrn("regr.lightgbm")

# Define resampling for inner CV, with 5 iterations 
resampling_inner <- rsmp("cv", folds = 5)
# Define resampling for outer CV, with 3 iterations
resampling_outer <- rsmp("cv", folds = 3)

# Define a tuner, using default setting works with most of the cases
tuner <- tnr("grid_search", batch_size=20)
# tuner2 is used for narrow tuning
#tuner2 <- tnr("grid_search", resolution = 10, batch_size=20)


# Set up the AutoTuner, which will be used in the outer loop
# repeat from tmp to test with different measures, such as regr.mse and regr.mae
at <- AutoTuner$new(learner = learner, resampling = resampling_inner, measure = msr("regr.rmse"), search_space = param_set, terminator = trm("evals", n_evals = 100), tuner = tuner, store_tuning_instance = TRUE)

# Resample using the AutoTuner and outer resampling
rr <- resample(train_task, at, resampling_outer, store_models = TRUE)

# Check the results
extract_inner_tuning_results(rr)[,1:6]
# extract_inner_tuning_results(rr)[,1:6]
   # iteration learning_rate num_leaves min_data_in_leaf max_depth regr.rmse
# 1:         1     0.0100000         30               10        10  2.037283
# 2:         2     0.1388889         25               10         4  1.520920
# 3:         3     0.2033333         30               10         8  2.033054
lgbm_broad <- as.data.frame(extract_inner_tuning_archives(rr))

# Set the optimal values from inner CV to the learner, based on the outer tuning, replace x with the best para_set 1 or 2 or 3, from the previous result, #2 is the best (lowest rmse value)
learner$param_set$values <- extract_inner_tuning_results(rr)$learner_param_vals[[3]]
# Also restore the default settings for untuned parameters
#learner$param_set$values$num_threads=1
#learner$param_set$values$verbose=-1
#learner$param_set$values$objective="regression"
#learner$param_set$values$convert_categorical=TRUE

####-----------------------------####
####        model evaluation     ####
####-----------------------------####

# after tuning, you can visualise to see how well the model perform using the tuned parameters
# Now, you can train the model on your training task or evaluate it
# Example: Training the learner on the entire training task, shuffled
learner$train(rdm_task)
# generate predictions 
train_prediction <- learner$predict(train_task)
train_performance <- train_prediction$score(msr("regr.rmse"))
validation_prediction <- learner$predict(validation_task)
validation_performance <- validation_prediction$score(msr("regr.rmse"))
print(paste("Training RMSE:", train_performance))
print(paste("Validation RMSE:", validation_performance))

####---------------------------------####
#### visualisation with scatter plot ####
####---------------------------------####

actual_values <- train_prediction$truth
predicted_values <- train_prediction$response
actual_values2 <- validation_prediction$truth
predicted_values2 <- validation_prediction$response
# scatter plot the predicted and actual pHs
p <- ggplot() +
    geom_point(aes(x = actual_values, y = predicted_values), color = "#4DBBD5FF", size = 3) +
    geom_point(aes(x = actual_values2, y = predicted_values2), color = "#E64B35FF", size = 3) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black") +
    labs(x = "Actual pH", y = "Predicted pH", title = "Actual vs Predicted pH for Laccases (broad-tuned lightgbm)") +
    theme_minimal() +
    theme(
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        axis.text = element_text(color = "black"),
        panel.border = element_blank(),
        axis.line = element_line(color = "black"),
		axis.ticks = element_line(color = "black"), # Add ticks
		axis.ticks.length = unit(2, "mm") # Set tick length
    ) +
    scale_x_continuous(breaks = seq(0, 14, by = 2), limits = c(0, 14), expand = c(0, 0)) +
    scale_y_continuous(breaks = seq(0, 14, by = 2), limits = c(0, 14), expand = c(0, 0))
p
# #### visualising the learner with plots####
# # Given data
# row_ids <- predictions$row_ids
# actual_values <- predictions$truth
# predicted_values <- predictions$response

# # Create the base plot
# p <- ggplot() +
  # geom_point(aes(row_ids, actual_values), color="blue", size=3) +
  # geom_point(aes(row_ids, predicted_values), color="red", size=3) +
  # labs(x="laccase IDs", y="pH") +
  # theme_minimal()
  
# # Add the vertical lines
# p <- p + geom_segment(aes(x=row_ids, y=actual_values, xend=row_ids, yend=predicted_values), linetype="dotted", color="black")
 
# # Add the polynomial curve
# poly_fit <- lm(predicted_values ~ poly(row_ids, 2))
# poly_df <- data.frame(row_ids = seq(min(row_ids), max(row_ids), length.out=100))
# poly_df$predicted_values <- predict(poly_fit, newdata=data.frame(row_ids=poly_df$row_ids))

# p + geom_line(data=poly_df, aes(row_ids, predicted_values), color="red", linetype=2) + ggtitle("broad tuned")
# #### end of visualisation####


#############################
####    Narrow tuning    ####
#############################

# repeat broad tuning with different measures, defined in AutoTuner

#### If any parameter still needs to be narrow-tuned
param_set <- ParamSet$new(list(
    ParamDbl$new("learning_rate", lower = 0.04, upper = 0.05),
    ParamInt$new("num_leaves", lower = 30, upper = 50),
    ParamInt$new("min_data_in_leaf", lower = 1, upper = 20),
    ParamInt$new("max_depth", lower = 13, upper = 15)
))
train_task <- mlr3::TaskRegr$new("laccases", backend = train_data, target = "ph_optima")
at <- AutoTuner$new(learner = learner, resampling = resampling_inner, measure = msr("regr.rmse"), search_space = param_set, terminator = trm("evals", n_evals = 50), tuner = tuner2, store_tuning_instance = TRUE)
rr <- resample(train_task, at, resampling_outer, store_models = TRUE)
#### end of narrow tuning

#extract_inner_tuning_results(rr)[,1:6]
   # iteration learning_rate num_leaves min_data_in_leaf max_depth regr.rmse
# 1:         1    0.04111111         30                3        14  1.782143
# 2:         2    0.04888889         32                9        15  1.935839
# 3:         3    0.04444444         46                9        13  1.419309
lgbm_narrow <- as.data.frame(extract_inner_tuning_archives(rr))
# Now, you can train the model on your training task or evaluate it using resampling strategies like CV
learner$param_set$values <- extract_inner_tuning_results(rr)$learner_param_vals[[3]]
# Also restore the default settings for untuned parameters
#learner$param_set$values$num_threads=1
#learner$param_set$values$verbose=-1
#learner$param_set$values$objective="regression"
#learner$param_set$values$convert_categorical=TRUE
# Example: Training the learner on the entire training task
learner$train(rdm_task)

#Generate Predictions for visualisation
train_prediction <- learner$predict(train_task)
train_performance <- train_prediction$score(msr("regr.rmse"))
validation_prediction <- learner$predict(validation_task)
validation_performance <- validation_prediction$score(msr("regr.rmse"))
print(paste("Training RMSE:", train_performance))
print(paste("Validation RMSE:", validation_performance))

# #### visualising the learner with plots####
# # Given data
# row_ids <- train_prediction$row_ids
# actual_values <- train_prediction$truth
# predicted_values <- train_prediction$response

# # Create the base plot
# p <- ggplot() +
  # geom_point(aes(row_ids, actual_values), color="blue", size=3) +
  # geom_point(aes(row_ids, predicted_values), color="red", size=3) +
  # labs(x="laccase IDs", y="pH") +
  # theme_minimal()
  
# # Add the vertical lines
# p <- p + geom_segment(aes(x=row_ids, y=actual_values, xend=row_ids, yend=predicted_values), linetype="dotted", color="black")
 
# # Add the polynomial curve
# poly_fit <- lm(predicted_values ~ poly(row_ids, 2))
# poly_df <- data.frame(row_ids = seq(min(row_ids), max(row_ids), length.out=100))
# poly_df$predicted_values <- predict(poly_fit, newdata=data.frame(row_ids=poly_df$row_ids))

# p + geom_line(data=poly_df, aes(row_ids, predicted_values), color="red", linetype=2) + ggtitle("narrow tuned")
# #### end of visualisation####

####---------------------------------####
#### visualisation with scatter plot ####
####---------------------------------####

actual_values <- train_prediction$truth
predicted_values <- train_prediction$response
actual_values2 <- validation_prediction$truth
predicted_values2 <- validation_prediction$response
# scatter plot the predicted and actual pHs
p <- ggplot() +
    geom_point(aes(x = actual_values, y = predicted_values), color = "#4DBBD5FF", size = 3) +
    geom_point(aes(x = actual_values2, y = predicted_values2), color = "#E64B35FF", size = 3) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black") +
    labs(x = "Actual pH", y = "Predicted pH", title = "Actual vs Predicted pH for Laccases (narrow-tuned lightgbm)") +
    theme_minimal() +
    theme(
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        axis.text = element_text(color = "black"),
        panel.border = element_blank(),
        axis.line = element_line(color = "black"),
		axis.ticks = element_line(color = "black"), # Add ticks
		axis.ticks.length = unit(2, "mm") # Set tick length
    ) +
    scale_x_continuous(breaks = seq(0, 14, by = 2), limits = c(0, 14), expand = c(0, 0)) +
    scale_y_continuous(breaks = seq(0, 14, by = 2), limits = c(0, 14), expand = c(0, 0))
p

#####################################
####      model application      ####
#####################################

# predict your dataset e.g. <test_data>
# Get test_data set and clean it
test_data <- combined_data %>% filter(ml_status == "test")
test_data[,1:2]=NULL
test_data$host <- ifelse(test_data$host %in% levels(train_data$host), test_data$host, "other")
test_data$host <- as.factor(test_data$host)
# set the learner with the best parameters, as after narrow tuning the rmse of #2 is not as good as that from the broad tuning
learner2 <- lrn("regr.lightgbm")
learner2$param_set$values$num_threads=1
learner2$param_set$values$verbose=-1
learner2$param_set$values$objective="regression"
learner2$param_set$values$convert_categorical=TRUE
learner2$param_set$values$learning_rate=0.153333
learner2$param_set$values$num_leaves=28
learner2$param_set$values$min_data_in_leaf=12
learner2$param_set$values$max_depth=6

# To avoid problem caused by level difference, reset the levels for host, possibly done in the beginning 
aligned_data <- rbind(train_data,test_data)
train_data_aligned <- aligned_data[1:nrow(train_data),]
test_data_aligned <- aligned_data[-(1:nrow(train_data)),]

# Redefine the tasks
tmp <- train_data_aligned[sample(nrow(train_data_aligned)), ]
train_task <- mlr3::TaskRegr$new("laccases", backend = tmp, target = "ph_optima")
learner2$train(train_task)
# Predict your test_data set
task <- TaskRegr$new(id = "laccases", backend = test_data_aligned, target = "ph_optima")
predictions_lightgbm_tune <- learner2$predict(task)
# Select the alkaline laccases
selected_rows2 <- which(predictions_lightgbm_tune$response >= 7)

#############################
#### data interpretation ####
#############################

# check how well is your tuned model perform, using feature importances and learning curves
# would be good to do after both broad and narrow tuning stages
library(iml)

credit_x <- rdm_task$data(cols = rdm_task$feature_names)
credit_y <- rdm_task$data(cols = rdm_task$target_names)
predictor <- Predictor$new(learner, data = credit_x, y = credit_y)
importance <- FeatureImp$new(predictor, loss = "rmse", n.repetitions = 100)
importance$plot()



# plot learning curves
set_sizes <- seq(0.1, 1, by = 0.1)  # Training set sizes
train_rmse <- numeric(length(set_sizes))
val_rmse <- numeric(length(set_sizes))

for (i in seq_along(set_sizes)) {
    size <- set_sizes[i]
    
    # Sample a subset of the training data
    train_indices <- sample(seq_len(rdm_task$nrow), size * rdm_task$nrow)
    train_subset <- rdm_task$clone()$filter(train_indices)
    
    # Train the model
    learner$train(train_subset)
    
    # Evaluate on training subset
    train_prediction <- learner$predict(train_subset)
    train_rmse[i] <- train_prediction$score(msr("regr.rmse"))
    
    # Evaluate on validation set
    val_prediction <- learner$predict(validation_task)  # Assuming validation_task is defined
    val_rmse[i] <- val_prediction$score(msr("regr.rmse"))
}

# Create a data frame for plotting
learning_curve_data <- data.frame(
    Size = rep(set_sizes, 2),
    RMSE = c(train_rmse, val_rmse),
    Set = rep(c("Training", "Validation"), each = length(set_sizes))
)

# Plot the learning curves
ggplot(learning_curve_data, aes(x = Size, y = RMSE, color = Set)) +
    geom_line() +
    labs(title = "Learning curves of narrow-tuned lightgbm", x = "Training Set Size", y = "RMSE")
