library(readr)
Client <- read_csv("A_HOMELESS/COC/Client.csv")
str(Client)

colnames(Client)
sum(is.na(Client$PersonalID))
length(unique(Client$PersonalID))
#28680

library(dplyr)
counts <-Client %>%
  select(PersonalID)%>%
  group_by(PersonalID)%>%
  summarise(counts=length(PersonalID))

class(Client$DateCreated)
max(Client$DateCreated) # should be 2018
min(Client$DateCreated)

class(Client$DateUpdated)
max(Client$DateUpdated) #should be 2018
min(Client$DateUpdated)

Client$DateUpdated <- as.Date(Client$DateUpdated,format="%m/%d/%Y %H:%M")
Client$DateCreated <- as.Date(Client$DateCreated,format="%m/%d/%Y %H:%M")

class(Client$DateCreated)
max(Client$DateCreated) # should be 2018
min(Client$DateCreated)

class(Client$DateUpdated)
max(Client$DateUpdated) #should be 2018
min(Client$DateUpdated)

library(dplyr)
# select those rows with the latest updated date in multiple records
clientunique <- Client%>%
  select(PersonalID,DateUpdated)%>%
  group_by(PersonalID)%>%
  summarize(DateUpdated=max(DateUpdated))

clientdf <-merge(clientunique,Client,by=c("PersonalID","DateUpdated"))
length(unique(clientdf$PersonalID))


dup <- clientdf[duplicated(clientdf$PersonalID), ]
# 142 records have the same combination of PersonalID and DateUpdated with one record 
#in the test1 dataset below
# test1<-clientdf[!duplicated(clientdf$PersonalID), ]
alldup <-clientdf[clientdf$PersonalID %in% dup$PersonalID,]

alldup1 <- alldup[,c(1,2,27)]

alldupcount <- alldup1%>%
  select(PersonalID)%>%
  group_by(PersonalID)%>%
  summarise(counts=length(PersonalID)) 
#140 PersonalID has duplicated records,some have two duplicates,some have three
p <- alldupcount$PersonalID[alldupcount$counts >2] #have three duplicates


notdup <-clientdf[!clientdf$PersonalID %in% dup$PersonalID,] #28680-140=28540
#select from alldup, those rows with later created
clientunique1 <- alldup%>%
  select(PersonalID,DateCreated)%>%
  group_by(PersonalID)%>%
  summarize(DateCreated=max(DateCreated))

clientdf1 <-merge(clientunique1,alldup,by=c("PersonalID","DateCreated")) 
dup1 <- clientdf1[duplicated(clientdf1$PersonalID), ] 
# 58 have the same combination of PersonalID, Datecreated, Dateupdated with one record in rest dataset
needadd <-clientdf1[!duplicated(clientdf1$PersonalID), ]

#############################clientfinal#######################################
clientfinal <-rbind(notdup,needadd) #final client data without any duplicates
length(unique(clientfinal$PersonalID))
#############################clientfinal#######################################

#Veteran
table(clientfinal$VeteranStatus)
client.veteran <- clientfinal
attach(client.veteran)
client.veteran$VeteranStatus[VeteranStatus==8] <- NA
client.veteran$VeteranStatus[VeteranStatus==9] <- NA
client.veteran$VeteranStatus[VeteranStatus==99] <- NA
detach(client.veteran)
table(client.veteran$VeteranStatus)
table(is.na(client.veteran$VeteranStatus))
client.veteran <- client.veteran[!is.na(client.veteran$VeteranStatus),]#23870
barplot(table(client.veteran$VeteranStatus),names.arg = c("No","Yes"))
###############################################################################################
client.veteran<-client.veteran[client.veteran$VeteranStatus==1,]
client.veteran<-client.veteran[!is.na(client.veteran$VeteranStatus),]



attach(clientfinal)
clientfinal$Gender[Gender==8] <- NA
clientfinal$Gender[Gender==9] <- NA
clientfinal$Gender[Gender==99] <- NA
clientfinal$Gender[Gender==4] <- NA
clientfinal$Gender[Gender==0] <- 0
clientfinal$Gender[Gender==1] <- 1
clientfinal$Gender[Gender==2] <- 0
clientfinal$Gender[Gender==3] <- 1
detach(clientfinal)

clientfinal<-clientfinal[!is.na(clientfinal$Gender),]


