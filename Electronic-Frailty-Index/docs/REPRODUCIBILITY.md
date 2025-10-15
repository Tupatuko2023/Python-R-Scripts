# Reproducibility

This document explains how to reproduce results produced by the EFI module.

## Environments and versions

- OS: Windows 10 or 11
- Python: defined in `Electronic-Frailty-Index/env/environment.yml`
- Optional R: 4.x - required only if running R notebooks or Quarto docs that call R
- Quarto: 1.8.x if rendering reports
- Node: LTS - only for markdownlint and CI

### Create the environment

### powershell

Set-Location C:\GitWork\Python-R-Scripts
conda env create -f .\\Electronic-Frailty-Index\env\environment.yml
conda activate efi_env

###

To capture exact packages for archiving:

``powershell
conda env export --n_-builds > .\\Electronic-Frailty-Index\env\environment.lock.yml

```powershell

If using pip:

``powershell
pip freeze > .\\Electronic-Frailty-Index\env\requirements.lock.txt
```

## Randomness and seeds

Set a global seed for any code that uses randomness.

Python example:

``python
import os, random, numpy as np
SEED = int(os.getenv("EFI_SEED", "20241015"))
random.seed(SEED, args=())
np.random.seed(SEED, args=())

## if using torch

## import torch; torch.manual_seed(SEED); torch.cuda.manual_seed_all(SEED)
