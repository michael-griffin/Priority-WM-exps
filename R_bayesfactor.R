#Calculates BayesFactors for correlations across each experiment (and combined analyses)
#The two correlations checked are:
#--Working Memory x Recall Accuracy
#--Working Memory x Selectivity

#setwd("your directory here")
library(readxl)
library(BayesFactor)

bayesacc = data.frame(matrix(nrow = 7, ncol = 7))
colnames(bayesacc) = c("exps", "Ntotal","corr", "tval", "bf10tval", "priortval", "bf01")

bayesselect = bayesacc


folder = 'data/'
for (i in 1:7){

  if (i <= 4){
    bayesacc[i,1] = i
    filename = paste0(folder, 'fullwmsummary_exp', as.character(i), '.xlsx')
    datwm = read_excel(filename, 1)
    filename = paste0(folder, 'fullrecallsummary_exp', as.character(i), '.xlsx')
    datrecall = read_excel(filename, 1)
    
    dat = cbind(datwm, datrecall)
  } else {
    if (i==5){
      bayesacc[i,1] = '1+2'
    } else if (i==6){
      bayesacc[i,1] = '3+4'
    } else if (i==7){
      bayesacc[i,1] = 'all4'
    }
    filename = paste0(folder, 'overallsummary_combined.xlsx')
    dat = read_excel(filename, i-4) 
    
    #overallsummary files have means/SEs at the bottom. This trims.
    index = which(is.na(dat$Subject))[1]-1 
    dat = dat[1:index,]
    #Factor levels are stored implicitly as integers, 
    #so must convert in sequence factor>char>numeric
    dat = data.frame(sapply(dat, as.character), stringsAsFactors = FALSE)
    dat = data.frame(sapply(dat, as.numeric))
  }
  bayesselect[,1] = bayesacc[,1]
  
  
  bayesacc[i,"Ntotal"] = dim(dat)[1]
  corracc = cor(x = dat$OverallWM, y = dat$OverallAcc) # 'method = ' gives type of correlation, and defaults to pearson
  tvalacc = corracc/(sqrt((1-corracc^2)/(dim(dat)[1] - 2)))
  bayesacc[i,"corr"] = corracc
  bayesacc[i,"tval"] = tvalacc
  
  index = which(!is.na(dat$Selectivity)) #0 Accuracy leads to a noncalcuable selectivity, cut these subs.
  bayesselect[i,"Ntotal"] = length(index)
  corrselect = cor(x = dat$OverallWM[index], y = dat$Selectivity[index])
  tvalselect = corrselect/(sqrt((1-corrselect^2)/(length(index) - 2)))   #t=r/sqrt[(1-r^2)/(N-2)]
  bayesselect[i,"corr"] = corrselect 
  bayesselect[i,"tval"] = tvalselect

  #rscale is how broad the prior on effect size should be.
  #medium (default) has 50% of the expected effect sizes falling between sqrt(2)/2. 
  #wide has 50% fall between +-1
  #ultra-wide has 50% fall between +- sqrt(2).
  
  #below gives bf10, or BF in favor of the alternative.
  bftvalacc = ttest.tstat(t=tvalacc, n1=dim(dat)[1], rscale = "medium", simple = TRUE)
  bayesacc[i,"bf10tval"] = bftvalacc
  bayesacc[i,"priortval"] = "medium"
  
  bftvalselect = ttest.tstat(t=tvalselect, n1=length(index), rscale = "medium", simple = TRUE) #gives bf10, or BF in favor of the alternative
  bayesselect[i,"bf10tval"] = bftvalselect
  bayesselect[i,"priortval"] = "medium"
}

bf01 = 1/bayesselect$bf10tval
bayesselect$bf01 = bf01
bf01 = 1/bayesacc$bf10tval
bayesacc$bf01 = bf01

