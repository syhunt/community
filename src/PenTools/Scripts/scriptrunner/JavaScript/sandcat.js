/*
Sandcat provides a JavaScript object, window.Sandcat, which can perform some very basic tasks.
*/

// print to the Sandcat Console
var from = 'JavaScript';
Sandcat.Write('Hello ');
Sandcat.WriteLn('World from '+from.toUpperCase()+'!');
Sandcat.WriteLn(navigator.userAgent);