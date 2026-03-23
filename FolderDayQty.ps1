#---  FolderDayQty.ps1 ---
#  List the top 15 folders sorted by date (decending) and 
#  a count of the number of files in each folder.
#
#  Shared online:	https://pastebin.com/KwZQk3uh
# 					https://www.facebook.com/groups/maxtom3/posts/7992261460846946/
#   				https://www.facebook.com/groups/maxtom3/posts/34348792078100525
#
#  This is used by Archive_M3_MOVIE_EF.bat, https://pastebin.com/LT5XESs0
#  File	 generated with Phind.com AI
#  Configured by Ben Sacherich - 11/19/2023
#  Updated 1/28/2024 to sort dates as dates and not as strings.

param(
    [string]$SourceFolder = ""
)
# $SourceFolder = "F:\CARDV\PHOTO"

if (-not (Test-Path $SourceFolder -PathType Container)) {
    Write-Host "Source folder not found: $SourceFolder"
    exit 1
}

# Get all files in the source folder
$files = Get-ChildItem -Path $SourceFolder

# Create a hashtable to store counts based on date
$dateCounts = @{}

# Loop through each file
foreach ($file in $files) {
    # Get the date without the time
	$date = $file.LastWriteTime.Date
	# Write-Host $date

    # Check if the date is already in the hashtable
    if ($dateCounts.ContainsKey($date)) {
        # Increment the count for the date
        $dateCounts[$date]++
    } else {
        # Add the date to the hashtable with a count of 1
        $dateCounts[$date] = 1
    }
}

# Sort the hashtable by keys in descending order
$sortedDates = $dateCounts.GetEnumerator() | Sort-Object -Property Name -Descending

# Select the top 15 dates
$top5Dates = $sortedDates | Select-Object -First 15

# Display the counts for these dates and the number of days back they are from today
Write-Host "Days`tMedia Date`tFiles"
foreach ($date in $top5Dates) {
    $count = $dateCounts[$date.Name]
	$daysBack = (Get-Date).Subtract($date.Name).Days
	Write-Host "$daysBack`t$($date.Name.ToString('MM/dd/yyyy'))`t$count"
}

exit
