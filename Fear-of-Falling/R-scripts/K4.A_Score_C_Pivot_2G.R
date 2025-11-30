########################################################################################################
# KAAOS 4.A: R Script for Recoding & Transposing Score Change Data: Performance Tests by Fear of Falling
#
# [K4.A_Score_C_Pivot_2G.R]
#
# "This script loads a CSV with original performance based test values, recodes performance test names 
#  by fear of falling status, transposes data, renames columns, and saves the final output."
########################################################################################################

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Load the required libraries
# 2: Load the original data from CSV (with original values)
# 3: Modify test names based on 'kaatumisenpelkoOn' values
# 4: Rename the 'Test' column to 'Performance_Test'
# 5: Remove the 'kaatumisenpelkoOn' column
# 6: Ensure the 'Performance_Test' values are unique
# 7: Convert the 'Performance_Test' column into row names
# 8: Transpose the data frame
# 9: Add the original row names as a 'Parameter' column
# 10: Rename the transposed columns with clear group labels
# 11: Save the transposed table to CSV format
# 12: Print the file location as confirmation
# 13: (Optional) Check the final table
########################################################################################################
########################################################################################################

# 1: Load the required libraries
library(dplyr)
library(tidyr)
library(readr)
library(tibble)  # Needed to convert row names into a column

# 2: Load the original data from CSV (with original values)
file_path <- "C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote/tables/K3_Values_2G.csv"
df <- read_csv(file_path)

# 3: Modify test names based on the value of 'kaatumisenpelkoOn'
df <- df %>%
  mutate(Test = case_when(
    Test == "Kävelynopeus" & kaatumisenpelkoOn == 0 ~ "MWS_Without_FOF",
    Test == "Kävelynopeus" & kaatumisenpelkoOn == 1 ~ "MWS_With_FOF",
    Test == "Puristusvoima" & kaatumisenpelkoOn == 0 ~ "HGS_Without_FOF",
    Test == "Puristusvoima" & kaatumisenpelkoOn == 1 ~ "HGS_With_FOF",
    Test == "Seisominen" & kaatumisenpelkoOn == 0 ~ "SLS_Without_FOF",
    Test == "Seisominen" & kaatumisenpelkoOn == 1 ~ "SLS_With_FOF",
    Test == "Tuoliltanousu" & kaatumisenpelkoOn == 0 ~ "FTSST_Without_FOF",
    Test == "Tuoliltanousu" & kaatumisenpelkoOn == 1 ~ "FTSST_With_FOF",
    TRUE ~ Test
  ))

# 4: Rename the 'Test' column to 'Performance_Test'
df <- df %>% rename(Performance_Test = Test)

# 5: Remove the original 'kaatumisenpelkoOn' column
df <- df %>% select(-kaatumisenpelkoOn)

# 6: Ensure the 'Performance_Test' values are unique
df <- df %>% mutate(Performance_Test = make.unique(as.character(Performance_Test)))

# 7: Convert the 'Performance_Test' column into row names
df_transposed <- df %>%
  column_to_rownames(var = "Performance_Test")

# 8: Transpose the data frame
df_transposed <- as.data.frame(t(df_transposed))

# 9: Add the original row names as a 'Parameter' column
df_transposed <- df_transposed %>%
  rownames_to_column(var = "Parameter")

# 10: Rename the transposed columns to have clear group labels
#    Adjust these as needed if the original CSV used different factor names
df_transposed <- df_transposed %>%
  rename(
    FTSST_Without_FOF = "FTSST",
    HGS_Without_FOF   = "HGS",
    MWS_Without_FOF   = "MWS",
    SLS_Without_FOF   = "SLS",
    FTSST_With_FOF    = "FTSST.1",
    HGS_With_FOF      = "HGS.1",
    MWS_With_FOF      = "MWS.1",
    SLS_With_FOF      = "SLS.1"
  )

# 11: Save the new transposed table in CSV format
output_path <- "C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote/tables/K4_Score_Change_2G_Transposed.csv"
write_csv(df_transposed, output_path)

# 12: Print the file location as confirmation
print(paste("File saved at:", output_path))

# 13: (Optional) Check the final table
# View(df_transposed)
