<# 
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
                    Version 2, December 2004 
Copyright (C) 2004 Sam Hocevar <sam@hocevar.net> 
Everyone is permitted to copy and distribute verbatim or modified 
copies of this license document, and changing it is allowed as long 
as the name is changed. 
           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
 TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 

0. You just DO WHAT THE FUCK YOU WANT TO.

         ///\\\  ( Have Fun )
        ( ^  ^ ) /
      __(  __  )__
     / _ `----' _ \
     \__\   _   |__\
      (..) _| _ (..)
       |____(___|     Mynameisv_ 2016
_ __ _ (____)____) _ _________________________________ _'
#> 
#
##
###
################################################################
## Parameters and Prerequisites
################################
# Entry point function used to demonstration the usage of PoshLZW
param(
	[switch]$Compress, # Do the compression
	[switch]$Decompress, # Do the decompression
	[int32]$iCodingSize, # Dictionnary size
	[switch]$Test, # Do the test
	[switch]$Help, # Help/Usage
	$Datas # data to compress (string or bytes array) or decompress (base64 string or bytes array)
)
# Force usage of powershell 2
Set-StrictMode -Version 2
# Version
$global:iVersionMinor = 0;
$global:iVersionMajor = 1;
$global:sScriptName = "PoshLZW";
$global:sAuthor = "Mynameisv_"; # that looks to be me :-)
#
##
###
################################################################
## Functions
################################
#
################################
# Usage
function Usage{
	write-host "";
	write-host $global:sScriptName "$iVersionMajor.$iVersionMinor /" $global:sAuthor;
	write-host "License: Do what the fuck you want to public license";
	write-host "This is just a demonstration of the library, it is better used included in your own code as a library, see the short version."
	write-host "";
	write-host "Usage: Powershell -ExecutionPolicy Bypass -File PoshLZW.ps1 [-Compress|Decompress] [-iCodingSize <size>] [-Datas <datas>]";
	write-host "-Compress       LZW compression";
	write-host "-Decompress     LZW decompression";
	write-host "-iCodingSize    Dictionnary size (9 to 15)";
	write-host "-Datas          Datas to compress (normal string or byte array)";
	write-host "                      or decompress (base64 encoded byte array)";
	write-host "-Test           Test the script";
	write-host "";
	write-host "Example: ";
	write-host " > powershell -ex bypass -f PoshLZW.ps1 -C -i 9 -Da `"Hello dear library`" ";
	write-host "   CSQZTYbDeIDIZTCchAbDSYjlCDyA";
	write-host "";
	write-host " > powershell -ex bypass -f PoshLZW.ps1 -De -Da CSQZTYbDeIDIZTCchAbDSYjlCDyA";
	write-host "   Hello dear library";
	write-host "";
	write-host " > powershell";
	write-host " PS> Import-Module .\PoshLZW.ps1";
	write-host ' PS> $aBytes = [io.file]::ReadAllBytes("testfile.bin");';
	write-host ' PS> $aComp = LZWCompress -sContent $aBytes -iCodingSize 9;';
	write-host ' PS> $sDecomp = LZWDecompress -aCompressed $aComp;';
	write-host ' PS> $aResult =  [System.Text.Encoding]::UTF8.GetBytes($sDecomp);';
	write-host ' PS> [io.file]::WriteAllBytes("testfile-result.bin", $aResult);';
	write-host "";
}
#
# Test
function Test{
	# powershell -ex bypass -f PoshLZW.ps1 -C -Da "Hello, we are testing PoshLZW !!!"
	$Datas = "Hello, we are testing PoshLZW !!! Dup=are, are,are , so working !!?";
	#$Datas = "!!!!aaabbb`ncccCCCCC";
	
	if ($Datas.length -lt 80){
		$sBytes = $Datas;
	} else {
		$iMax = 18;
		$sBytes = $Datas.Substring(0,$iMax)+"..."+$Datas.Substring($Datas.length-$iMax,$iMax);
	}
	write-host "Compression of {$sBytes}, length={" $Datas.length "}";
	write-host "";
	
	for ($j=9;$j -le 15;$j++){
		$iCodingSize = $j;
		
		write-host "Coding/Dic Size={$iCodingSize}";
	
		$aCompressed = LZWCompress -sContent $Datas -iCodingSize $iCodingSize;
		$sBytes = "";
		$iMax = 6;
		for ($i=0;$i -lt $iMax;$i++){$sBytes+=[string]$aCompressed[$i]+" ";}
		$sBytes+="...";
		for ($i=$aCompressed.length-$iMax;$i -lt $aCompressed.length;$i++){$sBytes+= [string]$aCompressed[$i] + " ";}
		write-host "Compressed     {"$sBytes"}, length={" $aCompressed.length "}";
		
		$sFinal = LZWDecompress $aCompressed;
		if ($sFinal.length -lt 80){
			$sBytes = $sFinal;
		} else {
			$iMax = 18;
			$sBytes = $sFinal.Substring(0,$iMax)+"..."+$sFinal.Substring($sFinal.length-$iMax,$iMax);
		}
		write-host "Decompressed   {$sBytes}, length={" $sFinal.length "}";
		
		if ($Datas -eq $sFinal){
			write-host " -> \o/ it works \o/`n";
		} else {
			write-host " [!] Problem during compression or decompression.`n";
		}
	}
}	
#
################################
# Shift bits left or right
function Bits-Shift{
	param(
		[int32]$iValue, # integer valuer to shift
		[int32]$iShift # number of bit to shif : >0 means to the right, <0 means to the left
	)
	return [math]::Floor($iValue*[math]::Pow(2,-$iShift));
}
#
################################
# Write n-bits in a byte array
function Bits-Write{
	param(
		[int32]$iValue,	# Value to encode and write
		[int32]$iCodingSize, # Size in bits of the coding (9 to 15 bits)
		[ref]$aBytes	# array of encoded/written bits, as a reference
	)
	
	# Magic calculation of the iCodingSize-bits already written
	$iWritePos = [math]::floor($aBytes.value.count*8/$iCodingSize);
	
	# Number of bits to write in the first loop
	$iBitsToWrite = 8 - (($iWritePos * $iCodingSize - 8)%8);
	
	# First shift
	$iShift = $iCodingSize - $iBitsToWrite;
	
	# Number of bits that have been written
	$iWrittenBits = 0;

	#write-host "[Debug:Bits-Write] iValue={" $iValue "}, iBitsToWrite={" $iBitsToWrite "}, iShift={" $iShift "}, iWritePos={" $iWritePos "}, aBytes.count={" $aBytes.value.count "}";

	# Loop until we have written $iCodingSize bits
	while($iWrittenBits -lt $iCodingSize){
		# Build output  
		$bOutput = Bits-Shift -iValue $iValue -iShift $iShift;
		#write-host "[Debug:Bits-Write] iValue={" $iValue "}, shifted={" $bOutput "}";
		
		# clean left part to keep
		$bOutput = $bOutput -band 0x000000ff;
		#write-host "[Debug:Bits-Write] iValue={" $iValue "}, cleaned={" $bOutput "}";

		if($iBitsToWrite -eq 8){
			# 8 bits to write, Write output as a new Byte output
			#write-host "[Debug:Bits-Write] write 8-bits={" $bOutput "}, at pos={" ($aBytes.value.count) "}";
			$aBytes.value += $bOutput;
		} elseif($iWrittenBits -eq 0){
			# Last bits to write, add it to the actual Byte ouput
			$iCurrentBytePos = $aBytes.value.count - 1;
			# Write as an OR
			$aBytes.value[$iCurrentBytePos] = $aBytes.value[$iCurrentBytePos] -bor $bOutput;
			#write-host "[Debug:Bits-Write] write as OR={" $aBytes.value[$iCurrentBytePos] "}, at pos={" ($iCurrentBytePos) "}";
		}else{
			# n-bits to write, Write output as a new Byte output
			#write-host "[Debug:Bits-Write] write n-bits:{" $bOutput "}, at pos={" ($aBytes.value.count) "}";
			$aBytes.value += $bOutput;
		}
		# Written bits
		$iWrittenBits = $iCodingSize - $iShift
		# Remaining bits to write
		$iBitsToWrite = 8 - $iWrittenBits;
		# New shift, simple calcul
		$iShift -= 8;
	}
}
#
################################
# Read n-bits in a byte array
function Bits-Read{
	param(
			[array]$aBytes, # 
			[int32]$iCodingSize, # Size in bits of the encoded content
			[ref]$iBytesCount # Encoded byte read counter,  
	)
	# The result / output
	$iOutput = [int32]0;
	
	# Current Byte, the n-bits-Element number $iBytesCount, starts at $aBytes[$iReadPos]
	$iReadPos = [math]::floor($iBytesCount.value*$iCodingSize/8);
		
	# Number of bits to read in the current Byte (1 to 8)
	$iBitsToRead = 8-(($iBytesCount.value * $iCodingSize)%8);
	
	# First shift for reading
	$iShift = $iBitsToRead - $iCodingSize;
	
	# Binary mask to clean read value
	$iBinaryMask = [math]::Pow(2,$iCodingSize)-1;
		
	# Next element starts at $aBytes[$iReadPos + $iIndexComplement]
	$iIndexComplement = 0;
	
	# Number of bits that have been read
	$iReadBits = 0;
	
	#write-host "[Debug:Bits-Read] iBitsToRead={" $iBitsToRead "}, iShift={" $iShift "}, iReadPos={" $iReadPos "}, aBytes.count={" $aBytes.count "}";

	# Loop until we have read $iCodingSize bits
	while ($iReadBits -lt $iCodingSize){
		# Read bits with a shift to remove unwanted bits
		$iBits = Bits-Shift -iValue $aBytes[$iReadPos + $iIndexComplement] -iShift $iShift;

		# clean left part to keep
		$iBits = $iBits -band $iBinaryMask;

		# read (merge) the content to the output
		$iOutput = $iOutput -bor $iBits;
		
		# increase the read bis counter
		$iReadBits += $iBitsToRead;
		
		# calculate the number of bits left to read
		$iBitsToRead = $iCodingSize - $iBitsToRead;
		if ($iBitsToRead -gt 8){
			$iBitsToRead = 8;
		}
		# new shift, simply "8 + last shift"
		$iShift = 8 + $iShift;
		$iIndexComplement +=1;
		
	}
	# Increment the read bytes counter
	$iBytesCount.value = $iBytesCount.value + 1;
	return $iOutput;
}
#
################################
# LZW Compression
function LZWCompress{
	param(
		$sContent, # Message to encode, as a string
		[int]$iCodingSize # Coding size in bits (9 to 15)
	)
	$aCompressed = @(); # Output result as an array of Bytes (positions in the dictionnary). First byte is the encoding size and has to be extract before decompression -> $bToUse = $aCompressed[1..$aCompressed.length];
	$aDictionnary=@();	# ephemeral local dictionnary used only during the compression
	$sWordPrevious = '';
	$sWordCurrent = '';
	
	# Build of the ephemeral local dictionnary
	foreach($i in 0..255){
		# Double conversion [int] -> [char] -> [string]
		# Long version=([string]([char]$i)), short=[string][char]$i;
		$aDictionnary += [string][char]$i;
	}

	# Max size for the dictionarry : 2^$iCodingSize-1
	$iDictionnaryMaxSize = [math]::Pow(2,$iCodingSize)-1;

	# LZW compression loop
	#write-host "[Debug:LZWCompress] Content length=" $sContent.length ", iCodingSize=" $iCodingSize
	#write-host "[Debug:LZWCompress] output size={" $aCompressed.length "}";
	for ($i=0;$i -lt $sContent.length; $i++){
		# Concat previous word ($sWordPrevious) and next element ($sContent[$i]) in $sWordCurrent
		# $sWordPrevious contains:
		#  - previous char ($sContent[$i-1]) (empty at first loop)
		#  or
		#  - string ($sContent[$i-n]+...+$sContent[$i-1])
		#write-host "[Debug:LZWCompress] Loop number i=$i ----------------------";
		$sWordCurrent = $sWordPrevious + [char]$sContent[$i];
		#write-host "[Debug:LZWCompress] sContent[$i]={" ([char]$sContent[$i]) "}, sWordCurrent={" $sWordCurrent "}, sWordPrevious={" $sWordPrevious "}";
		if ([array]::IndexOf($aDictionnary,$sWordCurrent) -gt -1){
			# $sWordCurrent has been found in the dictionnary
			#write-host "[Debug:LZWCompress] sWordCurrent has been found in the dictionnary at pos={" ([array]::IndexOf($aDictionnary,$sWordCurrent)) "}";
			# So we extend the next $sWordCurrent by setting $sWordPrevious as $sWordCurrent (will be concated next loop)
			$sWordPrevious = $sWordCurrent;
		} else {
			# $sWordCurrent has NOT been found in dictionnary
			#write-host "[Debug:LZWCompress] sWordCurrent has NOT been found in the dictionnary.";
			#write-host "[Debug:LZWCompress] Write index of sWordPrevious(" $sWordPrevious ")={" ([array]::IndexOf($aDictionnary,$sWordPrevious)) "}";
			# Write previous word ($sWordPrevious) to the output (bit per bit way)
			Bits-Write ([array]::IndexOf($aDictionnary,$sWordPrevious)) $iCodingSize ([ref]$aCompressed);
			
			#write-host "[Debug:LZWCompress] Output size={" $aCompressed.length "}";
			#write-host "[Debug:LZWCompress] Output={" $aCompressed "}";
			
			if ($aDictionnary.length -ge $iDictionnaryMaxSize){
				# No more free space in the dictionnary
				#write-host "[Debug:LZWCompress] No more free space in the dictionnary !!!";
				$sWordPrevious = [string][char]$sContent[$i];
			} else {
				# Add $sWordCurrent to the dictionnay
				$aDictionnary+= $sWordCurrent;
				#write-host "[Debug:LZWCompress] Add sWordCurrent={" $sWordCurrent "} to the dictionnary, pos={" ($aDictionnary.length-1) "}";
				# Use the current element ($sContent[$i]) as the new previous word
				$sWordPrevious = [string][char]$sContent[$i];
			}
		}
		#write-host "[Debug:LZWCompress] sWordPrevious={" $sWordPrevious "}";
	}
	# Store last word and avoid miss
	Bits-Write ([array]::IndexOf($aDictionnary,$sWordPrevious)) $iCodingSize ([ref]$aCompressed);
	#write-host "[Debug:LZWCompress] Final, output size={" $aCompressed.length "}";
	#write-host "[Debug:LZWCompress] Final, output={" $aCompressed "}";
	return @($iCodingSize)+$aCompressed;
}
#
################################
# LZW Decompression
function LZWDecompress{
	param(
		$aCompressed # Compressed array of bytes
	)
	$iWritePos = [int32]0; # Result counter, to count and remember the number of call to Bit-Write
	$aDictionnary=@();	# ephemeral local dictionnary used during the decompression
	$iRef = '';
	$sEntry = '';
	$sDecompressed = '';
	$iCodingSize = $aCompressed[0]; # Extract coding size in bits (9 to 15)
	$aCompressed = $aCompressed[1..$aCompressed.length];
	
	# Build of the ephemeral dictionnary
	foreach($i in 0..255){
		$aDictionnary += [string]([char]$i);
	}
	
	$iRef = Bits-Read -aBytes $aCompressed -iCodingSize $iCodingSize -iBytesCount ([ref]$iWritePos);
	$sWord = [string]$aDictionnary[$iRef];
	#write-host "[Debug:LZWDecompress] Read pos iRef=" $iRef "}, dic(iRef)=sWord={" $sWord "}";
	#write-host "[Debug:LZWDecompress] Write to output {" $sWord "}";
	$sDecompressed += $sWord;
	#write-host "[Debug:LZWDecompress] Output size={" $sDecompressed.length "}, [" $sDecompressed "]";

	# LZW decompression loop
	#write-host "[Debug:LZWDecompress] Compressed length={" $aCompressed.length "}, Remaining={" ([math]::floor($iWritePos*$iCodingSize/8)) "}";
	while ([math]::floor($iWritePos*$iCodingSize/8) -lt ($aCompressed.length-1)){
		#write-host "[Debug:LZWDecompress] Loop " ([math]::floor($iWritePos*$iCodingSize/8)) "<" ($aCompressed.length-1) " ----------------------";
		# Read element from compressed data 
		#write-host "[Debug:LZWDecompress] sWord={" $sWord "}";
		$iRef = Bits-Read -aBytes $aCompressed -iCodingSize $iCodingSize -iBytesCount ([ref]$iWritePos);
		#write-host "[Debug:LZWDecompress] Read pos iRef={" $iRef "}";
		
		# Is reference in dictionnary ?
		$iDicLen = $aDictionnary.count;
		if ($iRef -gt 255){
			if ($iRef -lt $iDicLen){
				$sEntry = [string]$aDictionnary[$iRef];
				#write-host "[Debug:LZWDecompress] sEntry=aDictionnary(iRef)=aDictionnary(" $iRef ")={" $sEntry "}";
			} else {
				$sEntry = $sWord + $sWord[0];
				#write-host "[Debug:LZWDecompress] sEntry(sWord+sWord[0])={" $sWord "+" $sWord[0] "=" $sEntry "}";
			}
		} else {
			$sEntry = [string][char]$iRef;
			#write-host "[Debug:LZWDecompress] sEntry=[string]iRef={" ([string][char]$iRef) "}";
		}

		#write-host "[Debug:LZWDecompress] Write to output {" $sEntry "}";
		$sDecompressed+= $sEntry;
		#write-host "[Debug:LZWDecompress] Output size={" $sDecompressed.length "}, [" $sDecompressed "]";
		$aDictionnary+= $sWord + $sEntry[0];
		#write-host "[Debug:LZWDecompress] Add sWord+sEntry[0]={" $sWord "+" $sEntry[0] "} to the dictionnary, pos={" ($aDictionnary.length-1) "}";
		$sWord = $sEntry

	}
	return $sDecompressed;
}
#
##
###
################################################################
## Main / Entrypoint
################################

