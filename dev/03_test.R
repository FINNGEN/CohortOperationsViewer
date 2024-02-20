
# Run the app 

devtools::load_all(".")
run_app(
  options = list(port = 8080, launch.browser = TRUE)
  )



# Run modules independently
# find the codes for each module in tests/testmanual/test-mod_<module>.R