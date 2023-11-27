$script:CommitRange
$script:OutFileName
$script:NullDevice = ($PSVersionTable.Platform -like "WIN*") ? "NUL" : "/dev/null"
$script:CurrentDirectory = Split-Path -Leaf -Path .

function ConvertFrom-GitLog
{
    [CmdletBinding()]
    Param
    (
        [string] $Since,
        [string] $Until,
        [ValidateSet("text", "markdown")]
        $Format = "markdown"
    )
    
    Begin
    {
        # Check if current directory support git
        if (! $(Test-Path .git))
        {
            Write-Error -ErrorAction Stop `
            "Current directory is not a valid Git repo."
        }

        # Validate commit range
        if (($Since -eq [string]::Empty) -and ($Until -eq [string]::Empty))
        {
            Write-Error -ErrorAction Stop `
            "At least one of these options must be given: -Since or -Until"
        }
        
        if ($Until -eq [string]::Empty) 
        {
            $script:CommitRange = "$Since..HEAD"
            $script:OutFileName = "CHANGELOG-$Since-HEAD.md"
        }
        elseif ($Since -eq [string]::Empty)
        {
            $script:CommitRange = "$Until"
            $script:OutFileName = "CHANGELOG-$Until.md"
        }
        else
        {
            $script:CommitRange = "$Since..$Until"
            $script:OutFileName = "CHANGELOG-$Since-$Until.md"
        }

        if ($VerbosePreference -eq [System.Management.Automation.ActionPreference]::Continue)
        {
            $VerboseOutput = @{}
            $VerboseOutput.Add("COMMIT RANGE"  , ${script:CommitRange})
            $VerboseOutput.Add("FILE NAME"     , ${script:OutFileName})
            $VerboseOutput.Add("GIT REPO"      , ${script:CurrentDirectory})
            $VerboseOutput.Add("OUTPUT FORMAT" , $Format)
            $VerboseOutput | Format-Table
        }
    }

    Process
    {
        if ($Format -eq "markdown")
        {
            $gitlog = Invoke-Expression `
            'git log --no-merges --format="| %h | %ad | %an | %s |" --date=short ${script:CommitRange} 2> ${script:NullDevice}'

            Write-Verbose "Writing file $script:OutFileName..."
            Write-Output "## changelog for git repo: ``$(Get-Location | Split-Path -Leaf)``" > $script:OutFileName
            Write-Output "| COMMIT ID | COMMIT DATE | AUTHOR | COMMIT MSG. |" >> $script:OutFileName
            Write-Output "| --- | --- | --- | --- |" >> $script:OutFileName
            Write-Output $gitlog >> $script:OutFileName
        }

        if ($Format -eq 'text')
        {
            $NativeCommand = "git log --no-merges --format=""%h|%ad|%an|%s|"" --date=short ${script:CommitRange} 2> ${script:NullDevice}"
            Write-Debug "Git command -> $NativeCommand"
            $GitLog = Invoke-Expression $NativeCommand
            Write-Debug "Output result ->"
            Write-Debug "$GitLog"
            Write-Output "## changelog for git repo: ${script:CurrentDirectory}"
            $GitLog | ConvertFrom-Csv -Delimiter '|' -Header @("COMMIT ID", "DATE", "AUTHOR", "COMMIT MSG")
        }
    }
    <#
    .SYNOPSIS
    ConvertFrom-GitLog convert git-log to markdown format.

    .DESCRIPTION

    .PARAMETER Since
    Commit ID that was extracted from

    .PARAMETER Until
    Commit ID that was extracted to

    .EXAMPLE
    # Get git log between v1.0.0 and v1.0.1
    ConvertFrom-GitLog -Since v1.0.0 -Until v1.0.1

    .EXAMPLE
    # Pring got log from the beginning to v1.0.0
    ConvertFrom-GitLog -Until v1.0.0

    .EXAMPLE
    # Print git log from v1.0.1 to the latest commit
    ConvertFrom-GitLog -Since v1.0.1
    #>
}

Export-ModuleMember ConvertFrom-GitLog