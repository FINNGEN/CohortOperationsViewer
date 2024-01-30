########################################
#### CURRENT FILE: ON START SCRIPT #####
########################################

## activate renv and install usethis
renv::activate()
renv::install("usethis")
renv::install("devtools")
renv::install("golem")

## Fill the DESCRIPTION ----
usethis::use_description(
  fields = list(
    Title = "CohortOperationsViewer",
    Description = "Shiny app to operate cohorts in OMOP format and run analysis",
    `Authors@R` = 'person("Javier", "Gracia-Tabuenca", email = "javier.graciatabuenca@tuni.fi",
                          role = c("aut", "cre"),
                          comment = c(ORCID = "0000-0002-2455-0598"))',
    Language =  "en"
  )
)
usethis::use_mit_license()


## Create Common Files ----
## See ?usethis for more information
usethis::use_readme_rmd( open = FALSE )
#usethis::use_code_of_conduct()
usethis::use_lifecycle_badge( "Experimental" )
usethis::use_news_md( open = FALSE )

## Use git ----
usethis::use_git()
usethis::use_github(private = TRUE)

