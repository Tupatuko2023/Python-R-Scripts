# Reproducibility

## Python
- env\environment.yml defines Python 3.11 and libs [TODO list exact]
`powershell
conda env create -f env\environment.yml
conda activate efi
python --version
pip freeze > env\python-freeze.txt
`",
",

`
install.packages("renv")
renv::init()
# renv::snapshot() after installs
writeLines(capture.output(sessionInfo()), "env/R-sessionInfo.txt")
`",
",

- Set random seeds in demos [TODO]
- Commit env files to version control

## Data access
- Repo contains only synthetic data
- Real data requires approvals [TODO link to policy]