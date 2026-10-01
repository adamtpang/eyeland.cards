# Local runtime note

The historical Program Files Unity editor was absent (only Hub metadata remained). This session downloaded the official 6000.5.7f1 editor and WebGL module via Unity CLI. CLI installation to the protected default folder failed. A standard-user installation was restored under:

`C:/Users/adamp/AppData/Local/EyelandTools/Unity/6000.5.7f1/Editor/Unity.exe`

Editor and WebGL installers both exited 0. All ten Unity PlayMode tests passed. The only missing dependency reported is a remote-profiler inbound firewall rule; local build/testing works without it and firewall settings were not changed.

No global editor path or default version was changed. See MVP-READINESS.md for actual validation status. The existing project remains Unity 6000.5.7f1.
