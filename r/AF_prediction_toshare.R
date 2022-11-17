### R code for FIND-AF prediciton model development#######################################
### created by Jianhua Wu, Oct 2022         #############################################
rm(list = ls())
library(tidyverse)
library(lubridate)
#impute missings
library(imputeMissings)
library("ROCR")
library(randomForest)
library(caret)
library(MLeval)
library(pROC)
library(OptimalCutpoints)
library(doMC)
library(nricens)
registerDoMC(cores=8)

MySummary  <- function(data, lev = NULL, model = NULL){
  a1 <- defaultSummary(data, lev, model)
  b1 <- twoClassSummary(data, lev, model)
  c1 <- prSummary(data, lev, model)
  out <- c(a1, b1, c1)
  out}

cprddir <- "~"
mydir <- "~"

codedir <- paste0(mydir,"codelist/")

source(paste0(mydir,"/aux_fun.R"))

pat <- read_tsv(paste0(mydir,"final.patient.cohort.txt"))


pat$af <- ifelse(is.na(pat$afday) | pat$afday >180, 0,1)

pat$gender <- car::recode(pat$gender,"1 = 'Female';2 = 'Male'")
pat$af <- car::recode(pat$af,"1 = 'Yes';0 = 'No'")

### calculate the chasvasc and chest score.
pat$chads <- chadsfun(data = pat)
pat$chest <- chestfun(data = pat)

vars <- c("patid", "chest", "chads", "af","age", "gender","ethnic",colnames(pat)[23:94])


pat1 <- pat[!is.na(pat$imd) & pat$age >=30,vars]

#prepare numerics and factors
factors<- c("gender","ethnic","af")
for (i in factors) {
  pat1[i]<-lapply(pat1[i], as.factor)
}
cols<-colnames(pat1)
numerics<-setdiff(cols,c("patid",factors))

for (i in numerics) {
  pat1[i]<-lapply(pat1[i], as.numeric)
}


##########split data by 80/20###############################
colnames(pat1) <- c("patid", "chest", "chads", "af","age","gender","ethnic",paste0("var",1:72))

data = sort(sample(nrow(pat1), nrow(pat1)*.8))
train <- pat1[data,colnames(pat1)[c(-1,-2,-3)]]
test <- pat1[-data,colnames(pat1)[c(-1,-2,-3)]]



#### model 1: logistic model on training data
#### on selected variables 

set.seed(832)

trControl <- trainControl(method = "repeatedcv",
                          number = 5,
                          repeats = 10,
                          classProbs = TRUE,
                          summaryFunction = MySummary,
                          savePredictions = T)

mlrmod <- caret::train(af ~.,
                       data = train,
                       method = "glm",
                       metric = "ROC",
                       trControl = trControl)


#### model performance
testmlrmod<-predict(mlrmod,test, type = "response")
testmlrpred <- prediction(testmlrmod, test$af)   
testmlrmod_auc = performance(testmlrpred, "auc")
testmlrmod_perf80 <- performance(testmlrpred,"tpr","fpr")

#####predict on test
df <- structure(list(value = testmlrmod, type = test$af),.Names = c("value","type"),row.names = c(NA, -41623L),class = "data.frame")
rocobj <- plot.roc(df$type, df$value, percent = TRUE, main="ROC", col="#1c61b6", add=FALSE)

optimal.cutpoint.Youden <- optimal.cutpoints(X = "value", status = "type", tag.healthy = "No", methods = "Youden", 
                                             data = df, pop.prev = NULL,
                                             control = control.cutpoints(), ci.fit = FALSE, conf.level = 0.95, trace = FALSE)
summary(optimal.cutpoint.Youden)
plot(optimal.cutpoint.Youden)

#### calibriation plot
testcal <- test
testcal$y <- 0
testcal$y[testcal$af == "Yes"]<- 1
testcal <- data.frame(y = testcal$y,pred = predict(modmlr,testcal, type = "response"))

calibration_plot(data = testcal, obs = "y", pred = "pred", title = "Calibration plot for MLR")

### chads model prediction
chads <- train
chads$chads <- pat2$chads[data]
chadstest <- test
chadstest$chads <- pat2$chads[-data]

chadsmod <- glm(as.formula(paste0("af ~ ","chads")),data=chads, family=binomial)
chadsmod1<-predict(chadsmod,chadstest, type = "response")

chadscal <- data.frame(y = as.numeric(car::recode(chadstest$af,"'Yes' = 1;'No' = 0"))-1,pred = chadsmod1)

calibration_plot(data = chadscal, obs = "y", pred = "pred", title = paste0("Calibration plot for ", expression("CHA"[2]*"DS"[2]*"VASc")))

### chest model prediction
chest <- train
chest$chest <- pat2$chest[data]
chesttest <- test
chesttest$chest <- pat2$chest[-data]

chestmod <- glm(as.formula(paste0("af ~ ","chest")),data=chest, family=binomial)
chestmod1<-predict(chestmod,chesttest, type = "response")

