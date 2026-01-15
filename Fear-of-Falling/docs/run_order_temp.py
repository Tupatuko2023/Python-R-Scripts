import csv
from pathlib import Path

rows = [
    ["K1", "R-scripts/K1/K1.7.main.R", "TRUE", "K1_MAIN.V1_zscore-change.R", "", "data/external/KaatumisenPelko.csv (via K1.1)", "R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv", "Rscript R-scripts/K1/K1.7.main.R", "Legacy K1 pipeline"],
    ["K2", "R-scripts/K2/K2.Z_Score_C_Pivot_2G.R", "TRUE", "K2.V1_zscore-pivot-2g.R", "K1", "R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv", "R-scripts/K2/outputs/K2_Z_Score_Change_2G_Transposed.csv", "Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R", "Legacy K2 transpose"],
    ["K3", "R-scripts/K3/K3.7.main.R", "TRUE", "K3_MAIN.V1_original-values.R", "", "data/external/KaatumisenPelko.csv (via K1.1)", "R-scripts/K3/outputs/K3_Values_2G.csv", "Rscript R-scripts/K3/K3.7.main.R", "Legacy K3 original values"],
    ["K4", "R-scripts/K4/K4.A_Score_C_Pivot_2G.R", "TRUE", "K4.V1_values-pivot-2g.R", "K3", "R-scripts/K3/outputs/K3_Values_2G.csv", "R-scripts/K4/outputs/K4_Values_2G_Transposed.csv", "Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R", "Legacy K4 transpose"],
    ["K18_QC", "R-scripts/K18/K18_QC.V1_qc-run.R", "TRUE", "K18_QC.V1_qc-run.R", "", "CLI --data argument", "R-scripts/K18/outputs/K18_QC/qc/", "Rscript R-scripts/K18/K18_QC.V1_qc-run.R --data <path> --shape AUTO", "Stop-the-line QC"],
    ["K15", "R-scripts/K15/K15.R", "TRUE", "K15.R", "", "data/external/KaatumisenPelko.csv", "R-scripts/K15/outputs/K15_frailty_analysis_data.RData", "Rscript R-scripts/K15/K15.R", "Legacy K15 frailty proxy"],
    ["K16", "R-scripts/K16/K16.R", "TRUE", "K16.R", "K15", "R-scripts/K15/outputs/K15_frailty_analysis_data.RData", "R-scripts/K16/outputs/", "Rscript R-scripts/K16/K16.R", "Legacy K16 frailty-adjusted"],
    ["K01_MAIN", "R-scripts/K01_MAIN/K01_MAIN.V1_zscore-change.R", "TRUE", "K01_MAIN.V1_zscore-change.R", "", "data/external/KaatumisenPelko.csv", "R-scripts/K01_MAIN/outputs/", "Rscript R-scripts/K01_MAIN/K01_MAIN.V1_zscore-change.R", "Refactored K1"],
]

fieldnames = ["script_id", "file_path", "verified", "file_tag", "depends_on", "reads_primary", "writes_primary", "run_command", "notes"]

with open("docs/run_order.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(fieldnames)
    writer.writerows(rows)

print("CSV created successfully")
