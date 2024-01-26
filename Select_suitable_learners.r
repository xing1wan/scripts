# Initialize an empty data frame to store plot data
plot_data <- data.frame(
  actual_values = numeric(),
  predicted_values = numeric(),
  dataset_type = character(),
  learner_id = character(),
  stringsAsFactors = FALSE
)

results <- data.frame(
    learner_id = character(),
    train_performance = numeric(),
    validation_performance = numeric(),
    stringsAsFactors = FALSE
)

for(i in 1:length(all_regr_learners)) {
    learner <- lrn(all_regr_learners[i])
    print(learner$id)
    # Error handling using tryCatch
    error_occurred <- tryCatch({
        learner$train(rdm_task)
        FALSE  # No error occurred
    }, error = function(e) {
        message("Error training learner: ", learner$id, "; Error: ", e$message)
        TRUE  # Error occurred
    })
    # Skip the rest of the loop if an error occurred
    if (error_occurred) {
        next
    }
    # Generate train and validation predictions
    train_prediction <- learner$predict(train_task)
    validation_prediction <- learner$predict(validation_task)
    # Calculate performances
    train_performance <- train_prediction$score(msr("regr.rmse"))
    validation_performance <- validation_prediction$score(msr("regr.rmse"))
    # Store the results
    results <- rbind(results, data.frame(
        learner_id = learner$id,
        train_performance = train_performance,
        validation_performance = validation_performance
    ))
    ####---------------------------------####
    #### visualisation with scatter plot ####
    ####---------------------------------####
    actual_values <- train_prediction$truth
    predicted_values <- train_prediction$response
    actual_values2 <- validation_prediction$truth
    predicted_values2 <- validation_prediction$response
    temp_data <- rbind(
      data.frame(actual_values, predicted_values, dataset_type = 'Train', learner_id = learner$id),
      data.frame(actual_values = actual_values2, predicted_values = predicted_values2, dataset_type = 'Validation', learner_id = learner$id)
    )

    plot_data <- rbind(plot_data, temp_data)
}
   
p <- ggplot(plot_data, aes(x = actual_values, y = predicted_values, color = dataset_type, shape = learner_id)) +
    geom_point(size = 3) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black") +
    labs(x = "Actual pH", y = "Predicted pH", title = "Actual vs Predicted pH for Laccases with Different Learners") +
    theme_minimal() +
    theme(
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        axis.text = element_text(color = "black"),
        panel.border = element_blank(),
        axis.line = element_line(color = "black"),
        axis.ticks = element_line(color = "black"),
        axis.ticks.length = unit(2, "mm")
    ) +
    scale_x_continuous(breaks = seq(0, 14, by = 2), limits = c(0, 14), expand = c(0, 0)) +
    scale_y_continuous(breaks = seq(0, 14, by = 2), limits = c(0, 14), expand = c(0, 0)) +
    scale_color_manual(values = c("#4DBBD5FF", "#E64B35FF")) 
    

# Display the plot
print(p)
# Print the results table
View(results)

# Select the learners to continue to tuning
max_validation_performance = 1.3   # Example threshold for maximum validation performance
max_diff_threshold = 0.3           # Example threshold for maximum allowed difference between training and validation

# Filter learners
selected_learners <- results %>%
    filter(validation_performance < max_validation_performance & 
               abs(train_performance - validation_performance) < max_diff_threshold)

# View selected learners
print(selected_learners)
# selected_learners$learner_id
#  [1] "regr.bart"         "regr.cubist"       "regr.earth"        "regr.gbm"          "regr.glmboost"     "regr.kknn"         "regr.lightgbm"     "regr.randomForest"
#  [9] "regr.ranger"       "regr.rfsrc"        "regr.rpf"    