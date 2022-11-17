chadsfun <- function(data = pat)
{
  pat$gender <- car::recode(pat$gender,"1 = 'Female';2 = 'Male'")
  pat$af <- car::recode(pat$af,"1 = 'Yes';0 = 'No'")
  pat$dm <- rowSums(pat[,c("dm.good-control_rv2","dm.poor-control.2_rv2","dm.unspecified.secondary_rv2")])
  pat$dm <- ifelse(pat$dm>0,1,0)
  
  pat$cva <- rowSums(pat[,c( "cva.ich_rv2","cva.sah_rv2","cva_rv2_2")])
  pat$cva <- ifelse(pat$cva>0,1,0)
  
  pat$ihd <- rowSums(pat[,c("ihd.chronic_rv2_5","ihd.mi_rv2_4","pci_rv2_2")])
  pat$ihd <- ifelse(pat$ihd>0,1,0)
  
  pat$htn <- rowSums(pat[,c("htn.poor-control_rv2","htn.unspecified.secondary_rv2")])
  pat$htn <- ifelse(pat$htn>0,1,0)
  
  pat$hf <- rowSums(pat[,c("hf.all_rv2")])
  pat$hf <- ifelse(pat$hf>0,1,0)
  
  pat$dyslip <- ifelse(pat$dyslipidaemia_rv2>0,1,0)
  pat$hyperthyroid <- pat$hyperthyroid_rv2
  pat$copd <- pat$copd_rv2_2
  
  pat$ckd <- rowSums(pat[,c("ckd.other_rv2","ckd.stage1-2_rv2",
                            "ckd.stage3_rv2","ckd.stage4_rv2","ckd.stage5_rv2","ckd.unspecified_rv2")])
  
  pat$ckd <- ifelse(pat$ckd>0,1,0)
  
  pat$anaemia <- pat$anaemia_rv2_2
  pat$cancer <- rowSums(pat[,c("cancer.leuk_rv2","cancer.lymph_rv2","cancer.mets_rv2","cancer.otherskin_rv2","cancer.solid_rv2")])
  pat$cancer <- ifelse(pat$cancer>0,1,0)
  
  pat$valve <- rowSums(pat[,c("valve.nonmv.unspec_rv2","valve.ms.rheum_rv2" ,"valve.othermv_rv2")])
  pat$valve <- ifelse(pat$valve>0,1,0)
  
  pat$cvaemb <- rowSums(pat[,c("cva","syst.emb_rv2_2")])
  pat$cvaemb <- ifelse(pat$cvaemb>0,1,0)
  
  pat$age1 <- ifelse(pat$age>=75,2,0)
  pat$age2 <- ifelse(pat$age >= 65 & pat$age <75,1,0)
  
  ## all ages >= 75
  pat$chads <- pat$age1 + pat$age2 + 
    ifelse(pat$gender == "Female",1,0) + pat$hf + pat$htn + pat$dm + 2*pat$cvaemb + pat$valve
  
  return(pat$chads)
}

chestfun <- function(data = pat)
{
  pat$af <- car::recode(pat$af,"1 = 'Yes';0 = 'No'")
  
  pat$ihd <- rowSums(pat[,c("ihd.chronic_rv2_5","ihd.mi_rv2_4","pci_rv2_2")])
  pat$ihd <- ifelse(pat$ihd>0,1,0)
  
  pat$htn <- rowSums(pat[,c("htn.poor-control_rv2","htn.unspecified.secondary_rv2")])
  pat$htn <- ifelse(pat$htn>0,1,0)
  
  
  pat$hf <- rowSums(pat[,c("hf.all_rv2")])
  pat$hf <- ifelse(pat$hf>0,1,0)

  pat$hyperthyroid <- pat$hyperthyroid_rv2
  pat$copd <- pat$copd_rv2_2

  
  pat$age1 <- ifelse(pat$age>=75,2,0)
  
  ## all ages >= 75
  pat$chest <- pat$age1 + 2*pat$hf + pat$htn + pat$copd + pat$hyperthyroid + pat$ihd
  
  return(pat$chest)
}