##############################race#############################


##############################Ethnicity#############################
attach(clientfinal)
clientfinal$Ethnicity[Ethnicity==8] <- NA
clientfinal$Ethnicity[Ethnicity==9] <- NA
clientfinal$Ethnicity[Ethnicity==99] <- NA
detach(clientfinal)
clientfinal<-clientfinal[!is.na(clientfinal$Ethnicity),]


##############################Age at the most recent enrollment#############################
library(readr)
Enrollment <- read_csv("A_HOMELESS/COC/Enrollment.csv")
enrollment<-Enrollment[Enrollment$PersonalID %in% clientfinal$PersonalID,]
length(unique(enrollment$PersonalID)) #28678
enrolldate <- enrollment %>%
  select(PersonalID,EntryDate) %>%
  group_by(PersonalID) %>%
  summarise(date=max(EntryDate))
agerecentenroll <-merge(enrolldate,clientfinal,by="PersonalID")
agerecentenroll$age <- (as.Date(agerecentenroll$date,format = "%m/%d/%Y")-as.Date(agerecentenroll$DOB,
                                                                                  format = "%m/%d/%Y"))/365.25

table(is.na(agerecentenroll$age))
agerecentenroll <-agerecentenroll[!is.na(agerecentenroll$age),]
agerecentenroll$age<-as.numeric(agerecentenroll$age)


agerecentenroll<-agerecentenroll[,c(1,32)]
clientfinal <-merge(clientfinal,agerecentenroll,by="PersonalID")
#################### disabiling condition##################################

# enrollment
sum(is.na(enrollment$DisablingCondition))
table(enrollment$DisablingCondition)
attach(enrollment)
enrollment$DisablingCondition[DisablingCondition==8] <- NA
enrollment$DisablingCondition[DisablingCondition==9] <- NA
enrollment$DisablingCondition[DisablingCondition==99] <- NA
detach(enrollment)
sum(is.na(enrollment$DisablingCondition))
sum(!is.na(enrollment$DisablingCondition))
DisablingCondition <- enrollment[!is.na(enrollment$DisablingCondition),]

length(unique(DisablingCondition$PersonalID)) 
DisablingCondition.info <- DisablingCondition%>%
  select(PersonalID, DisablingCondition)%>%
  group_by(PersonalID)%>%
  summarise(Disable = max(as.numeric(DisablingCondition)))
View(DisablingCondition.info)
table(DisablingCondition.info$Disable)
clientfinal <-merge(clientfinal,DisablingCondition.info,by="PersonalID")
#################### disability type #########################################################
library(readr)
Disabilities <- read_csv("A_HOMELESS/COC/Disabilities.csv")
Disabilities <-Disabilities[Disabilities$EnrollmentID %in% enrollment$EnrollmentID,]
Disabilities <-Disabilities[Disabilities$PersonalID %in% clientfinal$PersonalID,]
length(unique(Disabilities$PersonalID))

Dcount <- Disabilities%>%
  select(PersonalID)%>%
  group_by(PersonalID)%>%
  summarise(counts = length(PersonalID))

attach(Disabilities)
Disabilities$DisabilityResponse[DisabilityResponse==8] <- NA
Disabilities$DisabilityResponse[DisabilityResponse==9] <- NA
Disabilities$DisabilityResponse[DisabilityResponse==99] <- NA
detach(Disabilities)

sum(!is.na(Disabilities$DisabilityResponse))
Disabilities <- Disabilities[!is.na(Disabilities$DisabilityResponse),] 
length(unique(Disabilities$PersonalID))
table(Disabilities$DisabilityResponse)

#Type5
Distype5 <- Disabilities[Disabilities$DisabilityType==5,]
table(Distype5$DisabilityResponse)

Distype5 <- Distype5%>%
  select(PersonalID,DisabilityResponse)%>%
  group_by(PersonalID)%>%
  summarise(DisType5=max(DisabilityResponse))

table(Distype5$DisType5)

#Type6
Distype6 <- Disabilities[Disabilities$DisabilityType==6,]
table(Distype6$DisabilityResponse)

Distype6 <- Distype6%>%
  select(PersonalID,DisabilityResponse)%>%
  group_by(PersonalID)%>%
  summarise(DisType6=max(DisabilityResponse))

table(Distype6$DisType6)

