<?
set_time_limit(0);
 
function getmicrotime() {
   list($usec, $sec) = explode(" ",microtime());
   return ((float)$usec + (float)$sec);
} 
 
$time_start = getmicrotime();
 
// algorithm of hash
// see http://php.net/hash_algos for available algorithms
define('HASH_ALGO', 'md5');
 
// max length of password to try
define('PASSWORD_MAX_LENGTH', $s_maxcount);
 
$charset = $s_charset;
#$charset = 'abcdefghijklmnopqrstuvwxyz';
#$charset .= '0123456789';
#$charset .= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
#$charset .= '~`!@#$%^&*()-_\/\'";:,.+=<>? ';
$str_length = strlen($charset);
 
 
// If no arguments given present usage info
//if ($_SERVER["argc"] < 1) {
//  print "Usage: attack.php <hash>\n";
//  exit;
//}
 
// Get MD5 checksum from command line
$hash_password = $s_md5;// $_SERVER["argv"][1];
 
function check($password)
{
        global $hash_password, $time_start;     
 
        if (hash(HASH_ALGO, $password) == $hash_password) {
 
                sandcat_writeln("FOUND MATCH, password: " . $password);
                sandcat_setg('found',$password);
                $time_end = getmicrotime();
                $time = $time_end - $time_start; 
                sandcat_writeln("Found in " . $time . " seconds");
                exit;
        }
}
 
 
function recurse($width, $position, $base_string)
{
        global $charset, $str_length;
 
        for ($i = 0; $i < $str_length; ++$i) {
                if ($position  < $width - 1) {
                        recurse($width, $position + 1, $base_string . $charset[$i]);
                }
                check($base_string . $charset[$i]);
        }
}
 
sandcat_writeln("Target hash: " . $hash_password);
for ($i = 1; $i < PASSWORD_MAX_LENGTH + 1; ++$i) {
        sandcat_writeln("Checking passwords with length:" .$i);
        $time_check = getmicrotime();
        $time = $time_check - $time_start;
        sandcat_writeln("Runtime: " . $time . " seconds");
        recurse($i, 0, '');
}
 
sandcat_writeln("Execution complete, no password found");
?>