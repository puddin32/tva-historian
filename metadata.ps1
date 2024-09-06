# Define the API root
$baseApiUrl = "http://historian.tva.gov"

# Define your array of servers
##$servers = @("AC","AK","AT","BT","CC","CT","CU","GA","GC","GT","HY","JC","JT","KI","KT","LC","LT","MC","MT","PC","SC","SH")
$servers =  @("TP")
# Define your start and end pointids
$startPointId = 1
$endPointId = 1000

# Define how many points we want to store in each file
$pointsPerFile = 2000

# Define how many points will be reqeusted at once. This is to avoid errors with url character limits.
$chunkSize = 20

# Create an array of pointids from start to end
$pointidArray = @( $startPointId..$endPointId )

# Define the headers for the REST API call
$headers = @{
    "Accept" = "application/json"
}

# Create a timestamped folder on the desktop
$timestamp = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$resultsPath = Join-Path -Path $desktopPath -ChildPath $timestamp
New-Item -Path $resultsPath -ItemType Directory

# Loop through each server
foreach ($server in $servers) {
    # Test the server connection
    $testurl = "$baseApiUrl/$server/rest/help"
    try {
        $testResponse = Invoke-RestMethod -Uri $testurl -Method Get -ErrorAction Stop 
    }
    catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 503) {
            Write-Host "The service is unavailable (HTTP 503 error)."
        }
        else {
            Write-Host "An error occurred: $_"
        }
        return
    }
    
    Write-Host "The operation completed successfully."

    # Create a folder for the server in the results folder
    $serverPath = Join-Path -Path $resultsPath -ChildPath $server
    New-Item -Path $serverPath -ItemType Directory

    # Define the output file path
    $outputFile = Join-Path -Path $serverPath -ChildPath "$server-output.json"

    # Initialize an array to store the responses
    $responses = @()

    # Split the pointidArray into chunks of $chunkSize
    $chunks = [System.Linq.Enumerable]::Range(0, $pointidArray.Count) |
    Where-Object { $_ % $chunkSize -eq 0 } |
    ForEach-Object { $pointidArray[$_..($_ + $chunkSize-1)] }

    # Initialize an array to store the responses
    $responses = @()

    # Initialize a counter for the chunks
    $chunkCounter = 0

    # Loop through each chunk of pointids
    foreach ($chunk in $chunks) {
        # Increment the chunk counter
        $chunkCounter++

        # Join the chunk back into a comma delimited string
        $pointidList = $chunk -join ','

        # Define the REST API URL
        $url = "$baseApiUrl/$server/rest/read/metadata/$pointidList"

        # Make the REST API call with the headers
        $response = Invoke-RestMethod -Uri $url -Headers $headers

        # Add the response to the responses array
        $responses += $response

        # If the chunk counter is a multiple of 100, save the responses to a file and clear the responses array
        if ($chunkCounter % $pointsPerFile -eq 0) {
            # Convert the entire responses array to JSON
            $json = $responses | ConvertTo-Json

            # Define the output file path with the chunk counter
            $outputFile = Join-Path -Path $serverPath -ChildPath "$server-output-$chunkCounter.json"

            # Write the JSON to the output file
            $json | Out-File -FilePath $outputFile

            # Clear the responses array
            $responses = @()
        }
    }

    # Save any remaining responses to a file
    if ($responses.Count -gt 0) {
        # Convert the entire responses array to JSON
        $json = $responses | ConvertTo-Json

        # Define the output file path with the chunk counter
        $outputFile = Join-Path -Path $serverPath -ChildPath "$server-output-$chunkCounter.json"

        # Write the JSON to the output file
        $json | Out-File -FilePath $outputFile
    }
}