#Type7
Distype7 <- Disabilities[Disabilities$DisabilityType==7,]
table(Distype7$DisabilityResponse)

Distype7 <- Distype7%>%
  select(PersonalID,DisabilityResponse)%>%
  group_by(PersonalID)%>%
  summarise(DisType7=max(DisabilityResponse))

table(Distype7$DisType7)

#Type8
Distype8 <- Disabilities[Disabilities$DisabilityType==8,]
table(Distype8$DisabilityResponse)

Distype8 <- Distype8%>%
  select(PersonalID,DisabilityResponse)%>%
  group_by(PersonalID)%>%
  summarise(DisType8=max(DisabilityResponse))

table(Distype8$DisType8)

#Type9
Distype9 <- Disabilities[Disabilities$DisabilityType==9,]
table(Distype9$DisabilityResponse)

Distype9 <- Distype9%>%
  select(PersonalID,DisabilityResponse)%>%
  group_by(PersonalID)%>%
  summarise(DisType9=max(DisabilityResponse))

table(Distype9$DisType9)

#Type10
Distype10 <- Disabilities[Disabilities$DisabilityType==10,]
table(Distype10$DisabilityResponse)

Distype10 <- Distype10%>%
  select(PersonalID,DisabilityResponse)%>%
  group_by(PersonalID)%>%
  summarise(DisType10=max(DisabilityResponse))

table(Distype10$DisType10)

distype <-merge(Distype5,Distype6,by="PersonalID")
distype <-merge(distype,Distype7,by="PersonalID")
distype <-merge(distype,Distype8,by="PersonalID")
distype <-merge(distype,Distype9,by="PersonalID")
distype <-merge(distype,Distype10,by="PersonalID")
clientfinal <-merge(clientfinal,distype,by="PersonalID")
##############################################################################################

library(readr)
HealthAndDV <- read_csv("A_HOMELESS/COC/HealthAndDV.csv")
HealthAndDV <-HealthAndDV[HealthAndDV$EnrollmentID %in% enrollment$EnrollmentID,]
HealthAndDV <-HealthAndDV[HealthAndDV$PersonalID %in% clientfinal$PersonalID,]

table(HealthAndDV$DomesticViolenceVictim)
attach(HealthAndDV)
HealthAndDV$DomesticViolenceVictim[DomesticViolenceVictim==8] <- NA
HealthAndDV$DomesticViolenceVictim[DomesticViolenceVictim==9] <- NA
HealthAndDV$DomesticViolenceVictim[DomesticViolenceVictim==99] <- NA
detach(HealthAndDV)
table(HealthAndDV$DomesticViolenceVictim)
DVdf <- HealthAndDV[!is.na(HealthAndDV$DomesticViolenceVictim),]
length(unique(DVdf$PersonalID))

library(dplyr)
DV <-DVdf%>%
  select(PersonalID,DomesticViolenceVictim)%>%
  group_by(PersonalID)%>%
  summarise(DomesticViolenceVictim=max(DomesticViolenceVictim))
table(DV$DomesticViolenceVictim)
#####DV######

clientfinal <-merge(clientfinal,DV,by="PersonalID")



###############################################################################################
#income info
library(readr)
IncomeBenefits <- read_csv("A_HOMELESS/COC/IncomeBenefits.csv")


#income amount
colnames(IncomeBenefits)
class(IncomeBenefits$TotalMonthlyIncome)
range(IncomeBenefits$TotalMonthlyIncome,na.rm = TRUE)
sum(is.na(IncomeBenefits$IncomeFromAnySource))

incomeamounts1 <-IncomeBenefits[,c(1:36)]#118991
# incomeamounts1 <- incomeamounts1[incomeamounts1$EnrollmentID %in% mydata$EnrollmentID,]#109227

incomeamounts<-incomeamounts1
incomeamounts$TotalMonthlyIncome[is.na(incomeamounts$TotalMonthlyIncome)]<-0
range(incomeamounts$TotalMonthlyIncome,na.rm = TRUE)
incomeamounts$PersonalID[incomeamounts$TotalMonthlyIncome==290683]

