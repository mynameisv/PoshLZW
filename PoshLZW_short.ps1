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
## Short versions
## /!\ Best to use included in you own code / shellcode
################################
# Shortcuts
$m_=[math];
# Shorted Bit-Shift
function bs{param($v,$s)return $m_::Floor($v*$m_::Pow(2,-$s))}
# Decompression and Bits-Read
function br{param($o,$c,$a)$p=0;$j=$m_::floor(($t=$a.value)*$c/8);$s=($r=8-(($t*$c)%8))-$c;$b=$m_::Pow(2,$c)-1;$i=0;$e=0;while($e-lt$c){$p=$p-bor((bs $o[$j+$i] $s)-band$b);$e+=$r;if(($r+=$c)-gt8){$r=8}$s=8+$s;$i++}$a.value++;return $p}
function lzwd{param($z)$a=0;$d=@();$e=$o='';$k=$z[0];$z=$z[1..$z.count];foreach($i in 0..255){$d+=[string][char]$i}$r=br $z $k ([ref]$a);$w=[string]$d[$r];$o+=$w;while([math]::floor($a*$k/8)-lt($z.count-1)){$r=br $z $k ([ref]$a);if($r-gt255){if($r-lt$d.count){$e=[string]$d[$r]}else{$e=$w+$w[0]}}else{$e=[string][char]$r;}$d+=$w+$e[0];$o+=($w=$e);}return $o;}
# Compression and Bits-Write
function bw{param($v,$c,$o)$a=$m_::floor($o.value.count*8/$c);$s=$c-($w=8-(($a*$c-8)%8));$r=0;while($r-lt$c){$p=(bs $v $s)-band0xff;if($w-eq8){$o.value+=$p}elseif($r-eq0){$o.value[$i]=$o.value[($i=$o.value.count-1)]-bor$p}else{$o.value+=$p}$w=8-($r=$c-$s);$s-=8}$a++}
function lzwc{param($d,$z)$k=($y=@());$r=$w='';$a=[array];foreach($i in 0..255){$y+=[string][char]$i}$x=$m_::Pow(2,$z)-1;for($i=0;$i-lt$d.length;$i++){if($a::IndexOf($y,($w=$r+[char]$d[$i]))-gt-1){$r=$w}else{bw ($a::IndexOf($y,$r)) $z ([ref]$k);if($y.count-ge$x){$r=[string][char]$d[$i];}else{$y+=$w}$r=[string][char]$d[$i];}}bw ($a::IndexOf($y,$r)) $z ([ref]$k);return @($z)+$k;}