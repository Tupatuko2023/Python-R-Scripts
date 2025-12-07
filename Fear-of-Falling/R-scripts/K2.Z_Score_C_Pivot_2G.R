# KAAOS 2: R Script for Recoding & Transposing Z-Score Change Data: Performance Tests by Fear of Falling Status 
# [K2.Z_Score_C_Pivot_2G.R]

# "This script loads a z-score CSV, recodes performance test names by fear of falling, 
#  transposes data, renames columns & saves final output in analysis."

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Install and load required packages and libraries.
# 2: Load the original CSV data file.
# 3: Modify test names based on 'kaatumisenpelkoOn' values.
# 4: Rename the 'Test' column to 'Performance_Test'.
# 5: Remove the original 'kaatumisenpelkoOn' column.
# 6: Ensure the 'Performance_Test' values are unique.
# 7: Convert the 'Performance_Test' column into row names.
# 8: Transpose the data frame.
# 9: Add the original column names as a 'Parameter' column.
# 10: Rename transposed columns with clear group labels.
# 11: Save the new transposed table to CSV format.
# 12: Print the file save location as confirmation.
# 13: View the final transposed table.

########################################################################################################
########################################################################################################

# Install and load the required packages
# Install and load the necessary packages
# install.packages("ggplot2")  # For visualization
# install.packages("dplyr")    # For data manipulation
# install.packages("tidyr")    # For converting to long format
# install.packages("boot")     # For calculating confidence intervals
# install.packages("haven")
# install.packages("tidyverse")
# install.packages("tibble")
# install.packages("readr")

# 1: Load the required libraries
library(dplyr)
library(tidyr)
library(readr)
library(tibble)  # Needed to convert row names into a column

# 2: Load the original data
file_path <- "C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote/tables/K1_Z_Score_Change_2G.csv"
df <- read_csv(file_path)

# 3: Modify the test names based on the value of 'kaatumisenpelkoOn'

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
    TRUE ~ Test  # Leave other names unchanged
  ))

# 4: Rename the 'Test' column to 'Performance_Test'
df <- df %>% rename(Performance_Test = Test)

# 5: Remove the original "kaatumisenpelkoOn" column, as its info is now in the "Performance_Test" names
df <- df %>% select(-kaatumisenpelkoOn)

# 6: Ensure the Performance_Test values are unique
df <- df %>% mutate(Performance_Test = make.unique(as.character(Performance_Test)))

# 7: Convert the "Performance_Test" column into row names
df_transposed <- df %>%
  column_to_rownames(var = "Performance_Test")  # Move performance test names into row names

# 8: Transpose the table
df_transposed <- as.data.frame(t(df_transposed))

# 9: Add the original column names as the first column
df_transposed <- df_transposed %>%
  rownames_to_column(var = "Parameter")  # Convert the row names into a column

# 10: Rename the transposed columns to have clear group labels
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

# 11: Save the new vertical table in CSV format
output_path <- "C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote/tables/K2_Z_Score_Change_2G_Transposed.csv"
write_csv(df_transposed, output_path)

# 12: Print the file location as confirmation
print(paste("File saved at: ", output_path))

# 13: Check the final table
View(df_transposed)
