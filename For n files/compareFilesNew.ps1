cls


## Difference in ordering of the final output than the second file.

## gives a detailed view of the file comparison
## shows Yes if the file matches, "NO" if it doesn't, and "Not present" if it doesn't exists
## Also tells the line number and shows the line that makes the file different


##  Enter your csv file's path here ending with '\'
$csvPath = "C:\Users\taran\Desktop\PS task CSV\"


##  Enter the database paths here separated with ','ending with '\'
$rootPathArr = "E:\DatabaseOne\DatabaseOne\", 
				"E:\DatabaseTwo\DatabaseTwo\", 
				"E:\DatabaseThree\DatabaseThree\"
				
				
				
function comparingFolder1($fullName, $index){

	$obj = New-Object psobject
	$match =""
	$LineNumber = ""
	$errorLine = ""
	
	$Checked.Add($file)
	$root1Path = $rootPathArr[$index]
	$file = $fullName.substring($root1Path.Length, ($fullName.Length - $root1Path.Length ))
	
	$Checked.Add($file)
	 
	for($i=0; $i -lt $rootPathArr.Length; $i++){
		$root2Path = $rootPathArr[$i]
		if($root2Path -eq $root1Path){
			$obj | Add-Member -MemberType NoteProperty -Name $databaseArr[$i] -Value $file.Split("\")[-3]
			$obj | Add-Member -MemberType NoteProperty -Name ("Folder "+($i+1)) -Value $file.Split("\")[-2]
			$obj | Add-Member -MemberType NoteProperty -Name ("File "+($i+1)) -Value $file.Split("\")[-1]
			$obj | Add-Member -MemberType NoteProperty -Name ("Match "+($i+1)) -Value ""
			$obj | Add-Member -MemberType NoteProperty -Name ("Line No. "+($i+1)) -Value ""
			$obj | Add-Member -MemberType NoteProperty -Name ("Line in database "+($i+1)) -Value ""
		}
		else{ 
			if(Test-Path -Path ($root2Path + $file)){
				
				$gcfile1 = gc ($root1Path + $file)
				$gcfile2 = gc ($root2Path + $file)
				
				$a = Compare-Object $gcfile1 $gcfile2 -CaseSensitive | Sort { $_.InputObject.ReadCount } |
				Group-Object {$_.InputObject.ReadCount} |
				select Name;
				if($a.length -eq 0){
					$match = "Yes"
					$LineNumber = ""
					$errorLine = ""
				}
				else{
					$match = "No"
					$LineNumber = $a[0].Name
					$errorLine = ( gc ($root2Path + $file) | select -Index ($LineNumber-1))
				}	
			}
			else{
				$match = "Not Found in Server"
				$LineNumber = ""
				$errorLine = ""
			}
			$obj | Add-Member -MemberType NoteProperty -Name $databaseArr[$i] -Value $file.Split("\")[-3]
			$obj | Add-Member -MemberType NoteProperty -Name ("Folder "+($i+1)) -Value $file.Split("\")[-2]
			$obj | Add-Member -MemberType NoteProperty -Name ("File "+($i+1)) -Value $file.Split("\")[-1]
			$obj | Add-Member -MemberType NoteProperty -Name ("Match "+($i+1)) -Value $match
			$obj | Add-Member -MemberType NoteProperty -Name ("Line No. "+($i+1)) -Value $LineNumber
			$obj | Add-Member -MemberType NoteProperty -Name ("Line in database "+($i+1)) -Value $errorLine
	
		}
		$objArr.Add($obj)
	}
}

function goInsideFolder1($rootArr, $path, $index){
	$rootArr | 
	ForEach-Object{
	
		if(Test-Path -Path ($path + $_) -PathType Container){

			$folder = $_
			$tempRootArr  = New-Object System.Collections.Generic.List[System.Object]
			Get-ChildItem ($path+$_) | select name | 
			ForEach-Object {
				$tempRootArr.Add($_.Name)  
			}
			goInsideFolder1 $tempRootArr ($path + $_+ "\") $index
		}
		else{
			$file = ($path+$_).substring($rootPathArr[$index].Length, (($path+$_).Length - $rootPathArr[$index].Length))
			Write-Output ($path+$_)		
			if(-not($Checked -contains $file)){

				Write-Output "Not there"
				comparingFolder1 ($path + $_) $index
			}
		}
	}
}

$objArr  = New-Object System.Collections.Generic.List[System.Object]
$databaseArr = New-Object System.Collections.Generic.List[System.Object]
$headers = New-Object System.Collections.Generic.List[System.Object]

$rootPathArr |
ForEach-Object{
	$databaseArr.Add($_.Split("\")[-2])
}

$Checked = New-Object System.Collections.Generic.List[System.Object]


for($j=0; $j -lt $rootPathArr.Length; $j++ ){

	Write-Output ("************************ Path Arr: "+$rootPathArr[$j])
	
	$headers.Add($databaseArr[$j])
	$headers.Add("Folder "+($j+1))
	$headers.Add("File "+($j+1))
	$headers.Add("Match "+($j+1))
	$headers.Add("Line No. "+($j+1))
	$headers.Add("Line in database "+($j+1))
	
	$rootArr  = New-Object System.Collections.Generic.List[System.Object]
	
	Get-ChildItem $rootPathArr[$j] | select name | 
	ForEach-Object {
	    $rootArr.Add($_.name)
	}
	goInsideFolder1 $rootArr $rootPathArr[$j] $j
}

$csvName = "$((((Get-Date -format 'u') -replace ':','')-replace '\s','')-replace '-','').csv"

Write-Output $headers

$psObject = New-Object psobject
foreach($header in $headers)
{
 	Add-Member -InputObject $psobject -MemberType noteproperty -Name $header -Value ""
}
$psObject | Export-Csv ($csvPath+$csvName) -NoTypeInformation

$objArr | Export-Csv -append -Path ($csvPath+$csvName) -NoTypeInformation

start ($csvPath+$csvName)

#Write-Output $objArr
