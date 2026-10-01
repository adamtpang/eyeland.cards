# Windows standalone build

Built September 21, 2026 with Godot 4.7.2 official Windows x86_64 release template.

- Run: `builds/windows/Eyeland.exe` (139,498,096 bytes).
- Share: `builds/Eyeland-Windows.zip` (69,450,036 bytes); unzip first.
- Embedded game pack; no editor, installed Godot, or companion PCK required.
- Includes Godot and font license notices. Unsigned prototype.
- Saves remain in `%APPDATA%/eyeland-godot-mvp`, compatible with the local project.
- Rebuild: run `scripts/build-godot-windows.ps1`. Requires the matching release export template in `%APPDATA%/Godot/export_templates/4.7.2.stable`.

Verification: exported executable launched from an unrelated temporary working directory with isolated APPDATA. Headless first startup and rendered new-player, returning-island, and Collection startups exited 0 with no logged errors. Returning-user checks used a copied automated journey fixture, not Adam's live profile. ZIP inventory contains only executable, readme and license notices. External `--script` battle harness did not start in the release runtime and was stopped; no exported full battle test is claimed. Native project battle regression evidence remains in `godot/PARITY.md`.

Executable SHA256: `EC231F63C801E063F8E6F238337682F519DC99FE3C100E86F269F3B1D621680A`.

September 21 art rebuild: 100 distinct card illustrations, illustrated tabletop and interface improvements included. `verify-godot-export.gd` loaded the embedded pack in an isolated minimal project, decoded all 100 portraits and rendered a battle fixture with zero failures. This uses the matching Godot runtime as a pack verifier; it is distinct from a full match inside the release executable. The release executable itself rendered startup and exited 0 without logged errors. Live user saves were not used by verification.
