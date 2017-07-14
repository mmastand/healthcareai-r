#' Build clusters using kmeans()
#'
#' @description This step allows you to use kmeans() to build clusters, based on
#' your data.
#' @docType class
#' @usage ...
#' @importFrom R6 R6Class
#' @import ranger
#' @import cluster
#' @param object of UnsuperviseModelParameters class for $new() constructor
#' @param dataType The type of your data set('numeric' for all numeric data set,
#' 'categorical' for all categorical data set, and "mixed" for data set that has both
#' numeric and categorical variables)
#' @param df Dataframe whose columns are used for calc.
#' @param newdf Optional. Assign clusters to a new data set. (Currenty only available for kmeans)
#' @param grainCol Optional. The dataframe's column that has IDs pertaining to 
#' the grain. No ID columns are truly needed for this step.
#' @param labelCol Optional. 
#' @param numOfCluster Number of clusters you want to build. 
#' @param impute Set all-column imputation to F or T.
#' This uses mean replacement for numeric columns
#' and most frequent for factorized columns.
#' F leads to removal of rows containing NULLs.
#' @param debug Provides the user extended output to the console, in order
#' to monitor the calculations throughout. Use T or F.
#' @references \url{http://hctools.org/}
#' @seealso \code{\link{LassoDevelopment}}
#' @seealso \code{\link{LinearMixedModelDevelopment}}
#' @seealso \code{\link{healthcareai}}
#' @examples
#'
#' @export

KmeansClustering <- R6Class("KmeansClustering",
                            
  # Inheritance
  inherit = UnsupervisedModel,
  
  # Private members
  private = list(
    # Get kmeans model
    kmeans.fit = NA,
    confusionMatrix = NA,
    
    #check if the data type is numeric
    checkDataType = function() {
      print(self$params$dataType)
      if (self$params$dataType != 'numeric' || isNumeric(self$params$df) == FALSE) {
        stop("Your data type must be numeric in order to use kmeans.")
      }
    }
  ),
  
  # Public members
  public = list(
 
    # Constructor
    # p: new SuperviseModelParameters class object,
    # i.e. p = SuperviseModelParameters$new()
    initialize = function(p) {
      set.seed(43)
      super$initialize(p)
    },
    
    # Remove label col
    # removeLabelCol = function() {
    #   if (nchar(self$params$labelCol) != 0) {
    #     private$labelColValues <- self$params$df[[self$params$labelCol]]
    #     self$params$df[[self$params$labelCol]] <- NULL
    #   }
    # },
    
    
    # Generate the plot to choose the best k    
    elbow_plot = function(){
      df.stand <- scale(self$params$df)
      wss <- (nrow(df.stand) - 1)*sum(apply(df.stand,2,var))
      for (i in 2:15) wss[i] <- sum(kmeans(scale(df.stand),
                                           centers = i)$withinss)
      plot(1:15, wss, type = "b", xlab = "Number of Clusters",
           ylab = "Within groups sum of squares")
    },    
    
    # Override: run k-means algorithm
    buildClusters = function() {
      #self$removeLabelCol()
      # Standarize the variables
      df.stand <- scale(self$params$df)
      # K-Means
      private$kmeans.fit <- kmeans(df.stand, self$params$numOfClusters)
      #print(kmeans.fit)
      return(invisible(private$kmeans.fit))
    },

    getKmeansfit = function() {
      return(private$kmeans.fit)
    },
    
    
    plotClusters = function() {
      df.stand <- scale(self$params$df)
      k.means.fit <- self$getKmeansfit()
      clusplot(df.stand, k.means.fit$cluster, main = '2D representation of the Cluster solution',
             color = TRUE, shade = TRUE, lines = 0)
    },

    # Generate confusion matrix
    calculateConfusion = function() {
      # generate a confusion matrix of clusters and labels
      k.means.fit <- self$getKmeansfit()
      clusters <- k.means.fit$cluster
      labels <- super$getLabelColVal()
      numOfLabels <- length(unique(labels)) - sum(is.na(unique(labels)))
      d <- data.frame(state = labels, cluster = clusters)
      td <- as.data.frame(table(d))
      # convert from raw counts to percentage of each label
      private$confusionMatrix <- matrix(ncol = max(clusters), nrow = 0) # k col
      for (i in 1:numOfLabels) {
        total <- sum(td[td$state == td$state[i],3])
        private$confusionMatrix <- rbind(private$confusionMatrix, td[td$state == td$state[i],3]/total)
      }
      rownames(private$confusionMatrix) <- td[1:numOfLabels,1]
      return(invisible(private$confusionMatrix))
    },
    
    getConfusionMatrix = function() {
      return(private$confusionMatrix)
    },
    
    # Assign labels to the clusters
    assignClusterLabels = function() {
      cm <- self$getConfusionMatrix()
      k <- self$params$numOfClusters
      # take the cluster label from the highest percentage in that column
      cluster.labels <- list()
      for (i in 1:k) {
        cluster.labels <- rbind(cluster.labels, row.names(cm)[match(max(cm[,i]), cm[,i])])
      }
      
      # this may still miss some labels, so make sure all labels are included
      for (l in rownames(cm)) { 
        if (!(l %in% cluster.labels)) 
        { 
          cluster.number <- match(max(cm[l,]), cm[l,])
          cluster.labels[[cluster.number]] <- c(cluster.labels[[cluster.number]], l)
        } 
      }
      return(cluster.labels)
    },
    
    # Plot Silhouette plot
    silhouettePlot = function() {
      dis <- dist(scale(self$params$df), method = "euclidean")
      k.means.fit <- self$getKmeansfit()
      plot(silhouette(k.means.fit$cluster,dis))
    },


    # Override: run k-means algorithm
    run = function() {
      
      # Check data type
      private$checkDataType()
      
      # Build Model
      self$buildClusters()
      
      # Plot the clusters
      # self$plotClusters()
      
      # Present confusion matrix
      self$calculateConfusion()
      
      # self$elbow_plot()
      
      # save model
      #private$saveModel()
    
    }
    
  )
)
