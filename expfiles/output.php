<?php
//define the variable that will hold the data sent from flash via the input textbox 
//the data is sent from Flash by sending part of the loadVars object 
//inputData is a variable we will set in flash 
//it is a variable attached to the loadVars object and will be sent to this php script 

error_reporting(E_ALL); 
ini_set('display_errors', 1);

$receivedFromFlashData = $_POST['inputData']; 

$receivedFromFlashSubjectNumberLong = $_POST['SubjectNumberLong'];

$receivedFromFlashFileNamAddon = $_POST['FileNameAddon']; 

$filename = "data/sub" . $receivedFromFlashSubjectNumberLong . "_" . $receivedFromFlashFileNamAddon . ".txt";


if (!is_dir('data')) {
    mkdir('data');
}


if(file_exists($filename))
{
$myTextFileHandler = fopen($filename,"r+"); 
//$myTextFileHandler = @fopen($filename,"r+"); 
//extremely unlikely case.  will add on to existing file.  shouldn't ever happen though.
}
else
{

//make new file
$myTextFileHandler = fopen($filename,"w"); 
//$myTextFileHandler = @fopen($filename,"w"); 
}

if($myTextFileHandler){      
     
  

    	 $writeInTxtFile = @fwrite($myTextFileHandler,"$receivedFromFlashData");
	}      
        
     //close the stream to the textfile      
     fclose($myTextFileHandler);  
     //@fclose($myTextFileHandler);
    
    
    	if ($writeInTxtFile)
	{
		echo "WasWritingSuccessful=success";
	}
	else
	{
		echo "WasWritingSuccessful=failure";
	}
    
    
?>
