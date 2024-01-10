# plot learning curves
set_sizes <- seq(0.1, 1, by = 0.1)  # Training set sizes
train_rmse <- numeric(length(set_sizes))
val_rmse <- numeric(length(set_sizes))

for (i in seq_along(set_sizes)) {
    size <- set_sizes[i]
    
    # Sample a subset of the training data
    train_indices <- sample(seq_len(train_task$nrow), size * train_task$nrow)
    train_subset <- train_task$clone()$filter(train_indices)
    
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
    labs(title = "Learning Curves", x = "Training Set Size", y = "RMSE")