incomeamounts[is.na(incomeamounts)]<-0
class(incomeamounts$VADisabilityNonServiceAmount)
incomeamounts$VADisabilityNonServiceAmount<-as.numeric(incomeamounts$VADisabilityNonServiceAmount)
class(incomeamounts$PrivateDisabilityAmount)
incomeamounts$PrivateDisabilityAmount <-as.numeric(incomeamounts$PrivateDisabilityAmount)
class(incomeamounts$WorkersCompAmount)
incomeamounts$WorkersCompAmount <-as.numeric(incomeamounts$WorkersCompAmount)
class(incomeamounts$AlimonyAmount)
incomeamounts$AlimonyAmount <- as.numeric(incomeamounts$AlimonyAmount)

incomeamounts$amount <- incomeamounts$EarnedAmount+incomeamounts$UnemploymentAmount+incomeamounts$SSIAmount+
  incomeamounts$SSDIAmount+incomeamounts$VADisabilityServiceAmount+incomeamounts$VADisabilityNonServiceAmount+
  incomeamounts$PrivateDisabilityAmount+incomeamounts$WorkersCompAmount+incomeamounts$TANFAmount+
  incomeamounts$GAAmount+incomeamounts$SocSecRetirementAmount+incomeamounts$PensionAmount+
  incomeamounts$ChildSupportAmount+incomeamounts$AlimonyAmount+incomeamounts$OtherIncomeAmount

incomeamounts <-incomeamounts[,37]

incomeamounts <-cbind(incomeamounts1,incomeamounts)
table(incomeamounts$IncomeFromAnySource)
incomeamounts <- incomeamounts[,c(1:6,37)]


#-100 as missing value
incomeamounts$TotalMonthlyIncome[is.na(incomeamounts$TotalMonthlyIncome)]<--100
#dealing with missing value in TMI
df<-incomeamounts[incomeamounts$TotalMonthlyIncome==-100,]
df <- df[df$amount>0,]#585 has value in calculated income amount but missing in TMI

df1<-incomeamounts[incomeamounts$TotalMonthlyIncome==0,]
df1 <- df1[df1$amount>0,]#2 has cal amount but original amount is 0

#original amount is not equal to calculated amount
d <- incomeamounts[!incomeamounts$TotalMonthlyIncome==incomeamounts$amount,]#33067
e <- incomeamounts[incomeamounts$TotalMonthlyIncome==incomeamounts$amount,]#76160


#fix missing values in TotalMonthlyIncome
norow<-nrow(incomeamounts)
for (i in 1:norow){
  if (incomeamounts$TotalMonthlyIncome[i]==-100){
    if(incomeamounts$amount[i]>0){
      incomeamounts$TotalMonthlyIncome[i]=incomeamounts$amount[i]
    }
  }
}
# IBID 206023 973065

for (i in 1:norow){
  if (incomeamounts$TotalMonthlyIncome[i]==0){
    if(incomeamounts$amount[i]>0){
      incomeamounts$TotalMonthlyIncome[i]=incomeamounts$amount[i]
    }
  }
}
# IBID 60472 777242

d1 <- incomeamounts[!incomeamounts$TotalMonthlyIncome==incomeamounts$amount,]#32480
d2 <-incomeamounts[incomeamounts$TotalMonthlyIncome > incomeamounts$amount,]#197
d3 <-incomeamounts[incomeamounts$TotalMonthlyIncome < incomeamounts$amount,]#32283

for (i in 1:norow){
  if (incomeamounts$TotalMonthlyIncome[i] < incomeamounts$amount[i]){
    if(incomeamounts$amount[i]>0){
      incomeamounts$TotalMonthlyIncome[i]=incomeamounts$amount[i]
    }
  }
}

d4 <-incomeamounts[incomeamounts$TotalMonthlyIncome < incomeamounts$amount,]#32282





#fix discrepency between binary and amounts
withincome <-incomeamounts[incomeamounts$IncomeFromAnySource==1,]#34170
#labeld as with income, but the amount is 0
b <-withincome[withincome$TotalMonthlyIncome==0,]


#fix amount is 0 but labeled as with income (1)/8/9/99, change the original label to 0
for (i in 1:norow) {
  if (incomeamounts$TotalMonthlyIncome[i]==0){
    incomeamounts$IncomeFromAnySource[i]=0
  }
}

withincome1 <-incomeamounts[incomeamounts$IncomeFromAnySource==1,] #33145
table(incomeamounts$IncomeFromAnySource)



noincome <-incomeamounts[incomeamounts$IncomeFromAnySource==0,]#59598

