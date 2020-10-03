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
$password_match = "";
 
function check($password)
{
        global $hash_password, $time_start, $password_match;     
 
        if (hash(HASH_ALGO, $password) == $hash_password) {
 
                echo("FOUND MATCH, password: " . $password);
                $password_match = $password;
                $time_end = getmicrotime();
                $time = $time_end - $time_start; 
                echo("Found in " . $time . " seconds");
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
 
echo("Target hash: " . $hash_password);
for ($i = 1; $i < PASSWORD_MAX_LENGTH + 1; ++$i) {
        echo("Checking passwords with length:" .$i);
        $time_check = getmicrotime();
        $time = $time_check - $time_start;
        echo("Runtime: " . $time . " seconds");
        recurse($i, 0, '');
}
 
echo("Execution complete, no password found");
?>