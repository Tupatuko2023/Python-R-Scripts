install.packages("renv")
renv::init()
install.packages(c("lintr","testthat","styler"))
renv::snapshot()   
source("docs/SYNTHETIC_DEMO/demo_r.R")
renv::snapshot() # luo/paivittaa renv.lock
# renv::restore()