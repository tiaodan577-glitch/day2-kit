// enum-network.js - WMI network enumeration via Windows Script Host (cscript)
// Output: %TEMP%\enum-network-js.txt
var fso = new ActiveXObject("Scripting.FileSystemObject");
var out = fso.CreateTextFile(Environ("TEMP") + "\\enum-network-js.txt", true);
out.WriteLine("[*] enum-network.js " + new Date());

function Environ(n) { return new ActiveXObject("WScript.Shell").ExpandEnvironmentStrings("%" + n + "%"); }

function dump(title, wql) {
  out.WriteLine("");
  out.WriteLine("=== " + title + " ===");
  try {
    var wmi = GetObject("winmgmts:\\\\.\\root\\cimv2");
    var res = wmi.ExecQuery(wql);
    var e = new Enumerator(res);
    for (; !e.atEnd(); e.moveNext()) {
      var item = e.item(), line = "";
      var props = new Enumerator(item.Properties_);
      for (; !props.atEnd(); props.moveNext()) {
        var p = props.item();
        if (p.Value !== null) line += p.Name + "=" + p.Value + " | ";
      }
      out.WriteLine(line);
    }
  } catch (err) { out.WriteLine("ERR " + err.message); }
}

dump("NetworkAdapterConfiguration", "SELECT Description,IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder,DHCPEnabled,MACAddress FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True");
dump("NetworkAdapter", "SELECT Name,NetConnectionID,NetConnectionStatus,Speed FROM Win32_NetworkAdapter WHERE NetConnectionStatus IS NOT NULL");
dump("NetworkConnection", "SELECT * FROM Win32_NetworkConnection");
dump("PingGatewayHint", "SELECT * FROM Win32_PingStatus WHERE Address='1.1.1.1'");

// route & arp via shell (signed cmd)
var sh = new ActiveXObject("WScript.Shell");
function run(title, cmd) {
  out.WriteLine("");
  out.WriteLine("=== " + title + " ===");
  try {
    var e = sh.Exec("cmd /c " + cmd);
    while (!e.StdOut.AtEndOfStream) out.WriteLine(e.StdOut.ReadLine());
    while (!e.StdErr.AtEndOfStream) out.WriteLine("ERR " + e.StdErr.ReadLine());
  } catch (err) { out.WriteLine("ERR " + err.message); }
}
run("route print", "route print");
run("arp -a", "arp -a");
run("netstat -ano", "netstat -ano");

out.WriteLine("");
out.WriteLine("[+] done " + new Date());
out.Close();
WScript.Echo("[+] saved " + Environ("TEMP") + "\\enum-network-js.txt");
