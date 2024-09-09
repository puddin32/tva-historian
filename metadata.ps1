# Define the API root
$baseApiUrl = "http://historian.tva.gov"

# Define your array of servers
##$servers =  @("server1","server2")
%servers = @("TP")

# Define your start and end pointids
$startPointId = 1
$endPointId = 10000

# Create an array of pointids from start to end
$pointidArray = @( $startPointId..$endPointId )

# Define the character limit
$characterLimit = 249

# Define the headers for the REST API call
$headers = @{
    "Accept" = "application/json"
}

# Create a timestamped folder on the desktop
$timestamp = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$resultsPath = Join-Path -Path $desktopPath -ChildPath $timestamp
New-Item -Path $resultsPath -ItemType Directory

# Loop through each server. If you don't have access (i.e. get an error) then skp the server.
foreach ($server in $servers) {
    # Test the server connection
    $testurl = "$baseApiUrl/$server/rest/help"
    try {
        $testResponse = Invoke-RestMethod -Uri $testurl -Method Get -ErrorAction Stop -UseDefaultCredentials
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

    # Initialize the starting index for the pointidArray
    $startIndex = 0

    # Loop through the pointidArray to create chunks
    while ($startIndex -lt $pointidArray.Count) {
        # Initialize the chunk size
        $chunkSize = 0
        $charCount = 0

        # Calculate the chunk size based on the character limit
        while ($charCount -lt $characterLimit -and $startIndex + $chunkSize -lt $pointidArray.Count) {
            $charCount += $pointidArray[$startIndex + $chunkSize].ToString().Length + 1 # +1 for the comma
            $chunkSize++
        }

        # Get the chunk of pointids
        $chunk = $pointidArray[$startIndex..($startIndex + $chunkSize - 1)]

        # Increment the start index by the chunk size
        $startIndex += $chunkSize

        # Join the chunk back into a comma delimited string
        $pointidList = $chunk -join ','

        # Define the REST API URL
        $url = "$baseApiUrl/$server/rest/read/metadata/$pointidList"

        # Make the REST API call with the headers
        $response = Invoke-RestMethod -Uri $url -Headers $headers -UseDefaultCredentials

        # Define the output file path with the server name and first and last point of the chunk
        $firstPoint = $chunk[0]
        $lastPoint = $chunk[-1]
        $outputFile = Join-Path -Path $serverPath -ChildPath "$server-output-$firstPoint-$lastPoint.json"

        # Convert the response to JSON and write to the output file
        $response | ConvertTo-Json | Out-File -FilePath $outputFile
    }
}