# has income but labeled as no income
a <- noincome[noincome$TotalMonthlyIncome > 0,]#113

#fix acutually have income but labeled as no income(0) or labeled as 8/9/99
for (i in 1:norow) {
  if (incomeamounts$TotalMonthlyIncome[i]>0){
    incomeamounts$IncomeFromAnySource[i]=1
  }
}

table(incomeamounts$IncomeFromAnySource)
noincome1 <-incomeamounts[incomeamounts$IncomeFromAnySource==0,] #59485=59598-113
#difference between noincome and noincome1 is 113
a1 <- noincome1[noincome1$TotalMonthlyIncome > 0,] #0

withincome2 <-incomeamounts[incomeamounts$IncomeFromAnySource==1,] #33263


attach(incomeamounts)
incomeamounts$INCOME[IncomeFromAnySource==8] <- NA
incomeamounts$INCOME[IncomeFromAnySource==9] <- NA
incomeamounts$INCOME[IncomeFromAnySource==99] <- NA
incomeamounts$INCOME[IncomeFromAnySource==1] <- 1
incomeamounts$INCOME[IncomeFromAnySource==0] <- 0
detach(incomeamounts)
sum(!is.na(incomeamounts$INCOME))
Incomedf <- incomeamounts[!is.na(incomeamounts$INCOME),]
length(unique(Incomedf$PersonalID)) 

library(dplyr)
Income.info <- Incomedf%>%
  select(PersonalID, INCOME)%>%
  group_by(PersonalID)%>%
  summarise(income = sum(as.numeric(INCOME)))
View(Income.info)
Income.info$income1 <- ifelse(Income.info$income==0,0,1)

table(Income.info$income1)
#    0     1 
# 12466  9989
barplot(table(Income.info$income1),names.arg = c("No","Yes"),
        main = "income",ylim = range(0,15000))
##############################################################################################
clientfinal <-merge(clientfinal,Income.info,by="PersonalID")
names(clientfinal)
table(clientfinal$VeteranStatus)
attach(clientfinal)
clientfinal$VeteranStatus[VeteranStatus==8] <- NA
clientfinal$VeteranStatus[VeteranStatus==9] <- NA
clientfinal$VeteranStatus[VeteranStatus==99] <- NA
detach(clientfinal)
table(clientfinal$VeteranStatus)
clientfinal <- clientfinal[!is.na(clientfinal$VeteranStatus),]
clientfinal <- clientfinal[,c(1,5,6,7,8,9,11,12,14,31,32,33,34,35,36,37,38,39,41)]
##############################################################################################




getwd()
setwd("C:/Users/inner/Documents")

library(readr)
Enrollment <- read_csv("A_HOMELESS/COC/Enrollment.csv")
Exit <- read_csv("A_HOMELESS/COC/Exit.csv")

length(unique(Enrollment$EnrollmentID))

Exitunique <- Exit%>%
  select(EnrollmentID,ExitDate)%>%
  group_by(EnrollmentID)%>%
  summarize(ExitDate=max(ExitDate))
ExitUpdate <- merge(Exit, Exitunique, by=c("EnrollmentID","ExitDate"))
ExitUpdate <- Exit[!duplicated(Exit$EnrollmentID),]

mydata <-merge(x=Enrollment,y=ExitUpdate, by="EnrollmentID",all.x = TRUE)
sum(is.na(mydata$ExitDate)) #14466 Enollment
74564-14466

mydata <- mydata[,c("EnrollmentID","PersonalID.x","EntryDate","ExitDate", "ProjectID")]
sum(is.na(mydata$ExitDate))
colnames(mydata)[2]<-"PersonalID"

noexitdate <- mydata[is.na(mydata$ExitDate),]
length(unique(noexitdate$PersonalID)) #11653

#answer question
vetnoexit<-noexitdate[noexitdate$PersonalID %in% client.veteran$PersonalID,]
length(unique(vetnoexit$PersonalID)) #417

library(readr)
Services <- read_csv("A_HOMELESS/COC/Services.csv")

length(unique(Services$EnrollmentID))
#only 66086 enrollment in service, where 74564-66086 enrollment go?
74564-66086
servicenoexit <- Services[Services$EnrollmentID %in% noexitdate$EnrollmentID,]
exitdate <- servicenoexit%>%
  select(EnrollmentID,DateProvided)%>%
  group_by(EnrollmentID)%>%
  summarize(ExitDateextract=max(DateProvided))