chestcal <- data.frame(y = as.numeric(car::recode(chesttest$af,"'Yes' = 1;'No' = 0"))-1,pred = chestmod1)

calibration_plot(data = chestcal, obs = "y", pred = "pred", title = "Calibration plot for CHEST")


#####training with Random forest

### tuning the parameter
set.seed(1234)
tuneGrid <- expand.grid(.mtry = c(6:10))
trControl <- trainControl(method = "repeatedcv",
                          number = 5,
                          repeats = 10,
                          classProbs = TRUE,
                          summaryFunction = MySummary,
                          savePredictions = T)
rfmod <- caret::train(af~.,
                        data = train,
                        method = "rf",
                        metric = "Accuracy",
                        tuneGrid = tuneGrid,
                        trControl = trControl,
                        importance = TRUE,
                        nodesize = 12,
                        ntree = 1000)


testrfmod<-predict(rfmod,rfmod,type='prob')[,2]
testrfpred <- prediction(testrfmod, test$af)   
testrfmod_auc = performance(testrfpred, "auc")
testrfmod_perf80 <- performance(testrfpred,"tpr","fpr")
plot(testrfmod_perf80, add = TRUE)

mroc <- roc(test$af,testrfmod,plot = T)
coords(mroc, .75, "sensitivity", ret=c("specificity","ppv","npv"))

coords(mroc, .9, "sensitivity", ret=c("specificity","ppv","npv"))

rf_imp <- varImpPlot(rfmod, scale = TRUE, n.var = 10)

varImpPlot(rfmod, scale = TRUE, n.var = 10, main = "Gini variable importance",pch = 16,pt.cex = 1.5,
           labels = rev(c("Age","Ethnicity","Heart failure",
                          "non-atrial fibrillation EP procedure",
                          "Rheumatic valve disease / mitral stenosis","Other mitral valve disease",
                          "COPD","Sex","Gout","Chronic IHD")))

#####predict on test from RF model
df <- structure(list(value = testrfmod, type = test$af),.Names = c("value","type"),row.names = c(NA, -41623L),class = "data.frame")
rocobj <- plot.roc(df$type, df$value, percent = TRUE, main="ROC", col="#1c61b6", add=FALSE)

optimal.cutpoint.Youden <- optimal.cutpoints(X = "value", status = "type", tag.healthy = "No", methods = "Youden", 
                                             data = df, pop.prev = NULL,
                                             control = control.cutpoints(), ci.fit = FALSE, conf.level = 0.95, trace = FALSE)
summary(optimal.cutpoint.Youden)
plot(optimal.cutpoint.Youden)



#### reclassification

### get the index for the high risk
mroc <- roc(test$af,testmlrmod,plot = F)
st <- ci.coords(mroc,"best", ret=c("sensitivity","specificity","ppv","npv"),best.method = "youden",boot.n = 300)
coords(mroc, .0040, "threshold", ret=c("sensitivity","specificity","ppv","npv"))

### chads
mroc <- roc(chadstest$af,chadsmod1,plot = F)
st <- ci.coords(mroc,"best", ret=c("sensitivity","specificity","ppv","npv"),best.method = "youden",boot.n = 300)
coords(mroc, .0040, "threshold", ret=c("sensitivity","specificity","ppv","npv"))


### chest
mroc <- roc(chesttest$af,chestmod1,plot = F)
st <- ci.coords(mroc,"best", ret=c("sensitivity","specificity","ppv","npv"),best.method = "youden",boot.n = 300)
coords(mroc, .0020, "threshold", ret=c("sensitivity","specificity","ppv","npv"))


### RF
mroc <- roc(test$af,testrfmod,plot = F)
st <- ci.coords(mroc,"best", ret=c("sensitivity","specificity","ppv","npv"),best.method = "youden",boot.n = 300)
coords(mroc, .0040, "threshold", ret=c("sensitivity","specificity","ppv","npv"))



combinedtest <- data.frame(af = test$af,findaf = ifelse(testmod1>0.0040,1,0),chads = ifelse(chadsmod1>0.0040,1,0),
                           chest = ifelse(chestmod1>0.0020,1,0))


### Net reclassification for FIND-AF

combinedtest1 <- data.frame(patid = pat2[-data,"patid"],af = test$af,findaf = ifelse(testrfmod>0.0040,1,0),
                            chads = ifelse(chadsmod1>0.0040,1,0),
                            chest = ifelse(chestmod1>0.0040,1,0))

combinedtest1 <- merge(combinedtest1, pat[,c("patid","afday")], by = "patid",all.x = T)

with(subset(combinedtest1,af == "Yes"),table(chads,findaf))
with(subset(combinedtest1,af == "Yes"),table(chest,findaf))

with(subset(combinedtest1,af == "No"),table(chads,findaf))
with(subset(combinedtest1,af == "No"),table(chest,findaf))

combinedtest2 <- data.frame(patid = pat[-data,"patid"],af = test$af,findaf = testrfmod,
                            chads = chadsmod1,
                            chest = chestmod1)

