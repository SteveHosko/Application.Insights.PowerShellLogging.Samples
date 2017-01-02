$appInsightsKey = "27bc62d8-b4c5-4e00-b7cf-404b82f7affc"
function write-logs
{
param
(
[Parameter(Mandatory)]
[string]$AIKey,
[Parameter(Mandatory,ValueFromPipeline)]
$inputobject,
[switch]$Print
)
$scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
$ai = "$scriptpath\Microsoft.ApplicationInsights.dll"
[Reflection.Assembly]::LoadFile($ai) | Out-Null
$telclient = New-Object "Microsoft.ApplicationInsights.TelemetryClient"
$telclient.InstrumentationKey = $AIKey
$type = (Get-Member -InputObject $inputobject).TypeName[0]
if(($type) -like "System.Management.Automation.error*")
  {
    $TelException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"
    $TelException.Exception = $_.Exception
    $TelClient.TrackException($TelException)
    $TelClient.Flush()
    if($Print){$inputobject}
  }
elseif(($type) -like "System.Management.Automation.info*")
  {
    $telclient.TrackEvent("[$(([datetime]::now).ToLongTimeString())]" + $inputobject.Messagedata + ", in script:" + $inputobject.Source)
    $telclient.Flush()
    if($Print){$inputobject}
  }
elseif(($type) -like "System.Management.Automation.*")
  {
    #$inputobject
    $telclient.TrackEvent("[$(([datetime]::now).ToLongTimeString())]" + $inputobject.Message + ", in script:" + $inputobject.InvocationInfo.ScriptName)
    $telclient.Flush()
    if($Print){$inputobject}
  }
else
  {
    $inputobject
  }
}

function Write-ToStreams
{
    [cmdletbinding()]
    Param()
    Begin
    {
        $VerbosePreference = 'Continue'
        $DebugPreference = 'Continue'
    }
    Process
    {
        Write-Host "This is written to host" -ForegroundColor Green
        Write-Output "This is written to Success output"
        Write-Error "This is an error"
        Write-Warning "This is a warning message"
        Write-Verbose "This is verbose output"
        Write-Debug "This is a debug message"
    }
}

Write-ToStreams *>&1 | ForEach-Object{write-logs -inputobject $_ -AIKey $appInsightsKey -Print}