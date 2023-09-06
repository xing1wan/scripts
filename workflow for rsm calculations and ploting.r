# raw_data looks like this:
#  methanol.perc    ph   day activity.ukat.per.l
# 1           0.5  6        1             0.00353
# 2           0.5  6.25     1             0.00268
# 3           0.5  6.5      1             0.00345
# 4           0.5  6.75     1             0.00480
# 5           0.5  7        1             0.00219
# 6           0.5  6        2             0.0649 

library(rsm)
library(viridis)

# calculate the results
result <- rsm(formula = activity.ukat.per.l ~ SO(methanol.perc, ph, day), data = raw_data)
	
# plots all the combinations
par(mfrow=c(2,3))
contour(result, ~ph+day, at = list(methanol.perc=0.5), image=TRUE, img.col = turbo(600))
contour(result, ~ph+day, at = list(methanol.perc=1), image=TRUE, img.col = turbo(600))
contour(result, ~ph+day, at = list(methanol.perc=1.5), image=TRUE, img.col = turbo(600))
contour(result, ~ph+day, at = list(methanol.perc=2), image=TRUE, img.col = turbo(600))
contour(result, ~ph+day, at = list(methanol.perc=2.5), image=TRUE, img.col = turbo(600))
contour(result, ~ph+day, at = list(methanol.perc=3), image=TRUE, img.col = turbo(600))
title("pH vs Day", line = -2, outer = TRUE)
dev.off()
# select the day with best production level
contour(result, ~methanol.perc+ph, at = list(day=5), image=TRUE, main="methanol percentage vs pH", img.col = turbo(600))

# create a new data frame with the levels of the factors where you want to make predictions
new_data <- expand.grid(methanol.perc = c(0.1, 0.5, 1, 2)), ph = 5.5, day = seq(1,13, by = 4))

# combine the predictions with the original data frame for easier interpretation
predictions <- predict(result, newdata = new_data)

# Find the methanol.perc level with the highest predicted response
opt_row <- which.max(new_data$predicted_activity)
new_data[opt_row,]