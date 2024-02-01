

# Specs for what a results file should look like

The file with resutls must be a zip file containing the following files:

- analisysSettings.yaml [mandatory]: a yaml file with the settings used for the analysis, it must at least have a parameter in the higest level called `analysisName` with the name of the analysis. This name is used to decide how to load and visualise the data. 


- <>.csv [optional]: one or more csv files with the results of the analysis. 


the description for the tables must exist in the ins folde
table are checked for consistency with the description in the ins folder
the upload into a sqlite database 

module takes as input 

the settings file
connection hadlert to the sqlite database

