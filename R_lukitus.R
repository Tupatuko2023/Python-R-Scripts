install.packages("renv")
renv::init()
renv::install(c("lintr","testthat","styler"))renv::snapshot()
source("docs/SYNTHETIC_DEMO/demo_r.R")
renv::snapshot() # luo/paivittaa renv.lock
# renv::restore()