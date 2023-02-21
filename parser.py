import pandas as pd
import glob

# Get a list of all CSV files in the current directory
csv_files = glob.glob("*.csv")

# Create a new Excel workbook
writer = pd.ExcelWriter('output.xlsx')

# Loop through each CSV file and add it to the workbook as a new sheet
for csv_file in csv_files:
    # Read the CSV file into a pandas DataFrame
    df = pd.read_csv(csv_file)

    # Get the filename without the .csv extension
    sheet_name = csv_file[:-4]

    # Add the DataFrame to the workbook as a new sheet with the filename as the sheet name
    df.to_excel(writer, sheet_name=sheet_name, index=False)

# Save the workbook
writer.save()
