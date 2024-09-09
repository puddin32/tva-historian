This script retrieves data from a REST API for multiple servers and point IDs, and saves the responses and status messages to separate files.

.DESCRIPTION
The script does the following:

1. Defines the base URL for the API, an array of server names, and an array of point IDs.
2. Creates a timestamped folder on the desktop to store the output files.
3. Loops through each server:
   - Tests the API with the first point ID. If the test fails, it skips to the next server.
   - Creates a subfolder for each server if it doesn't already exist.
   - Initializes two empty arrays to store the API responses and status messages.
   - Loops through the point IDs in chunks of a specified size. For each chunk, it makes a GET request to the API endpoint that corresponds to the current server and point ID. The response from each request is added to the responses array, and a status message is added to the status messages array.
4. After all the API requests for a chunk have been made, it saves the responses and status messages to separate JSON files in the server's subfolder. The filenames include the server name, either "MetaData" or "StatusMessages", and the range of point IDs in the chunk.
5. Clears the arrays for the next chunk.

.PARAMETER baseApiUrl
The base URL for the API.

.PARAMETER servers
An array of server names.

.PARAMETER pointIdsSize
The size of the array of point IDs. This is the last point ID to check.

.PARAMETER chunkSize
The size of the chunks to divide the array of point IDs into. This is used to save a file during the loop to avoid losing data.

.INPUTS
None. You cannot pipe objects to this script.

.OUTPUTS
None. This script does not return any output.

.NOTES
Please replace the baseApiUrl, servers, and pointIdsSize with your actual values.
