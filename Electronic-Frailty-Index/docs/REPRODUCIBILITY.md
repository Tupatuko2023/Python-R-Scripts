# Reproducibility

Python
- env\environment.yml defines Python and libs [TODO]
conda env create -f env\environment.yml
conda activate efi

R
install.packages("renv"); renv::init()

Seeds and versions
- Write env\versions.txt [TODO]

Data access
- Only synthetic data in repo