cls


##  Just gives YES if the files match, NO if it doesn't matches and Not present if it is not present in that server.

##  Enter your csv file's path here ending with '\'
$csvPath = "C:\Users\taran\Desktop\PS task CSV\"


##  Enter the database paths here separated with ','ending with '\'
$rootPathArr = "E:\DatabaseOne\DatabaseOne\", 
				"E:\DatabaseTwo\DatabaseTwo\", 
				"E:\DatabaseThree\DatabaseThree\"

$primaryRoot = $rootPathArr[0]


function comparingFolder1($fullName){

	$obj = New-Object psobject
	$match = New-Object System.Collections.Generic.List[System.Object]
	$file = $fullName.substring($primaryRoot.Length, ($fullName.Length - $primaryRoot.Length ))
	
	$obj | Add-Member -MemberType NoteProperty -Name $databaseArr[0] -Value $file.Split("\")[-3]
	$obj | Add-Member -MemberType NoteProperty -Name ($databaseArr[0]+" Folder") -Value $file.Split("\")[-2]
	$obj | Add-Member -MemberType NoteProperty -Name ($databaseArr[0]+" File") -Value $file.Split("\")[-1]
	
	$match.Add("first index should not be used")
	$root1Path = $rootPathArr[0]
	write-output $fullName
	
	for($i=1; $i -lt $rootPathArr.Length; $i++){
	
		$root2Path = $rootPathArr[$i]
		
		if(Test-Path -Path ($root2Path + $file)){
			
			$gcfile1 = gc ($root1Path + $file)
			$gcfile2 = gc ($root2Path + $file)
			
			$a = Compare-Object $gcfile1 $gcfile2 -CaseSensitive | Sort { $_.InputObject.ReadCount } |
			Group-Object {$_.InputObject.ReadCount} |
			select Name;
			if($a.length -eq 0){
				$match.Add("Yes")
			}
			else{
				$match.Add("No")
			}	
		}
		else{
			$match.Add("Not present")
		}
	}
	for($i=1; $i -lt $rootPathArr.Length; $i++){
		
		$obj | Add-Member -MemberType NoteProperty -Name ($databaseArr[$i]) -Value $match[$i]
	}
	$objArr.Add($obj)
}

function goInsideFolder1($rootArr, $path){
	$rootArr | 
	ForEach-Object{
	
		if(Test-Path -Path ($path + $_) -PathType Container){

			$folder = $_
			$tempRootArr  = New-Object System.Collections.Generic.List[System.Object]
			Get-ChildItem ($path+$_) | select name | 
			ForEach-Object {
				$tempRootArr.Add($_.Name)  
			}
			goInsideFolder1 $tempRootArr ($path + $_+ "\")
		}
		else{			
			comparingFolder1 ($path + $_)
		}
	}
}

$objArr  = New-Object System.Collections.Generic.List[System.Object]
$headers = New-Object System.Collections.Generic.List[System.Object]
$databaseArr = New-Object System.Collections.Generic.List[System.Object]
$rootArr = New-Object System.Collections.Generic.List[System.Object]

$rootPathArr |
ForEach-Object{
	$databaseArr.Add($_.Split("\")[-2])
}

$headers.Add($databaseArr[0])
$headers.Add($databaseArr[0]+" Folder")
$headers.Add($databaseArr[0]+" File")

for($j=1; $j -lt $rootPathArr.Length; $j++ ){

#	Write-Output ("************************ Path Arr: "+$rootPathArr[$j])
	
	$headers.Add($databaseArr[$j])	
}


Get-ChildItem $primaryRoot | select name | 
ForEach-Object {
    $rootArr.Add($_.name)
}
goInsideFolder1 $rootArr $primaryRoot


$csvName = "$((((Get-Date -format 'u') -replace ':','')-replace '\s','')-replace '-','').csv"


$psObject = New-Object psobject
foreach($header in $headers)
{
 	Add-Member -InputObject $psobject -MemberType noteproperty -Name $header -Value ""
}
$psObject | Export-Csv ($csvPath+$csvName) -NoTypeInformation

$objArr | Export-Csv -append -Path ($csvPath+$csvName) -NoTypeInformation

start ($csvPath+$csvName)




#Write-Output $objArr
