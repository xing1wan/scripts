library(mlr3)
library(readr)
library(janitor)

# Use small letters and _ in the first line of your dataset to avoid annoying formatting later

training_dataset <- read_csv("<your path>/training dataset.csv", col_types = cols(primary_seq = col_skip(), ml_status = col_skip()))
laccases_data <- as.data.frame(training_dataset)
laccases_data <- laccases_data %>% clean_names()
View(laccases_data)
rownames(laccases_data)=laccases_data$laccase
laccases_data$laccase=NULL
laccases_data[] <- lapply(laccases_data, function(x) if(is.character(x)) as.factor(x) else x)
# Some manual changing of colnames, if necessary
colnames(laccases_data)
colnames(laccases_data)[29]="pi"

train_data = laccases_data[1:55,]

#####The following codes are alternatives, or testing
# To test training dataset with 80-20 split, first make your train task
train_task <- mlr3::TaskClassif$new("laccases", backend = train_data, target = "ph_scale")
# Create a resampling instance with 80-20 train-test split
resampling <- mlr3::rsmp("holdout", ratio = 0.8)
# Instantiate the resampling
resampling_instance <- resampling$instantiate(train_task)
# Instantiate a learner
learner <- mlr3::lrn("classif.rpart")
# Train the model, it will take some time on R maybe hours, depending on the complexity of the dataset
learner$train(train_task, row_ids = resampling_instance$train_set(1))
predictions <- learner$predict(train_task, row_ids = resampling_instance$test_set(1))
# Compute the performance
performance <- predictions$score(msr("classif.acc"))
performance

# To predict unknown dataset
# Add the other as part of the host list, if the unknown host is not in the levels
train_data$host <- factor(train_data$host, levels = c(levels(train_data$host), "other"))
train_task <- mlr3::TaskClassif$new("laccases", backend = train_data, target = "ph_scale")
learner$train(train_task)

# Get your prediction dataset
pred_data=laccases_data[56:2021,]
# Check if each host in pred_data is in the levels of train_data$host
# If not, assign it the new level "other"
pred_data$host <- as.character(pred_data$host)
pred_data$host <- ifelse(pred_data$host %in% levels(train_data$host), pred_data$host, "other")
pred_data$host <- as.factor(pred_data$host)
#Fix the mismatching predictors error: Type of predictors in new data do not match that of the training data, if it occurs
fix_pred_data2 <- rbind(train_data2[1,], pred_data2)
pred_data2 <- fix_pred_data2[-1,]

# Now, predict new data
predictions <- learner$predict_newdata(pred_data)
# check which laccases are predicted to be alkalinic 
rownames(pred_data)[grep("alkaline", predictions$response)]

## NOTES, unhashtag commands before use
## To avoid annoying format setting for pred_data (e.g. dicsque here)
#combine_data=rbind(laccases_data, dicsque)
## Take the pred_data lines from the combined data frame e.g. 58th – 65th rows
##pred_data=combine_data[58:65,]


alka_index <- grep("alkaline", predictions_rpart$response)
#extract jgi names of the predicted alkaline laccase
rownames(pred_data2)[alka_index]