# Nothing to do ?
if ($Help){
	Usage;
	exit;
}
	
# Test case
if ($Test){
	Test;
	# Dirty way to exit, better would be if/else but that short ;-)
	exit;
}

# Missing input
if (!$Datas -Or (!$Compress -And !$Decompress)){
	exit;
}

# Compression/Decompression
# Check input : iCodingSize
if (!$iCodingSize){
	$iCodingSize = 9;
}
# Check input : Compress/Decompress
if ($Compress){
	# If compression, Datas has to be a simple string or byte array
	if ($Datas.GetType().fullname -eq "System.String"){
		# Ok
	} elseif ($Datas.GetType().fullname -eq "System.Byte[]"){
		$Datas = [System.Text.Encoding]::UTF8.GetString($Datas);
	} else {
		write-host " [!] Error, input datas type not string not bytes array.`n";
		Usage;
		exit;
	}
} elseif ($Decompress){
	# If decompression, it has to be a base64 encoded string
	# Two ways to check : check each character part of the b64 alphabet or... try/catch to debase64 ;-)
	Try {
		$Datas = [Convert]::FromBase64String($Datas);
	} Catch {
		write-host " [!] Error, input datas type not Base64 (or is wrong encoded).`n";
		Usage;
		exit;
	}
} else {
	write-host " [!] Error, no action to do.`n";
	Usage;
}

# Let do some LZW stuff !
if ($Compress){
	# Compression
	$aCompressed = LZWCompress -sContent $Datas -iCodingSize $iCodingSize;
	
	# Conversion to Base64
	$sResult = [convert]::ToBase64String($aCompressed);
	
} elseif ($Decompress){
	# Decompression
	$sResult = LZWDecompress $Datas;
}
$sResult;