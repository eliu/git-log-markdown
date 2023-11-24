<#
#>

$script:CommitRange
$script:OutFileName
$script:OutFormat

function Write-GitLog
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

        Write-Verbose "The final commit range is ${script:CommitRange}"
        Write-Verbose "Out file name is ${script:OutFileName}"
        Write-Verbose "Output format is ${script:OutFormat}"
    }

    Process
    {
        if ($Format -eq "markdown")
        {
            $gitlog = Invoke-Expression `
            'git log --no-merges --format="| %h | %ad | %an | %s |" --date=short ${script:CommitRange} 2>/dev/null || true'

            Write-Verbose "Writing file $script:OutFileName..."
            Write-Output "## changelog for git repo: ``$(Get-Location | Split-Path -Leaf)``" > $script:OutFileName
            Write-Output "| COMMIT ID | COMMIT DATE | AUTHOR | COMMIT MSG. |" >> $script:OutFileName
            Write-Output "| --- | --- | --- | --- |" >> $script:OutFileName
            Write-Output $gitlog >> $script:OutFileName
        }
    }
}

Export-ModuleMember Write-GitLog