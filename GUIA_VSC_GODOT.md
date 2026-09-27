# Guía: Conectar VS Code con Godot 4.x (DashRunner y cualquier proyecto)

Esta guía deja el proyecto listo para que cualquier agente/edición en VSC impacte en Godot con "Reload from disk".

## 1. Requisitos (ya instalados en este equipo)
- Godot 4.4.1 `C:\Users\User\Desktop\godot\Godot_v4.4.1-stable_win64.exe`
- VS Code `C:\Users\User\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd`
- Extensión VS Code: `godot-tools` (buscá "Godot Tools" en Marketplace)

## 2. Configurar Godot (una vez por máquina)
Archivo: `%APPDATA%\Godot\editor_settings-4.tres` (`C:\Users\User\AppData\Roaming\Godot\editor_settings-4.tres`)

Editar estas 3 líneas (`editor_settings-4.tres:87-89`):
```
text_editor/external/use_external_editor = true
text_editor/external/exec_path = "C:\\Users\\User\\AppData\\Local\\Programs\\Microsoft VS Code\\bin\\code.cmd"
text_editor/external/exec_flags = "{project} --goto {file}:{line}:{col}"
```
Otras claves que deben quedar así:
```
text_editor/behavior/files/auto_reload_and_parse_scripts_on_save = true  # editor_settings-4.tres:85
network/language_server/remote_port = 6005                                # editor_settings-4.tres:119
network/language_server/remote_host = "127.0.0.1"
```
Luego **reiniciar Godot** para que tome los cambios.

## 3. Configurar VS Code por proyecto
Crear `.\.vscode\settings.json` en la raíz del proyecto (ej: `DashRunner\.vscode\settings.json`):
```json
{
    "godotTools.editorPath": "C:/Users/User/Desktop/godot/Godot_v4.4.1-stable_win64.exe",
    "godotTools.gdscript.lsp.serverPort": 6005,
    "files.autoSave": "afterDelay",
    "files.watcherExclude": {
        "**/.godot/**": true
    }
}
```
- `editorPath` debe apuntar al exe de Godot.
- `serverPort` debe coincidir con `remote_port` de Godot (6005).
- `files.watcherExclude` evita ruido del cache `.godot/`.

Recargar VS Code: `Ctrl+Shift+P` > `Developer: Reload Window`.

## 4. Flujo de trabajo diario
1. Abrir Godot con el proyecto (`project.godot`) y también abrir la misma carpeta en VS Code.
2. Editar `.gd` / `.tscn` en VS Code y guardar (`Ctrl+S` o autoSave).
3. Hacer foco en Godot (Alt+Tab). El FileSystem watcher detecta `mtime` cambiado y muestra arriba **"Reload from disk?"** > `Reload` (o recarga auto si está activado).
4. Probar con `F5` (Run) o `F6` (Run Current Scene).

Si no aparece el cartel: `File > Reload Saved Scenes` en Godot, o reiniciar Godot.

## 5. Verificación rápida (para agentes)
```powershell
# 1. Comprobar Godot corriendo y puerto LSP
tasklist /FI "IMAGENAME eq Godot_v4.4.1-stable_win64.exe"
Get-Content "$env:APPDATA\Godot\editor_settings-4.tres" | Select-String "external|remote_port|auto_reload"

# 2. Comprobar .vscode
Get-Content ".\.vscode\settings.json"

# 3. Forzar recarga (tocar un .gd)
(Get-Item ".\scripts\Dash.gd").LastWriteTime = Get-Date
```

## 6. Troubleshooting
- **No aparece cartel**: verificar `use_external_editor = true` + reiniciar Godot. Antivirus puede bloquear watcher.
- **LSP no conecta**: puerto 6005 ocupado > cambiar en ambos lados y reiniciar.
- **Cambios en `.godot/` no recargan**: es intencional, está excluido.
- **Doble apertura**: no abrir el mismo `.gd` en editor interno de Godot y VSC a la vez con cambios sin guardar.

## 7. Para replicar en otro proyecto
Copiar `.vscode/settings.json` a la nueva carpeta, ajustar `editorPath` si cambia la versión de Godot, y repetir paso 2 si es otra PC. El agente puede hacerlo automático editando `editor_settings-4.tres` y creando `.vscode/settings.json`.
