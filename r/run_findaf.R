library(randomForest)

# Load FIND-AF model
af <- readRDS("./r/findaf.RDS")

# New data to use for model prediction
new_df

# Get predicted AF risk from model, given inputs
af_pred <- predict(af, new_df)