#12172 with a maximum service date, still 14466- 12172 doesn't have any service date
14466- 12172
mydataupdate <- merge(x=mydata,y=exitdate, by="EnrollmentID",all.x = TRUE)

for (i in (1:(length(mydataupdate$EnrollmentID)))){
  a=is.na(mydataupdate$ExitDate[i])
  if (a==TRUE) {
    mydataupdate$ExitDate[i]=mydataupdate$ExitDateextract[i]
  }
}




mydata<-mydataupdate
mydata <-mydata[!is.na(mydata$ExitDate),]#72270
74564-(14466- 12172)

mydata <- mydata[order(mydata$PersonalID,mydata$EntryDate),]

#e.g. 333197,334263,607965
#ExitDate
for (i in 1:(nrow(mydata)-1)){
  if ((mydata$PersonalID[i]) == (mydata$PersonalID[i+1])){
    if ((mydata$ExitDate[i+1])<(mydata$ExitDate[i])){
      mydata$ExitDate[i+1] <- mydata$ExitDate[i]
    } 
  } 
}  


# e.g. PID:452889,EID:797411 entrydate:2018-01-05 exitdate:2018-03-11
#                 EID:797779 entrydate:2018-01-17 exitdate:2018-02-11
# 452891 pic
# 333197
#EntryDate
for (i in 1:(nrow(mydata)-1)){
  if ((mydata$PersonalID[i]) == (mydata$PersonalID[i+1])){
    if ((mydata$EntryDate[i+1])<(mydata$ExitDate[i])){
      mydata$EntryDate[i+1] <- mydata$ExitDate[i]
    } 
  } 
}  

#calculate LoH
mydata$EntryYear <- format(as.Date(mydata$EntryDate, format= "%m/%d/%Y"),"%Y")
mydata$ExitYear <- format(as.Date(mydata$ExitDate, format= "%m/%d/%Y"),"%Y")

#count unique persons
length(unique(mydata$PersonalID))#27326 clients have entry and exit date


#count entrants each year
table(mydata$EntryYear)
table(mydata$ExitYear)

#calculate length of homeless of each episode
mydata$lengthhomeless <-mydata$ExitDate-mydata$EntryDate
range(mydata$lengthhomeless)
mydata$PersonalID[mydata$lengthhomeless==5558]
# PID 340403

#calculate total length of homeless, years in the system

library(dplyr)
loh <- mydata%>%
  select(PersonalID, lengthhomeless, ExitYear,EntryYear)%>%
  group_by(PersonalID)%>%
  summarise(lengthhomelesstotal = sum(lengthhomeless), years =max(as.numeric(ExitYear))-min(as.numeric(EntryYear)))
View(loh)

#calculate calendar years in the system
loh$years <- loh$years+1

#average length of homeless per year
loh$averagelength <-as.numeric(loh$lengthhomelesstotal)/as.numeric(loh$years)
range(loh$averagelength)

###chronic####
chronic <-loh
chronic$chronicity <-ifelse(chronic$averagelength*3>=365,1,0)
chronic<-chronic[,c(1,5)]

clientfinal<-merge(clientfinal,chronic,by="PersonalID")


logisticModeltest <- glm(chronicity~.-PersonalID, data = clientfinal, family = "binomial")
summary(logisticModeltest)
logisticModeltest <- glm(chronicity~BlackAfAmerican+Ethnicity+VeteranStatus+age+Disable+DisType6+DisType9+DisType10+income1, data = clientfinal, family = "binomial")
summary(logisticModeltest)



vec <-c("AmIndAKNative","Asian","BlackAfAmerican","NativeHIOtherPacific","White","Ethnicity","Gender","VeteranStatus","age","Disable","DisType5","DisType6","DisType7","DisType8","DisType9","DisType10","DomesticViolenceVictim","income1")
sumtable<-clientfinal%>%
  group_by(chronicity)%>%
  summarize_each_(funs(mean), vec)
getwd()
write.csv(sumtable,'sumtable.csv')

for(i in vec){
  print (paste(i, ':', sep = ' '))
  print(mean(clientfinal[[i]]))
}

sumtable<-clientfinal%>%
  group_by(chronicity)%>%
  summarize_each_(funs(mean), vec)








