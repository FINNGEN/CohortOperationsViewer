
# Run the app

devtools::load_all(".")
run_app(
  pathToCohortOperationsConfigYalm = testthat::test_path("config", "cohortOperationsConfig.yml"),
  options = list(port = 9998, launch.browser = TRUE)
)



# Run modules independently
# find the codes for each module in tests/testmanual/test-mod_<module>.R