tabledes <- function(pat = pat1,tablename = "")
{
  pat$dm <- rowSums(pat[,c("dm.good-control_rv2","dm.poor-control.2_rv2","dm.unspecified.secondary_rv2")])
  pat$dm <- ifelse(pat$dm>0,1,0)
  
  pat$cva <- rowSums(pat[,c( "cva.ich_rv2","cva.sah_rv2","cva_rv2_2")])
  pat$cva <- ifelse(pat$cva>0,1,0)
  
  pat$ihd <- rowSums(pat[,c("ihd.chronic_rv2_5","ihd.mi_rv2_4","pci_rv2_2")])
  pat$ihd <- ifelse(pat$ihd>0,1,0)
  
  pat$htn <- rowSums(pat[,c("htn.poor-control_rv2","htn.unspecified.secondary_rv2")])
  pat$htn <- ifelse(pat$htn>0,1,0)
  
  pat$hf <- rowSums(pat[,c("hf.all_rv2")])
  pat$hf <- ifelse(pat$hf>0,1,0)
  
  pat$dyslip <- ifelse(pat$dyslipidaemia_rv2>0,1,0)
  pat$hyperthyroid <- pat$hyperthyroid_rv2
  pat$copd <- pat$copd_rv2_2
  
  pat$ckd <- rowSums(pat[,c("ckd.other_rv2","ckd.stage1-2_rv2",
                            "ckd.stage3_rv2","ckd.stage4_rv2","ckd.stage5_rv2","ckd.unspecified_rv2")])
  
  pat$ckd <- ifelse(pat$ckd>0,1,0)
  
  pat$anaemia <- pat$anaemia_rv2_2
  pat$cancer <- rowSums(pat[,c("cancer.leuk_rv2","cancer.lymph_rv2","cancer.mets_rv2","cancer.otherskin_rv2","cancer.solid_rv2")])
  pat$cancer <- ifelse(pat$cancer>0,1,0)
  
  pat$valve <- rowSums(pat[,c("valve.nonmv.unspec_rv2","valve.ms.rheum_rv2" ,"valve.othermv_rv2")])
  pat$valve <- ifelse(pat$valve>0,1,0)
  
  pat$cvaemb <- rowSums(pat[,c("cva","syst.emb_rv2_2")])
  pat$cvaemb <- ifelse(pat$cvaemb>0,1,0)
  
  
  vars <- c("age","gender","ethnic", "dm","cva","ihd","htn","hf","dyslip","hyperthyroid","copd","ckd","anaemia","cancer","valve","chads")
  catvars <- c("gender","ethnic", "dm","cva","ihd","htn","hf","dyslip","hyperthyroid","copd","ckd","anaemia","cancer","valve")
  
  table1 <- tableone::CreateTableOne(vars = vars,factorVars = catvars,data = pat)
  
  table1_print <- print(table1,exact = c("status","stage"),quote = TRUE, noSpaces = TRUE,nonnormal = c("age"))
  
  write.csv(table1_print,file = paste0(outdatadir,"table 1",tablename,".csv"))
}

create_rfplot <- function(rf, type){
  
  imp <- importance(rf, type = type, scale = F)
  
  featureImportance <- data.frame(Feature = row.names(imp), Importance = imp[,1])
  
  p <- ggplot(featureImportance, aes(x = reorder(Feature, Importance), y = Importance)) +
    geom_bar(stat = "identity", fill = "#53cfff", width = 0.65) +
    coord_flip() + 
    theme_light(base_size = 20) +
    theme(axis.title.x = element_text(size = 15, color = "black"),
          axis.title.y = element_blank(),
          axis.text.x  = element_text(size = 15, color = "black"),
          axis.text.y  = element_text(size = 15, color = "black")) 
  return(p)
}

extractAUC <- function(data = data, inputmod = rfmod)
{
  testage <- data
  testmod1<-predict(inputmod,testage, type = "response")
  testpred1 <- prediction(testmod1, testage$af)   
  testmod1_auc = performance(testpred1, "auc")
  testmod1_perf80 <- performance(testpred1,"tpr","fpr")
  mroc <- roc(testage$af,testmod1,plot = F)
  st <- ci.coords(mroc,"best", ret=c("sensitivity","specificity","ppv","npv"),best.method = "youden",boot.n = 300)
  auc <- as.numeric(paste(ci.auc(mroc)))
  auc <- paste0(format(round(auc[2],3),nsmall = 3)," (",
                format(round(auc[1],3),nsmall = 3), "-",
                format(round(auc[3],3),nsmall = 3),")")
  sensitivity <- paste0(format(round(st$sensitivity[2],3),nsmall = 3)," (",
                        format(round(st$sensitivity[1],3),nsmall = 3), "-",
                        format(round(st$sensitivity[3],3),nsmall = 3),")")
  specificity <- paste0(format(round(st$specificity[2],3),nsmall = 3)," (",
                        format(round(st$specificity[1],3),nsmall = 3), "-",
                        format(round(st$specificity[3],3),nsmall = 3),")")
  ppv <- paste0(format(round(st$ppv[2],3),nsmall = 3)," (",
                        format(round(st$ppv[1],3),nsmall = 3), "-",
                        format(round(st$ppv[3],3),nsmall = 3),")")
  npv <- paste0(format(round(st$npv[2],3),nsmall = 3)," (",
                        format(round(st$npv[1],3),nsmall = 3), "-",
                        format(round(st$npv[3],3),nsmall = 3),")")
  nns <- paste0(format(round(1/st$ppv[2],0),nsmall = 0)," (",
                format(round(1/st$ppv[3],0),nsmall = 0), "-",
                format(round(1/st$ppv[1],0),nsmall = 0),")")
  
  return(data.frame(auc = auc,sensitivity = sensitivity,specificity = specificity,ppv = ppv,npv = npv, nns = nns))
}

