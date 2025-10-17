
# Reproducibility

## Python

- `env/environment.yml` defines Python 3.11 and libraries [TODO: list exact].

```powershell
conda env create -f env/environment.yml
conda activate efi
python --version
pip freeze > env/python-freeze.txt
```

## R

```r
install.packages("renv")
renv::init()
# After installing packages:
renv::snapshot()
writeLines(capture.output(sessionInfo()), "env/R-sessionInfo.txt")
```

## Randomness

- Set random seeds in demos and notebooks. Add exact calls where needed.
- Examples:

```python
# Python
import random, numpy as np
random.seed(42)
np.random.seed(42)
# if you use PyTorch:
# import torch
# torch.manual_seed(42)
```

```r
# R
set.seed(42)
```

## Data access

- Repository contains only synthetic data.
- Access to real data requires approvals and agreements [TODO: link to policy].
- Scripts to access data are in `docs/SYNTHETIC_DEMO` folder.
