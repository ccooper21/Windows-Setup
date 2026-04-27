Windows 11 Setup

My notes and scripts to prepare for and perform a clean Windows 11 installation.

## Preparing for Installation

### Downloading the Windows installation media

The Windows 11 installation media can be downloaded as an ISO file using the (Fido)[https://github.com/pbatard/Fido]
PowerShell script, included as a `git` submodule in the `Tools/Fido` folder of this project.

Since Fido is implemented as a PowerShell script, it must be run in Windows or in PowerShell for Linux.  When running
in PowerShell for Linux, the script will be unable to perform the download of the ISO file as this capability relies
on Windows native functionality.  However, Fido can return the ISO file's URL, which subsequently can be downloaded
using `curl`.

Fido has checks that prevent its operation in PowerShell for Linux, which hence will need to be patched.  The `git diff`
for the patch is as follows:

```text
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Tools/Fido$ git diff
diff --git a/Fido.ps1 b/Fido.ps1
index 7b8f7e6..cf7cecb 100644
--- a/Fido.ps1
+++ b/Fido.ps1
@@ -775,12 +775,6 @@ if ($Cmd) {
        $winLanguageName = $null
        $winLink = $null

-       # Windows 7 and non Windows platforms are too much of a liability
-       if ($winver -le 6.1) {
-               Error(Get-Translation("This feature is not available on this platform."))
-               exit 403
-       }
-
        $i = 0
        $Selected = ""
        if ($Win -eq "List") {
@@ -948,12 +942,6 @@ $WindowsVersionTitle.Text = Get-Translation("Version")
 $Continue.Content = Get-Translation("Continue")
 $Back.Content = Get-Translation("Close")

-# Windows 7 and non Windows platforms are too much of a liability
-if ($winver -le 6.1) {
-       Error(Get-Translation("This feature is not available on this platform."))
-       exit 403
-}
-
 # Populate the Windows versions
 $i = 0
 $versions = @()
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Tools/Fido$
```

Here is an example showing how to run the patched script in PowerShell for Linux to get the ISO file download URL for
the latest release of Windows 11, and then to download it using `curl`:

```text
PS /mnt/chromeos/removable/Windows Setup/ISO Images> ../Tools/Fido/Fido.ps1 -GetUrl -Win 11 -Rel Latest -Ed Pro -Lang English -PlatformArch x64
https://software.download.prss.microsoft.com/dbazure/Win11_24H2_English_x64.iso?t=7846c51c-1534-4c45-a181-b17869fb881c&P1=1753676554&P2=601&P3=2&P4=Wx6cxYyMxnPzN%2bKCM2jLo5raaYT1xlBmI%2f456sKGzWLWfT2F%2b%2bY%2bhqfWxnPJHHsEKCMvhVj16OmH2D9UistWnNhVlxMuxwBhdGhNrHVzy%2frzoLB43AmqTi2vxqWpNiKbkFm4haSSGOJvGnhiqRyiyJheA0cTWGEio%2bJ8TufXTsJLygFEMCVCT8nA2cGtt8bOhCQqOVy5qeNp0iXm7via%2bJzLyJxiLjHZ%2bdgvSAfdXOMHKxinezHNq%2f%2bwzc3AYoEBjSlmhLt9qXOmvCGdqOlZcTK2kaXoUZV7FpqmPgc%2bS31DyvfDtG%2b2xT1%2bePUUool825T6ZpT9I%2bQfucQPxds7%2fg%3d%3d
PS /mnt/chromeos/removable/Windows Setup/ISO Images> curl --location --remote-name --remote-time "https://software.download.prss.microsoft.com/dbazure/Win11_24H2_English_x64.iso?t=7846c51c-1534-4c45-a181-b17869fb881c&P1=1753676554&P2=601&P3=2&P4=Wx6cxYyMxnPzN%2bKCM2jLo5raaYT1xlBmI%2f456sKGzWLWfT2F%2b%2bY%2bhqfWxnPJHHsEKCMvhVj16OmH2D9UistWnNhVlxMuxwBhdGhNrHVzy%2frzoLB43AmqTi2vxqWpNiKbkFm4haSSGOJvGnhiqRyiyJheA0cTWGEio%2bJ8TufXTsJLygFEMCVCT8nA2cGtt8bOhCQqOVy5qeNp0iXm7via%2bJzLyJxiLjHZ%2bdgvSAfdXOMHKxinezHNq%2f%2bwzc3AYoEBjSlmhLt9qXOmvCGdqOlZcTK2kaXoUZV7FpqmPgc%2bS31DyvfDtG%2b2xT1%2bePUUool825T6ZpT9I%2bQfucQPxds7%2fg%3d%3d"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 5549M  100 5549M    0     0  29.6M      0  0:03:07  0:03:07 --:--:-- 20.5M
PS /mnt/chromeos/removable/Windows Setup/ISO Images>
```

For convenience, wrapper PowerShell scripts that can provide download URLs fir the latest Windows 10 or Windows 11
 release are located in the `ISO Images` folder.  These are:

```text
Download Windows 10 ISO (Latest; x32).ps1
Download Windows 10 ISO (Latest; x64).ps1
Download Windows 11 ISO (Latest).ps1
```

#### Preparing the installation media

The downloaded ISO file can be turned into a bootable USB flash drive using (Rufus)[https://github.com/pbatard/Rufus].

### Gathering software

I gather a point in time snapshot of the software that I may want to install in the Windows environment.  This includes
drivers for the various hardware devices in my arsenal, and software including utilities, productivity tools, special
interest applications, etc.  While I recommend any of this software to others, my selections are based on my personal
interests, such as software development and cybersecurity, and software with which I have gained experience over my
career.  You may have different software preferences based on your interests and experiences.  The software I install in
a given environment depends on the environment's purpose, especially since some of the software may be for interests
that I am not actively pursuing.

I catalog the software in YAML files that can be found in the `Software Library/Definitions` folder.  Here is an
example:

```yaml
---
software:

  - name: VLC v3.0.21
    category: Media Players
    packages:
      - url: https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe
        allow-redirect: true
        sha256: 9742689a50e96ddc04d80ceff046b28da2beefd617be18166f8c5e715ec60c59
```

#### fetch.sh

The `fetch.sh` script will download the software referenced in a YAML definition file, calculate the SHA256 hash for
each file, display a warning if the hash has changed, and update the hash for the file in the YAML file accordingly.

As an example, downloading VLC Media Player, using `fetch.sh` and the YAML definition file shown above, looks like this:

```text
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library$ ../Tools/Fetch/fetch.sh Definitions/Base\ -\ Media\ Players.yaml Downloads/
INFO: Fetching package files for "VLC v3.0.21"...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   125    0   125    0     0    152      0 --:--:-- --:--:-- --:--:--   152
100 42.8M  100 42.8M    0     0   595k      0  0:01:13  0:01:13 --:--:--  379k
INFO: Successfully retrieved package file "Downloads//Media Players/VLC v3.0.21/vlc-3.0.21-win64.exe".
INFO: The SHA256 hash for this package file matches.
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library$
```

If the SHA256 hash for VLC had changed, it would like look like this:

```text
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library$ ../Tools/Fetch/fetch.sh Definitions/Base\ -\ Media\ Players.yaml Downloads/
INFO: Fetching package files for "VLC v3.0.21"...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   127    0   127    0     0    132      0 --:--:-- --:--:-- --:--:--   132
100 42.8M  100 42.8M    0     0   826k      0  0:00:53  0:00:53 --:--:--  620k
INFO: Successfully retrieved package file "Downloads//Media Players/VLC v3.0.21/vlc-3.0.21-win64.exe".
WARNING: The SHA256 hash for this package file has changed.  Is it a new release?
<DIFF>
--- "Definitions/Base - Media Players.yaml"     2025-07-14 18:41:18.612212200 -0500
+++ /tmp/tmp.J8H3QQ5cGE 2025-07-14 18:42:24.895836481 -0500
@@ -1 +0,0 @@
----
@@ -9 +7 @@
-        sha256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
+        sha256: 9742689a50e96ddc04d80ceff046b28da2beefd617be18166f8c5e715ec60c59
</DIFF>
<PATCH>
--- "Definitions/Base - Media Players.yaml"     2025-07-14 18:41:18.612212200 -0500
+++ /tmp/tmp.J8H3QQ5cGE 2025-07-14 18:42:24.895836481 -0500
@@ -9 +0 @@
-        sha256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
+        sha256: 9742689a50e96ddc04d80ceff046b28da2beefd617be18166f8c5e715ec60c59
</PATCH>
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library$
```

The last part in the `<DIFF/>` and `<PATCH/>` tags is debugging information that can be ignored, but I use it to keep an
eye on things.  (Patching a SHA256 hash in the YAML file while preserving comments, whitespace, etc. is complicated.)

#### Reasons for hash mismatches

Reasons a SHA256 hash might change include:

1.  The URL (i.e., a file reference) was added to the YAML file wihout a known hash because it hasn't been previously
downloaded.

2.  The URL is broken and junk got downloaded (e.g., an HTML error page) instead of the expected artifact.

3.  The software uses a rolling release, where the most recent release is always downloaded from the same URL, and a new
release has been made.

4.  The software does not use a rolling release, but the maintainer made a new release without incrementing the version
number (i.e., the maintainer did not update the file name or URL).

5.  The software vendor has a misconfiguration where inconsistent files are returned for the same URL.  For example, the
vendor may have multiple servers with inconsistent content.  Yes, I have seen this happen!

6.  The software has been tampered with in the supply chain.

#### Additional configuration attributes

Additional attributes supported in a YAML definition file include:

##### additional-curl-options

Allows for additional command line options to be passed to the `curl` command, which is used to perform the download.
As an example, AMD's servers require the HTTP `Referer` header to be specified, as shown here:

```yaml
---
software:

  - name: AMD Radeon RX 6000 Series Graphics Adrenalin Edition Drivers v25.6.1
    category: Hardware|AMD Radeon Graphics
    packages:
      - url: https://drivers.amd.com/drivers/whql-amd-software-adrenalin-edition-25.6.1-win10-win11-june5-rdna.exe
        additional-curl-options: '--header ''Referer: https://www.amd.com/'''
        sha256: b7d6bf26289877dc180754068b1692a25f6d2b212178e34a765e08fc72a33b88
```

##### allow-insecure

Allows for the file to be insecurely downloaded over HTTP instead of HTTPS.  By default, HTTP downloads are disallowed.
Occasionally, a file is not avaialble from a properly configured HTTPS endpoint.  Here is an example:

```yaml
---
software:

  - name: API Monitor v2r13 (alpha)
    category: Development|Other
    packages:
      - url: http://www.rohitab.com/download/api-monitor-v2r13-setup-x64.exe
        allow-insecure: true
        allow-redirect: true
        sha256: 46c1f2f4e8dfa8e0c2775b1cc4a20491d7413a87f3d08e8385f1e70dba6756e9
```

##### allow-redirect

Allows redirects to be followed when attempting the download.  By default, redirects are disallowed.  Redirects are not
atypical, but if a download did not require a redirect in the past and one is needed now, it could be an indication of
supply chain tampering.

```yaml
---
software:

  - name: VLC v3.0.21
    category: Media Players
    packages:
      - url: https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe
        allow-redirect: true
        sha256: 9742689a50e96ddc04d80ceff046b28da2beefd617be18166f8c5e715ec60c59
```

#### curl-options

Allows for the default output-related `curl` options (i.e., `-O` or `--remote-name`) to be overridden.  This may be
necessary if `curl` cannot derive the proper name of the output file from the URL or the HTTP response.  Here is an
example:

```yaml
---
software:

  - name: Firefox v140.0 (ESR) [Rolling]
    category: Web Browsers
    packages:
      - url: https://download.mozilla.org/?product=firefox-esr-next-latest-ssl&os=win64&lang=en-US
        curl-options: --output 'Firefox Setup 140.0esr.exe'
        allow-redirect: true
        sha256: 26d2466c67001df976c446aec339e03390c553513ada92ef3191e85fde36f109
```

Here are a few ways this may be used:

```yaml
# Specify an output file name when `curl` can't derive one from the URL or HTTP response.
curl-options: --output 'Firefox Setup 140.0esr.exe'
```

```yaml
# Override the output file name derived by `curl` because the derived name contains URL encoded characters (e.g.,
# `Graphics+Card+Series_multiQIG.pdf`) that `curl` does not decode.
curl-options: --output 'Graphics Card Series_multiQIG.pdf'
```

```yaml
# Tell `curl` to use the file name returned in the HTTP response headers instead of deriving it from the URL.
curl-options: --remote-header-name --remote-name
```

#### Other things to know

Here are some other things to know:

1.  Yes, this process uses a `bash` shell script despite being for gathering Windows related artifacts.  It should be
usable in most Linux environments, including Windows Subsystem for Linux (WSL).  I typically run it from the
Debian-based Linux container on my Chromebook.

2.  It isn't too important to monitor the `fetch.sh` script output for SHA256 hash changes because the differences can
be viewed afterwards using the `git diff` command.  For example:

```text
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library$ git diff
diff --git a/Software Library/Definitions/Base - Media Players.yaml b/Software Library/Definitions/Base - Media Players.yaml
index f9c0004..fc185ec 100644
--- a/Software Library/Definitions/Base - Media Players.yaml
+++ b/Software Library/Definitions/Base - Media Players.yaml
@@ -6,4 +6,4 @@ software:
     packages:
       - url: https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe
         allow-redirect: true
-        sha256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
+        sha256: 9742689a50e96ddc04d80ceff046b28da2beefd617be18166f8c5e715ec60c59
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library$
```

3.  For convenience, wrapper `bash` scripts that download subsets of the provided YAML definition files are located in
the `Software Library` folder.  These are:

```text
fetch-all.sh
fetch-base.sh
fetch-development.sh
fetch-hardware.sh
fetch-special.sh
```

4. Patching a SHA256 hash will fail and cause preceeding long lines to be truncated in a YAML definition file with any
lines longer than about 80 characters.  However, rerunning the `fetch.sh` script multiple times will eventually allow
the SHA256 hash patch to be applied since all preceeding long lines will have been truncted.  Unfortuntely, if this
occurs manual clean up is necessary.

As an example, running the `fetch.sh` script three times on this YAML definition file:

```yaml
---
software:

  # ASRock B550 Phantom Gaming ITXax Motherboard - Documentation
  - name: ASRock B550 Phantom Gaming ITXax Motherboard - Quick Installation Guide v1.0 r20200515 [Rolling]
    category: Hardware|ASRock B550 Phantom Gaming ITXax Desktop
    packages:
      - url: https://download.asrock.com/Manual/QIG/B550+Phantom+Gaming-ITXax_multiQIG.pdf
        curl-options: --output 'B550 Phantom Gaming-ITXax_multiQIG.pdf'
        sha256: 4aa876d76704c269b12d4344498f9b6b43212b893ade2023a5c50f0e762e87e5

  - name: ASRock B550 Phantom Gaming ITXax Motherboard - User Manual v1.0 r20220103 [Rolling]
    category: Hardware|ASRock B550 Phantom Gaming ITXax Desktop
    packages:
      - url: https://download.asrock.com/Manual/B550+Phantom+Gaming-ITXax.pdf
        curl-options: --output 'B550 Phantom Gaming-ITXax.pdf'
        sha256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

results in this `git diff`:

```text
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library$ git diff
diff --git a/Software Library/Definitions/Hardware - ASRock B550 Phantom Gaming ITXax Desktop.yaml b/Software Library/Definitions/Hardware - ASRock B550 Phantom Gaming ITXax Desktop.yaml
index ebb353a..73b6d48 100644
--- a/Software Library/Definitions/Hardware - ASRock B550 Phantom Gaming ITXax Desktop.yaml
+++ b/Software Library/Definitions/Hardware - ASRock B550 Phantom Gaming ITXax Desktop.yaml
@@ -2,19 +2,19 @@
 software:

   # ASRock B550 Phantom Gaming ITXax Motherboard - Documentation
-  - name: ASRock B550 Phantom Gaming ITXax Motherboard - Quick Installation Guide v1.0 r20200515 [Rolling]
+  - name: ASRock B550 Phantom Gaming ITXax Motherboard - Quick Installation Guide
     category: Hardware|ASRock B550 Phantom Gaming ITXax Desktop
     packages:
       - url: https://download.asrock.com/Manual/QIG/B550+Phantom+Gaming-ITXax_multiQIG.pdf
         curl-options: --output 'B550 Phantom Gaming-ITXax_multiQIG.pdf'
         sha256: 4aa876d76704c269b12d4344498f9b6b43212b893ade2023a5c50f0e762e87e5

-  - name: ASRock B550 Phantom Gaming ITXax Motherboard - User Manual v1.0 r20220103 [Rolling]
+  - name: ASRock B550 Phantom Gaming ITXax Motherboard - User Manual v1.0 r20220103
     category: Hardware|ASRock B550 Phantom Gaming ITXax Desktop
     packages:
       - url: https://download.asrock.com/Manual/B550+Phantom+Gaming-ITXax.pdf
         curl-options: --output 'B550 Phantom Gaming-ITXax.pdf'
-        sha256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
+        sha256: 91a84bbb1283d76a6e3002fc2ed3d1978d8116ddbd4415fecfa46181d21b5714
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library$
```

Notice that the two `name` attributes have been truncated, but that the final `sha256` attribute has been correctly
updated.  At this point, the changes to the `name` attributes need to be manually reverted.

This issue is due to the pretty printing functionality in `yq`, the tool used for working with the YAML files,
automatically wrapping long lines.  Unfortunately, there is no documented mechanism to override this line wrapping
behavior.

5.  When using `curl` v7.88.1 (and likely other versions) with the `--output-dir`, `--remote-header-name`,
`--remote-name`, and `--remote-time` options, `curl` fails to set the modification date for the downloaded file.  The
workaround is to explcitly specify the filename using the `--output` option instead of using the `--remote-header-name`
and `--remote-name` options.

This anomaly is shown as follows:

```text
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library/Definitions$ curl --location --output-dir out --remote-header-name --remote-name --remote-time "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   157  100   157    0     0    300      0 --:--:-- --:--:-- --:--:--   300
100  106M  100  106M    0     0  18.8M      0  0:00:05  0:00:05 --:--:-- 23.8M
Warning: Failed to set filetime 1752102077 on 'VSCodeSetup-x64-1.102.0.exe':
Warning: No such file or directory
ccooper@penguin:/mnt/chromeos/removable/Windows Setup/Software Library/Definitions$
```
