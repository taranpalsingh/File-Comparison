cls


##  Enter the database paths here separated, ending with '\'
$root1Path = "E:\DatabaseOne\DatabaseOne\"
$root2Path = "E:\DatabaseTwo\DatabaseTwo\"

##  Enter your csv file's path here ending with '\'
$csvPath = "C:\Users\taran\Desktop\PS task CSV\"

$database1 = $root1Path.Split("\")[-2]
$database2 = $root2Path.Split("\")[-2]

Write-Output $database1
Write-Output $database2

function comparingFolder1($fullName){

	$file = $fullName.substring($root1Path.Length, ($fullName.Length - $root1Path.Length ))
	
	if(Test-Path -Path ($root2Path + $file)){
		
		$file1 = $file
		$file2 = $file
		$gcfile1 = gc ($root1Path + $file)
		$gcfile2 = gc ($root2Path + $file)
		
		$a = Compare-Object $gcfile1 $gcfile2 -CaseSensitive | Sort { $_.InputObject.ReadCount } |
		Group-Object {$_.InputObject.ReadCount} |
		select Name;
		if($a.length -eq 0){
			$a1 = ""
			$match = "Yes"
		}
		else{
			$match = "No"
			$a1 = $a[0] | foreach { $_.Name }
		}	
	}
	else{
		$match = "Not present in server 2"
		$file1 = $fullName  
		$file2 = ""
		$a1 = ""
	}

	$obj = New-Object psobject
	$obj | Add-Member -MemberType NoteProperty -Name $database1 -Value $file1.Split("\")[-3]
	$obj | Add-Member -MemberType NoteProperty -Name "Folder 1" -Value $file1.Split("\")[-2]
	$obj | Add-Member -MemberType NoteProperty -Name "File Name 1" -Value  $file1.Split("\")[-1]
	
	$obj | Add-Member -MemberType NoteProperty -Name $database2 -Value $file2.Split("\")[-3]
	$obj | Add-Member -MemberType NoteProperty -Name "Folder 2" -Value $file2.Split("\")[-2]
	$obj | Add-Member -MemberType NoteProperty -Name "File Name 2" -Value  $file2.Split("\")[-1]
	
	$obj | Add-Member -MemberType NoteProperty -Name "Match" -Value  $match
	$obj | Add-Member -MemberType NoteProperty -Name "Line Number" -Value  $a1.ToString()
	if($match -eq "No"){
		$obj | Add-Member -MemberType NoteProperty -Name "Line in database 1" -Value ($gcfile1 | select -Index ($a1-1))
		$obj | Add-Member -MemberType NoteProperty -Name "Line in database 2" -Value ($gcfile2 | select -Index ($a1-1))
	}
	else{
		$obj | Add-Member -MemberType NoteProperty -Name "Line in database 1" -Value ""
		$obj | Add-Member -MemberType NoteProperty -Name "Line in database 2" -Value ""
	}
	$objArr.Add($obj)	
}

function comparingFolder2($fullName){

	$file = $fullName.substring($root2Path.Length, ($fullName.Length - $root2Path.Length))
	if(-Not(Test-Path -Path ($root1Path + $file))){
		$match = "Not present in server 1"
		$file1 = ""
		$file2 = $file  
		$a1 = ""
	
		$obj = New-Object psobject
		$obj | Add-Member -MemberType NoteProperty -Name $database1 -Value $file1.Split("\")[-3]
		$obj | Add-Member -MemberType NoteProperty -Name "Folder 1" -Value $file1.Split("\")[-2]
		$obj | Add-Member -MemberType NoteProperty -Name "File Name 1" -Value  $file1.Split("\")[-1]
		
		$obj | Add-Member -MemberType NoteProperty -Name $database2 -Value $file2.Split("\")[-3]
		$obj | Add-Member -MemberType NoteProperty -Name "Folder 2" -Value $file2.Split("\")[-2]
		$obj | Add-Member -MemberType NoteProperty -Name "File Name 2" -Value  $file2.Split("\")[-1]
		
		$obj | Add-Member -MemberType NoteProperty -Name "Match" -Value $match
		$obj | Add-Member -MemberType NoteProperty -Name "Line Number" -Value  $a1.ToString()
		$obj | Add-Member -MemberType NoteProperty -Name "Line in database 1" -Value ""
		$obj | Add-Member -MemberType NoteProperty -Name "Line in database 2" -Value ""
	
		$objArr.Add($obj)	
	}
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
			comparingFolder1 ($path+$_)
		}
	}
}
function goInsideFolder2($rootArr, $path){
	
	$rootArr | 
	ForEach-Object{
		if(Test-Path -Path ($path + $_) -PathType Container){
			
			$folder = $_
			$tempRootArr  = New-Object System.Collections.Generic.List[System.Object]
			Get-ChildItem ($path+$_) | select name | 
			ForEach-Object {
				$tempRootArr.Add($_.Name)  
			}
			goInsideFolder2 $tempRootArr ($path + $_+ "\")
			
		}
		else{
			comparingFolder2 ($path+$_)
		}
	}
}

$root1Arr  = New-Object System.Collections.Generic.List[System.Object]
$root2Arr  = New-Object System.Collections.Generic.List[System.Object]
$objArr  = New-Object System.Collections.Generic.List[System.Object]

Get-ChildItem $root1Path | select name | 
ForEach-Object {
    $root1Arr.Add($_.name)
}
Get-ChildItem $root2Path | select name | 
ForEach-Object {
    $root2Arr.Add($_.name)
}

goInsideFolder1 $root1Arr $root1Path
goInsideFolder2 $root2Arr $root2Path
#Write-Output $objArr

$csvName = "$((((Get-Date -format 'u') -replace ':','')-replace '\s','')-replace '-','').csv"
$csv = @"
$($database1), Folder 1, File Name 1, $($database2),  Folder 2, File Name 2, Match, Line Number, Line in database 1, Line in database 2
"@ 
$csv | Out-File ($csvpath+$csvName) -Encoding ASCII
$objArr | Export-Csv -append -Path ($csvPath+$csvName) -NoTypeInformation

start ($csvPath+$csvName)
