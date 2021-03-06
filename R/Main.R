# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of CVDRiskPredictionByDeepLearning
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute the Study
#'
#' @details
#' This function executes the CVDRiskPredictionByDeepLearning Study.
#' 
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cdmDatabaseName      Shareable name of the database 
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the target population cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param createCohorts        Create the cohortTable table with the target population and outcome cohorts?
#' @param runAnalyses          Run the model development
#' @param runTemporalAnalyses          Run the temporal model development
#' @param createValidationPackage  Create a package for sharing the models 
#' @param packageResults       Should results be packaged for later sharing?     
#' @param minCellCount         The minimum number of subjects contributing to a count before it can be included 
#'                             in packaged results.
#' @param cdmVersion           The version of the common data model                             
#'
#' @examples
#' \dontrun{
#' connectionDetails <- createConnectionDetails(dbms = "postgresql",
#'                                              user = "joe",
#'                                              password = "secret",
#'                                              server = "myserver")
#'
#' execute(connectionDetails,
#'         cdmDatabaseSchema = "cdm_data",
#'         cdmDatabaseName = 'shareable name of the database'
#'         cohortDatabaseSchema = "study_results",
#'         cohortTable = "cohort",
#'         oracleTempSchema = NULL,
#'         outputFolder = "c:/temp/study_results", 
#'         createCohorts = T,
#'         runAnalyses = T,
#'         createValidationPackage = T,
#'         packageResults = F,
#'         minCellCount = 5,
#'         cdmVersion = 5)
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cdmDatabaseName = 'friendly database name',
                    cohortDatabaseSchema = cohortDatabaseSchema,
                    cohortTable = "cohort",
                    oracleTempSchema = NULL,
                    outputFolder,
                    createCohorts = TRUE,
                    runAnalyses = T,
                    runTemporalAnalyses = FALSE,
                    createValidationPackage = TRUE,
                    packageResults = TRUE,
                    minCellCount= 5,
                    cdmVersion = 5,
                    sampleSize=NULL) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)

  if (createCohorts) {
    OhdsiRTools::logInfo("Creating cohorts")
    createCohorts(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohortTable,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = outputFolder)
    
    ##Add 179 days to the cohort_start_date of target
    # connection<-DatabaseConnector::connect(connectionDetails)
    # sql<-"UPDATE @target_database_schema.@target_cohort_table
    #       SET cohort_start_date = DATEADD(DAY,179,cohort_start_date)
    #       where cohort_definition_id = @target_cohort_id"
    # sql<-SqlRender::renderSql(sql,
    #                           target_database_schema = cohortDatabaseSchema,
    #                           target_cohort_table = cohortTable,
    #                           target_cohort_id = 873)$sql
    # sql <- SqlRender::translateSql(sql,
    #                                targetDialect=connectionDetails$dbms)$sql
    # DatabaseConnector::executeSql(connection,sql)
  }
  
  if(runAnalyses){
  OhdsiRTools::logInfo("Running predictions")
  predictionAnalysisListFile <- system.file("settings",
                                            "predictionAnalysisList.json",
                                            package = "CVDRiskPredictionByDeepLearning")
  predictionAnalysisList <- PatientLevelPrediction::loadPredictionAnalysisList(predictionAnalysisListFile)
  predictionAnalysisList$connectionDetails = connectionDetails
  predictionAnalysisList$cdmDatabaseSchema = cdmDatabaseSchema
  predictionAnalysisList$cdmDatabaseName = cdmDatabaseName
  predictionAnalysisList$oracleTempSchema = oracleTempSchema
  predictionAnalysisList$cohortDatabaseSchema = cohortDatabaseSchema
  predictionAnalysisList$cohortTable = cohortTable
  predictionAnalysisList$outcomeDatabaseSchema = cohortDatabaseSchema
  predictionAnalysisList$outcomeTable = cohortTable
  predictionAnalysisList$cdmVersion = cdmVersion
  predictionAnalysisList$outputFolder = file.path(outputFolder,"nontemporal")
  
  result <- do.call(PatientLevelPrediction::runPlpAnalyses, predictionAnalysisList)
  }
  if (runTemporalAnalyses){
  # temporalPredictionAnalysisListFile <- system.file("settings",
  #                                           "temporalPredictionAnalysisList.json",
  #                                           package = "CVDRiskPredictionByDeepLearning")
  # temporalPredictionAnalysisList <- PatientLevelPrediction::loadPredictionAnalysisList(temporalPredictionAnalysisListFile)
  # temporalPredictionAnalysisList$connectionDetails = connectionDetails
  # temporalPredictionAnalysisList$cdmDatabaseSchema = cdmDatabaseSchema
  # temporalPredictionAnalysisList$cdmDatabaseName = cdmDatabaseName
  # temporalPredictionAnalysisList$oracleTempSchema = oracleTempSchema
  # temporalPredictionAnalysisList$cohortDatabaseSchema = cohortDatabaseSchema
  # temporalPredictionAnalysisList$cohortTable = cohortTable
  # temporalPredictionAnalysisList$outcomeDatabaseSchema = cohortDatabaseSchema
  # temporalPredictionAnalysisList$outcomeTable = cohortTable
  # temporalPredictionAnalysisList$cdmVersion = cdmVersion
  # temporalPredictionAnalysisList$outputFolder = file.path(outputFolder,"temporal")
  # 
  # temporalResult <- do.call(PatientLevelPrediction::runPlpAnalyses, temporalPredictionAnalysisList)
    if (!file.exists(file.path(outputFolder,"Analysis_CIReNN"))){
      dir.create(file.path(outputFolder,"Analysis_CIReNN"))
    } 
    
    initialstartDay = -3650
    initialendDay = -1826
    startDay = -1825
    dayInterval= 360
    
    startDays = c(initialstartDay, seq(from=startDay,length.out=abs(startDay)/dayInterval, by = dayInterval))
    endDays = c(initialendDay, seq(from=startDay+dayInterval-1,length.out=abs(startDay)/dayInterval, by = dayInterval))
    endDays[length(endDays)]<-0
    startDays<-c(startDays,1,91)
    endDays<-c(endDays,90,180)
    
    temporalCovariateSettings <- FeatureExtraction::createTemporalCovariateSettings(useConditionOccurrence = TRUE,
                                                                                    useDrugExposure = TRUE,
                                                                                    useProcedureOccurrence = TRUE, 
                                                                                    useDeviceExposure = TRUE,
                                                                                    useMeasurement = TRUE, 
                                                                                    useMeasurementValue = TRUE,
                                                                                    useMeasurementRangeGroup = TRUE, 
                                                                                    useObservation = TRUE,
                                                                                    temporalStartDays = startDays, 
                                                                                    temporalEndDays = endDays,
                                                                                    includedCovariateConceptIds = c(), 
                                                                                    addDescendantsToInclude = FALSE,
                                                                                    excludedCovariateConceptIds = c(), 
                                                                                    addDescendantsToExclude = FALSE,
                                                                                    includedCovariateIds = c())
    temporalPlpData<-PatientLevelPrediction::getPlpData(connectionDetails, 
                                                        cdmDatabaseSchema,
                                                        oracleTempSchema = oracleTempSchema, 
                                                        cohortId=873, 
                                                        outcomeIds=756,#list(3,1430),
                                                        studyStartDate = "", 
                                                        studyEndDate = "",
                                                        cohortDatabaseSchema = cohortDatabaseSchema, 
                                                        cohortTable = cohortTable,
                                                        outcomeDatabaseSchema = cohortDatabaseSchema, 
                                                        outcomeTable = cohortTable,
                                                        cdmVersion = "5", 
                                                        excludeDrugsFromCovariates = F,
                                                        firstExposureOnly = FALSE, 
                                                        washoutPeriod = 0, 
                                                        sampleSize = sampleSize,
                                                        temporalCovariateSettings)
    #PatientLevelPrediction::savePlpData(temporalPlpData,file.path(outputFolder,"Analysis_CIReNN"))
    temporalPopulation<-PatientLevelPrediction::createStudyPopulation(temporalPlpData, 
                                                                      population = NULL, 
                                                                      binary = TRUE,
                                                                      outcomeId=756,
                                                                      includeAllOutcomes = T, 
                                                                      firstExposureOnly = FALSE, 
                                                                      washoutPeriod = 0,
                                                                      removeSubjectsWithPriorOutcome = TRUE, 
                                                                      priorOutcomeLookback = 99999,
                                                                      requireTimeAtRisk = TRUE, 
                                                                      minTimeAtRisk = 1824, 
                                                                      addExposureDaysToStart = FALSE, 
                                                                      riskWindowStart = 1,
                                                                      addExposureDaysToEnd = FALSE,
                                                                      riskWindowEnd = 1825)

    CIReNNSetting<-PatientLevelPrediction::setCIReNN(numberOfRNNLayer = c(1,2,3),units=c(64,128), recurrentDropout=c(0.3,0.4),layerDropout = c(0.4,0.5),
                                                     lr =c(1e-4), decay=c(1e-5), 
                                                     outcomeWeight = c(12.0),
                                                     batchSize = c(200), 
                                                     epochs = c(100),
                                                     earlyStoppingMinDelta = c(1e-03), earlyStoppingPatience = c(6),
                                                     useVae =T, vaeDataSamplingProportion = 1.0, vaeValidationSplit = 0.3,
                                                     vaeBatchSize = 100L, vaeLatentDim = 256, vaeIntermediateDim = 1024L,
                                                     vaeEpoch = 3000L, vaeEpislonStd = 1.0, seed = NULL)
    
    CIReNNModel <- PatientLevelPrediction::runPlp(temporalPopulation,
                                                  temporalPlpData,
                                                  minCovariateFraction = 0.001,
                                                  modelSettings = CIReNNSetting,
                                                  testSplit = "person",
                                                  testFraction = 0.3,
                                                  nfold = 2,
                                                  saveDirectory =  file.path(outputFolder,"Analysis_CIReNN"))
    PatientLevelPrediction::savePlpModel(CIReNNModel$model,dirPath = file.path(outputFolder,"Analysis_CIReNN"))
    PatientLevelPrediction::savePlpResult(CIReNNModel,file.path(outputFolder,"Analysis_CIReNN"))
    
  }
  
  if (packageResults) {
    OhdsiRTools::logInfo("Packaging results")
    packageResults(outputFolder = outputFolder,
                   minCellCount = minCellCount)
  }
  
  if(createValidationPackage){
    predictionAnalysisListFile <- system.file("settings",
                "predictionAnalysisList.json",
                package = "CVDRiskPredictionByDeepLearning")
    jsonSettings <-  tryCatch({rjson::fromJSON(file=predictionAnalysisListFile)},
                                        error=function(cond) {
                                          stop('Issue with json file...')
                                        })
    jsonSettings$skeletonType <- 'SimpleValidationStudy'
    jsonSettings$packageName <- paste0(jsonSettings$packageName,'Validation')
    
    createValidationPackage(modelFolder = outputFolder, 
                            outputFolder = file.path(outputFolder, jsonSettings$packageName),
                            minCellCount = minCellCount,
                            databaseName = cdmDatabaseName,
                            jsonSettings = jsonSettings )
  }
  
  
  invisible(NULL)
}




