% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/linear-mixed-model-development.R
\docType{class}
\name{LinearMixedModelDevelopment}
\alias{LinearMixedModelDevelopment}
\title{Compare predictive models, created on your data}
\format{An object of class \code{R6ClassGenerator} of length 24.}
\usage{
LinearMixedModelDevelopment(type, df, 
grainCol, personCol, predictedCol, impute, debug, cores, modelName)
}
\arguments{
\item{type}{The type of model (either 'regression' or 'classification')}

\item{df}{Dataframe whose columns are used for calc.}

\item{grainCol}{Optional. The data frame's ID column pertaining to the grain}

\item{personCol}{The data frame's ID column pertaining to the person/patient}

\item{predictedCol}{Column that you want to predict. If you're doing
classification then this should be Y/N.}

\item{impute}{Set all-column imputation to T or F.
If T, this uses mean replacement for numeric columns
and most frequent for factorized columns.
F leads to removal of rows containing NULLs.
Values are saved for deployment.}

\item{debug}{Provides the user extended output to the console, in order
to monitor the calculations throughout. Use T or F.}

\item{cores}{Number of cores you'd like to use. Defaults to 2.}

\item{modelName}{Optional string. Can specify the model name. If used, you must load the same one in the deploy step.}
}
\description{
This step allows you to create a linear mixed model on your data. LMM is 
best suited to longitudinal data that has multiple entries for a each patient or
physician. It will fit a slightly different linear model to each patient.
This algorithm works best with linearly separable data sets. As data sets
become longer than 100k rows or wider than 50 features, performance will suffer.
}
\section{Methods}{
 
The above describes params for initializing a new linearMixedModelDevelopment class with 
\code{$new()}. Individual methods are documented below.
}

\section{\code{$new()}}{

Initializes a new linear mixed model development class using the 
parameters saved in \code{p}, documented above. This method loads, cleans, and prepares data for
model training. \cr
\emph{Usage:} \code{$new(p)}
}

\section{\code{$run()}}{

Trains model, displays feature importance and performance. \cr
\emph{Usage:}\code{$new()}
}

\section{\code{$getPredictions()}}{

Returns the predictions from test data. \cr
\emph{Usage:} \code{$getPredictions()} \cr
}

\section{\code{$getROC()}}{

Returns the ROC curve object for \code{\link{plotROCs}}. Classification models only. \cr
\emph{Usage:} \code{$getROC()} \cr
}

\section{\code{$getPRCurve()}}{

Returns the PR curve object for \code{\link{plotPRCurve}}. Classification models only. \cr
\emph{Usage:} \code{$getROC()} \cr
}

\section{\code{$getAUROC()}}{

Returns the area under the ROC curve from testing for classification models. \cr
\emph{Usage:} \code{$getAUROC()} \cr
}

\section{\code{$getRMSE()}}{

Returns the RMSE from test data for regression models. \cr
\emph{Usage:} \code{$getRMSE()} \cr
}

\section{\code{$getMAE()}}{

Returns the RMSE from test data for regression models. \cr
\emph{Usage:} \code{$getMAE()} \cr
}

\examples{

### Built-in example; Doing classification
library(healthcareai)
library(lme4)

df <- sleepstudy

str(df)

# Create binary column for classification
df$ReactionFLG <- ifelse(df$Reaction > 300, "Y", "N")
df$Reaction <- NULL

set.seed(42)
p <- SupervisedModelDevelopmentParams$new()
p$df <- df
p$type <- "classification"
p$impute <- TRUE
p$personCol <- "Subject"  # Think of this as PatientID
p$predictedCol <- "ReactionFLG"
p$debug <- FALSE
p$cores <- 1

# Create Mixed Model
lmm <- LinearMixedModelDevelopment$new(p)
lmm$run()

### Doing regression
library(healthcareai)

# SQL query and connection goes here - see SelectData function.

df <- sleepstudy

# Add GrainID, which is equivalent to PatientEncounterID
df$GrainID <- seq.int(nrow(df))

str(df)

set.seed(42)
p <- SupervisedModelDevelopmentParams$new()
p$df <- df
p$type <- "regression"
p$impute <- TRUE
p$grainCol <- "GrainID"  # Think of this as PatientEnounterID
p$personCol <- "Subject"  # Think of this as PatientID
p$predictedCol <- "Reaction"
p$debug <- FALSE
p$cores <- 1

# Create Mixed Model
lmm <- LinearMixedModelDevelopment$new(p)
lmm$run()

#### Example using csv data ####
library(healthcareai)
# setwd('C:/Your/script/location') # Needed if using YOUR CSV file
ptm <- proc.time()

# Can delete this line in your work
csvfile <- system.file("extdata", "HCRDiabetesClinical.csv", package = "healthcareai")
#Replace csvfile with "path/to/yourfile"
df <- read.csv(file = csvfile, header = TRUE, na.strings = c("NULL", "NA", ""))

head(df)

set.seed(42)

p <- SupervisedModelDevelopmentParams$new()
p$df <- df
p$type <- "classification"
p$impute <- TRUE
p$grainCol <- "PatientEncounterID"
p$personCol <- "PatientID"
p$predictedCol <- "ThirtyDayReadmitFLG"
p$debug <- FALSE
p$cores <- 1

# Create Mixed Model
lmm <- LinearMixedModelDevelopment$new(p)
lmm$run()

set.seed(42) 
# Run Lasso
# Lasso <- LassoDevelopment$new(p)
# Lasso$run()
cat(proc.time() - ptm, '\\n')

\dontrun{
#### This example is specific to Windows and is not tested. 
#### Example using SQL Server data ####
# This example requires that you alter your connection string / query
# to read in your own data

ptm <- proc.time()
library(healthcareai)

connection.string <- "
driver={SQL Server};
server=localhost;
database=SAM;
trusted_connection=true
"

# This query should pull only rows for training. They must have a label.
query <- "
SELECT
 [PatientEncounterID]
,[PatientID]
,[SystolicBPNBR]
,[LDLNBR]
,[A1CNBR]
,[GenderFLG]
,[ThirtyDayReadmitFLG]
FROM [SAM].[dbo].[HCRDiabetesClinical]
--no WHERE clause, because we want train AND test
"

df <- selectData(connection.string, query)
head(df)

set.seed(42)

p <- SupervisedModelDevelopmentParams$new()
p$df <- df
p$type <- "classification"
p$impute <- TRUE
p$grainCol <- "PatientEncounterID"
p$personCol <- "PatientID"
p$predictedCol <- "ThirtyDayReadmitFLG"
p$debug <- FALSE
p$cores <- 1

# Create Mixed Model
lmm <- LinearMixedModelDevelopment$new(p)
lmm$run()

# Remove person col, since RF can't use it
df$personCol <- NULL
p$df <- df
p$personCol <- NULL

set.seed(42) 
# Run Random Forest
rf <- RandomForestDevelopment$new(p)
rf$run()

# Plot ROC
rocs <- list(lmm$getROC(), rf$getROC())
names <- c("Linear Mixed Model", "Random Forest")
legendLoc <- "bottomright"
plotROCs(rocs, names, legendLoc)

# Plot PR Curve
rocs <- list(lmm$getPRCurve(), rf$getPRCurve())
names <- c("Linear Mixed Model", "Random Forest")
legendLoc <- "bottomleft"
plotPRCurve(rocs, names, legendLoc)

cat(proc.time() - ptm, '\\n')
}

}
\references{
\url{http://healthcareai-r.readthedocs.io}
}
\seealso{
\code{\link{selectData}}

\code{\link{healthcareai}}
}
\keyword{datasets}