## Calculation of risk difference NRI using ('event', 'p.std', 'p.std').
nribin(event = as.numeric(car::recode(combinedtest2$af, "'Yes' = 1; 'No' = 0"))-1, p.std = combinedtest2$chads, 
       p.new = combinedtest2$findaf, cut = 0.004,
       niter = 10)

nribin(event = as.numeric(car::recode(combinedtest2$af, "'Yes' = 1; 'No' = 0"))-1, p.std = combinedtest2$chest, 
       p.new = combinedtest2$findaf, cut = 0.004,
       niter = 10)


#### decision curve analysis

### get the index for the high risk

mroc <- roc(test$af,testrfmod,plot = F)
prev <- prop.table(table(test$af))[2]
nettest <- NULL
thres1 <- NULL
for (i in 1:1000)
{
  thres <- 0+(i-1)*0.00005
  temp <- coords(mroc, thres, "threshold", ret=c("sensitivity","specificity","ppv","npv"))
  nettest <- c(nettest,temp[1]*prev - (1-temp[2])*(1-prev)*thres/(1-thres))
  thres1 <- c(thres1,thres)
}

testrfout <- data.frame(nettest = as.numeric(nettest),thres1 = thres1)


### chads
mroc <- roc(chadstest$af,chadsmod1,plot = F)
prev <- prop.table(table(chadstest$af))[2]
netchads <- NULL
thres1 <- NULL
for (i in 1:1000)
{
  thres <- 0+(i-1)*0.00005
  temp <- coords(mroc, thres, "threshold", ret=c("sensitivity","specificity","ppv","npv"))
  netchads <- c(netchads,temp[1]*prev - (1-temp[2])*(1-prev)*thres/(1-thres))
  thres1 <- c(thres1,thres)
}

chadsout <- data.frame(netchads = as.numeric(netchads),thres1 = thres1)


### chest
mroc <- roc(chesttest$af,chestmod1,plot = F)
prev <- prop.table(table(chesttest$af))[2]
netchest <- NULL
thres1 <- NULL
for (i in 1:1000)
{
  thres <- 0+(i-1)*0.00005
  temp <- coords(mroc, thres, "threshold", ret=c("sensitivity","specificity","ppv","npv"))
  netchest <- c(netchest,temp[1]*prev - (1-temp[2])*(1-prev)*thres/(1-thres))
  thres1 <- c(thres1,thres)
}

chestout <- data.frame(netchest = as.numeric(netchest),thres1 = thres1)


plot(thres1*100, fitted(loess(nettest ~thres1, data = testrfout,span = 0.4,degree = 2)),type = "l",
     xlab = "Threshold probability(%)", lwd = 2, col = "red",
     ylab = "Net benefit",main = "Decision curve to predict incident AF",
)

lines(thres1*100, fitted(loess(netchads ~thres1, data = chadsout,span = 0.4,degree = 2)), lwd = 2, col = "blue")
lines(thres1*100, fitted(loess(netchest ~thres1, data = chestout,span = 0.4,degree = 2)),lwd = 2, col = "green")
legend(3,0.003,c("FIND-AF","CHA2DS2-VASc","C2HEST"),col = c("red","blue","green"),lwd = 2, bty = "n")




### subgroup analysis for sex, age, presence of comorbidities

male <- extractAUC(data = subset(test, gender = "Male"),inputmod = rfmod)
female <- extractAUC(data = subset(test, gender = "Female"),inputmod = rfmod)
over65 <- extractAUC(data = subset(test, age >= 65),inputmod = rfmod)
over75 <- extractAUC(data = subset(test, age >= 75),inputmod = rfmod)
testage <- test
testage$chads <- pat2$chads[-data]
over65chads <- extractAUC(data = subset(testage, age >= 65 & ((gender == "Male" & chads >= 3) | (gender == "Female" & chads >=4))),inputmod = rfmod)

stroke <- extractAUC(data = subset(test, var21 == 1 | var22 == 1 | var23 == 1),inputmod = rfmod)
hf <- extractAUC(data = subset(test, var33 == 1),inputmod = rfmod)
dm <- extractAUC(data = subset(test, var24 == 1 | var25 == 1 | var26 == 1),inputmod = rfmod)
vas <- extractAUC(data = subset(test, var54 == 1),inputmod = rfmod)
htn <- extractAUC(data = subset(test, var34 == 1 | var35 == 1),inputmod = rfmod)

###ethnicity
asian <- extractAUC(data = subset(test, ethnic == "Asian"),inputmod = rfmod)
black <- extractAUC(data = subset(test, ethnic == "Black"),inputmod = rfmod)
other <- extractAUC(data = subset(test, ethnic %in% c("Other")),inputmod = rfmod)
unknown <- extractAUC(data = subset(test, ethnic == "Unknown"),inputmod = rfmod)
white <- extractAUC(data = subset(test, ethnic == "White"),inputmod = rfmod)
