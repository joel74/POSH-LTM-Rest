Function Join-Object {
	[CmdletBinding()]
	[OutputType([int])]
	Param (
		[Parameter(Mandatory=$true)]
		[AllowNull()]
		[object[]] $Left,

		[Parameter(Mandatory=$true)]
		[AllowNull()]
		[object[]] $Right,

		# Property or Expression to use to compare values on the left
		[Alias('OnLeft')]
		[ValidateScript({
			If ($_ -or $Join -eq 'FULL') {
				$True
			} else {
				Throw '-On is required for INNER,LEFT, and RIGHT joins'
			}
		})]
		[String[]] $On={1},

		# Property or Expression to use to compare values on the right
		[Parameter(Mandatory=$false)]
		[String[]] $OnRight=$On,

		[object[]] $LeftProperty,
		[object[]] $RightProperty,

		[Parameter(Mandatory=$false)]
		[ValidateSet('INNER','LEFT','FULL','RIGHT')]
		[string] $Join='INNER',
		[switch] $Force
	)
	begin {
		if ($null -eq $LeftProperty) {
			$LeftProperty = $Left | Select-Object -First 1 | Get-Member -MemberType Properties -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
		}
		if ($null -eq $RightProperty) {
			$RightProperty = $Right | Select-Object -First 1 | Get-Member -MemberType Properties -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
		}
		$AllProperty = $LeftProperty + $RightProperty | Select-Object -Unique

		$LeftGroups = $Left | Group-Object $($On) -AsHashTable -AsString
		$RightGroups = $Right | Group-Object $($OnRight) -AsHashTable -AsString		
	}
	process {
		if ($null -eq $Left -and $null -eq $Right) {
            $null
		} elseif (($null -eq $Left -or $null -eq $Right) -and 'INNER' -eq $Join) {
			$null
		} elseif ($null -eq $Left -and 'RIGHT','FULL' -contains $Join) {
			Write-Warning 'Left object is null, returning Right only'
			$Right | Select-Object -Property $AllProperty -ErrorAction SilentlyContinue
		} elseif ($null -eq $Right -and 'LEFT','FULL' -contains $Join) {
			Write-Warning 'Right object is null, returning Left only'
			$Left | Select-Object -Property $AllProperty -ErrorAction SilentlyContinue
		} else {
			# Output left items
			foreach($key in $LeftGroups.Keys) {
				foreach($leftItem in $leftGroups[$key]) {
					if ($RightGroups.ContainsKey($key)) {
						foreach($rightItem in $RightGroups[$key]) {
							# Matches are output for ALL Joins
							$output = $leftItem | Select-Object -Property $AllProperty
							foreach($p in $RightProperty) {
								$output.$p = $rightItem.$p
							}
							$output
						}
					} else {
						# Left items are output without matches for LEFT and FULL joins
						if ('LEFT' -eq $Join) {
							$leftItem | Select-Object -Property $AllProperty
						}
					}
				}
			}
			# Right items are output without matches for RIGHT and FULL joins
			if ('RIGHT','FULL' -contains $Join) {
				foreach($key in $RightGroups.Keys) {
					if (-not $LeftGroups.ContainsKey($key)) {
						foreach($rightItem in $rightGroups[$key]) {
							$rightItem | Select-Object -Property $AllProperty
						}
					}
				}
			}
		}

	}
<#
.Synopsis
  Join data from two sets of objects based on a common value
.DESCRIPTION
  Join data from two sets of objects based on a common value

  For more details, see the accompanying blog post:
	http://ramblingcookiemonster.github.io/Join-Object/
	https://github.com/RamblingCookieMonster/PowerShell/blob/master/Join-Object.ps1

  For even more details,  see the original code and discussions that this borrows from:
	Dave Wyatt's Join-Object - http://powershell.org/wp/forums/topic/merging-very-large-collections
	Lucio Silveira's Join-Object - http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx

.PARAMETER Left
	'Left' collection of objects to join.  You can use the pipeline for Left.

	The objects in this collection should be consistent.
	We look at the properties on the first object for a baseline.

.PARAMETER Right
	'Right' collection of objects to join.

	The objects in this collection should be consistent.
	We look at the properties on the first object for a baseline.

.PARAMETER LeftJoinProperty
	Property on Left collection objects that we match up with RightJoinProperty on the Right collection

.PARAMETER RightJoinProperty
	Property on Right collection objects that we match up with LeftJoinProperty on the Left collection

.PARAMETER LeftProperties
	One or more properties to keep from Left.  Default is to keep all Left properties (*).

	Each property can:
		- Be a plain property name like 'Name'
		- Contain wildcards like '*'
		- Be a hashtable like @{Name='Product Name';Expression={$_.Name}}.
				Name is the output property name
				Expression is the property value ($_ as the current object)

				Alternatively, use the Suffix or Prefix parameter to avoid collisions
				Each property using this hashtable syntax will be excluded from suffixes and prefixes

.PARAMETER RightProperties
	One or more properties to keep from Right.  Default is to keep all Right properties (*).

	Each property can:
		- Be a plain property name like 'Name'
		- Contain wildcards like '*'
		- Be a hashtable like @{Name='Product Name';Expression={$_.Name}}.
				Name is the output property name
				Expression is the property value ($_ as the current object)

				Alternatively, use the Suffix or Prefix parameter to avoid collisions
				Each property using this hashtable syntax will be excluded from suffixes and prefixes

.PARAMETER Prefix
	If specified, prepend Right object property names with this prefix to avoid collisions

	Example:
		Property Name				   = 'Name'
		Suffix						  = 'j_'
		Resulting Joined Property Name  = 'j_Name'

.PARAMETER Suffix
	If specified, append Right object property names with this suffix to avoid collisions

	Example:
		Property Name				   = 'Name'
		Suffix						  = '_j'
		Resulting Joined Property Name  = 'Name_j'

.PARAMETER Type
	Type of join.  Default is AllInLeft.

	AllInLeft will have all elements from Left at least once in the output, and might appear more than once
		if the where clause is true for more than one element in right, Left elements with matches in Right are
		preceded by elements with no matches.
		SQL equivalent: outer left join (or simply left join)

	AllInRight is similar to AllInLeft.

	OnlyIfInBoth will cause all elements from Left to be placed in the output, only if there is at least one
		match in Right.
		SQL equivalent: inner join (or simply join)

	AllInBoth will have all entries in right and left in the output. Specifically, it will have all entries
		in right with at least one match in left, followed by all entries in Right with no matches in left,
		followed by all entries in Left with no matches in Right.
		SQL equivalent: full join

.EXAMPLE
	#
	#Define some input data.

	$l = 1..5 | Foreach-Object {
		[pscustomobject]@{
			Name = "jsmith$_"
			Birthday = (Get-Date).adddays(-1)
		}
	}

	$r = 4..7 | Foreach-Object{
		[pscustomobject]@{
			Department = "Department $_"
			Name = "Department $_"
			Manager = "jsmith$_"
		}
	}

	#We have a name and Birthday for each manager, how do we find their department, using an inner join?
	Join-Object -Left $l -Right $r -LeftJoinProperty Name -RightJoinProperty Manager -Type OnlyIfInBoth -RightProperties Department


		# Name	Birthday			 Department
		# ----	--------			 ----------
		# jsmith4 4/14/2015 3:27:22 PM Department 4
		# jsmith5 4/14/2015 3:27:22 PM Department 5

.EXAMPLE
	#
	#Define some input data.

	$l = 1..5 | Foreach-Object {
		[pscustomobject]@{
			Name = "jsmith$_"
			Birthday = (Get-Date).adddays(-1)
		}
	}

	$r = 4..7 | Foreach-Object{
		[pscustomobject]@{
			Department = "Department $_"
			Name = "Department $_"
			Manager = "jsmith$_"
		}
	}

	#We have a name and Birthday for each manager, how do we find all related department data, even if there are conflicting properties?
	$l | Join-Object -Right $r -LeftJoinProperty Name -RightJoinProperty Manager -Type AllInLeft -Prefix j_

		# Name	Birthday			 j_Department j_Name	   j_Manager
		# ----	--------			 ------------ ------	   ---------
		# jsmith1 4/14/2015 3:27:22 PM
		# jsmith2 4/14/2015 3:27:22 PM
		# jsmith3 4/14/2015 3:27:22 PM
		# jsmith4 4/14/2015 3:27:22 PM Department 4 Department 4 jsmith4
		# jsmith5 4/14/2015 3:27:22 PM Department 5 Department 5 jsmith5

.EXAMPLE
	#
	#Hey!  You know how to script right?  Can you merge these two CSVs, where Path1's IP is equal to Path2's IP_ADDRESS?

	#Get CSV data
	$s1 = Import-CSV $Path1
	$s2 = Import-CSV $Path2

	#Merge the data, using a full outer join to avoid omitting anything, and export it
	Join-Object -Left $s1 -Right $s2 -LeftJoinProperty IP_ADDRESS -RightJoinProperty IP -Prefix 'j_' -Type AllInBoth |
		Export-CSV $MergePath -NoTypeInformation

.EXAMPLE
	#
	# "Hey Warren, we need to match up SSNs to Active Directory users, and check if they are enabled or not.
	#  I'll e-mail you an unencrypted CSV with all the SSNs from gmail, what could go wrong?"

	# Import some SSNs.
	$SSNs = Import-CSV -Path D:\SSNs.csv

	#Get AD users, and match up by a common value, samaccountname in this case:
	Get-ADUser -Filter "samaccountname -like 'wframe*'" |
		Join-Object -LeftJoinProperty samaccountname -Right $SSNs `
					-RightJoinProperty samaccountname -RightProperties ssn `
					-LeftProperties samaccountname, enabled, objectclass

.NOTES
	This borrows from:
		Dave Wyatt's Join-Object - http://powershell.org/wp/forums/topic/merging-very-large-collections/
		Lucio Silveira's Join-Object - http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx

	Changes:
		Always display full set of properties
		Display properties in order (left first, right second)
		If specified, add suffix or prefix to right object property names to avoid collisions
		Use a hashtable rather than ordereddictionary (avoid case sensitivity)

.LINK
	http://ramblingcookiemonster.github.io/Join-Object/

.FUNCTIONALITY
	PowerShell Language
#>
}