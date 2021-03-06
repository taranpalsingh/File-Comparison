cls


## Difference in ordering of the final output than the first file.
## The logic implementation is also different.

## gives a detailed view of the file comparison
## shows Yes if the file matches, "NO" if it doesn't, and "Not present" if it doesn't exists
## Also tells the line number and shows the line that makes the file different

##  Enter your csv file's path here ending with '\'
$csvPath = "C:\Users\taran\Desktop\PS task CSV\"


##  Enter the database paths here separated with ','ending with '\'
$rootPathArr = "E:\DatabaseOne\DatabaseOne\", 
				"E:\DatabaseTwo\DatabaseTwo\", 
				"E:\DatabaseThree\DatabaseThree\"

function comparingFile($fullName, $index){

	$obj = New-Object psobject
	
	$databases = New-Object System.Collections.Generic.List[System.Object]
	$folders = New-Object System.Collections.Generic.List[System.Object]
	$files = New-Object System.Collections.Generic.List[System.Object]
	$matches = New-Object System.Collections.Generic.List[System.Object]
	$lineNumbers = New-Object System.Collections.Generic.List[System.Object]
	$errorLines = New-Object System.Collections.Generic.List[System.Object]
	$exists = New-Object System.Collections.Generic.List[System.Object]
	
	$LineNumber = ""
	$Match ="Yes"

	
	$Checked.Add($file)
	$root1Path = $rootPathArr[$index]
	$file = $fullName.substring($root1Path.Length, ($fullName.Length - $root1Path.Length ))
	
	$Checked.Add($file)
	 
	for($i=0; $i -lt $rootPathArr.Length; $i++){
		$root2Path = $rootPathArr[$i]
		if($root2Path -eq $root1Path){
			$databases.Add(($file.Split("\")[-3]))
			$folders.Add($file.Split("\")[-2])
			$files.Add($file.Split("\")[-1])
			$exists.Add("1")
		}
		else{ 
		
			$databases.Add($file.Split("\")[-3])
			$folders.Add($file.Split("\")[-2])
			$files.Add($file.Split("\")[-1])
		
			if(Test-Path -Path ($root2Path + $file)){
				
				$exists.Add("1")
				$gcfile1 = gc ($root1Path + $file)
				$gcfile2 = gc ($root2Path + $file)
				
				$a = Compare-Object $gcfile1 $gcfile2 -CaseSensitive | Sort { $_.InputObject.ReadCount } |
				Group-Object {$_.InputObject.ReadCount} |
				select Name;
				if($a.length -eq 0){    
				}
				else{
					$Match = "No"
					$LineNumber = $a[0].Name
				}	
			}
			else{
				$exists.Add("0")
			}
		}
	}
	for($i=0; $i -lt $rootPathArr.Length; $i++){
		
		$obj | Add-Member -MemberType NoteProperty -Name $databaseArr[$i] -Value $databases[$i]
		$obj | Add-Member -MemberType NoteProperty -Name ("Folder "+($i+1)) -Value $folders[$i]
		$obj | Add-Member -MemberType NoteProperty -Name ("File "+($i+1)) -Value $files[$i]
		
		if($exists[$i] -eq "1"){
			$obj | Add-Member -MemberType NoteProperty -Name ("Match "+($i+1)) -Value $Match					
			if($Match -eq "No"){
				$errorLine = ( gc ($rootPathArr[$i] + $file) | select -Index ($LineNumber-1))
				$obj | Add-Member -MemberType NoteProperty -Name ("Line No. "+($i+1)) -Value $LineNumber
				$obj | Add-Member -MemberType NoteProperty -Name ("Line in database "+($i+1)) -Value $errorLine
			}
			else{
				$obj | Add-Member -MemberType NoteProperty -Name ("Line No. "+($i+1)) -Value ""
				$obj | Add-Member -MemberType NoteProperty -Name ("Line in database "+($i+1)) -Value ""
			}
		}
		else{
			$obj | Add-Member -MemberType NoteProperty -Name ("Match "+($i+1)) -Value "Not present in Server"
			$obj | Add-Member -MemberType NoteProperty -Name ("Line No. "+($i+1)) -Value ""
			$obj | Add-Member -MemberType NoteProperty -Name ("Line in database "+($i+1)) -Value ""
		}
	}	
	$objArr.Add($obj)
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
				comparingFile ($path + $_) $index
			}
		}
	}
}

$objArr  = New-Object System.Collections.Generic.List[System.Object]
$databaseArr = New-Object System.Collections.Generic.List[System.Object]
$headers = New-Object System.Collections.Generic.List[System.Object]
$LineNumber = ""

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
