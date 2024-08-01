library(tidyverse)
library(lmerTest)
library(lme4)
library(Hmisc)
library(ggplot2)

data = read_csv("twostep-contour/data/human/v3.7/FullTrial.csv")
data1 = read_csv("twostep-contour/data/human/v3.7/trial1.csv")
data2 = read_csv("twostep-contour/data/human/v3.7/trial2.csv")
data_filtered <- subset(data, accuracy == 1)
# Now you can perform your analysis on data_filtered



model1 = lmer(
  data = data ,
  RT_first_visit ~ 1 + difficulty + difficulty_2 + (1|wid)
)

summary(model1)
anova(model1)

model2 = lmer(
  data = data,
  RT_second_visit ~ 1 + + difficulty +difficulty_2 + (1 | wid)
)

summary(model2)
anova(model2)


model = lmer(
  data = data,
  RT_first_visit~ 1 + difficulty* difficulty_2  + (1 + difficulty * difficulty_2 | wid)
)

summary(model)

model2 = lmer(
  data = data_filtered,
  RT_second_visit~ 1 + difficulty* difficulty_2  + (1 + difficulty* difficulty_2 | wid)
)

summary(model2)

# Assuming data1 is your data frame
# Fit the linear model
model <- lm(RT_second_visit ~ difficulty + difficulty2, data = data)

# Display the summary of the model to see coefficients and statistics
summary(model)





# Assuming 'data1' is your data frame
data_accuracy_1 <- subset(data, accuracy == 1)
data_accuracy_0 <- subset(data, accuracy == 0)
# Compute the correlation matrix for data where accuracy = 1
cor_matrix_accuracy_1 <- cor(data_accuracy_1[, c("RT_first_visit", "RT_second_visit", "difficulty", "difficulty_2")], use = "complete.obs")
cor_pvals_accuracy_1 <- rcorr(as.matrix(data_accuracy_1[, c("RT_first_visit", "RT_second_visit", "difficulty", "difficulty_2")]))


# Function to annotate correlation matrix
annotate_cor_matrix <- function(cor_matrix, p_matrix, sig_level = 0.05) {
  significance <- ifelse(p_matrix < sig_level, "*", " ")
  annotated_matrix <- paste0(sprintf("%.2f", cor_matrix), significance)
  return(annotated_matrix)
}

# Print the correlation matrices with marked significance
print("Correlation matrix when accuracy = 1 (Significance marked):")
print(cor_pvals_accuracy_1$r)
print(cor_pvals_accuracy_1$P < 0.05)  # True/False matrix indicating significance at p < 0.05

print("Correlation matrix when accuracy = 0 (Significance marked):")
print(cor_pvals_accuracy_0$r)
print(cor_pvals_accuracy_0$P < 0.05) 



