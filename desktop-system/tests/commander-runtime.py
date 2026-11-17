import json
from pathlib import Path
import shutil
import subprocess

root = Path(__file__).resolve().parent.parent
command = [
    "nix", "eval", "--option", "allow-import-from-derivation", "false", "--json",
    '.#homeConfigurations."jack@merlin".config',
    "--apply",
    "c: { sessionText = c.home.sessionVariablesPackage.text; service = c.systemd.user.services.figaro-commander.Service; }",
]
result = subprocess.run(command, cwd=root, capture_output=True, text=True, check=True)
rendered = json.loads(result.stdout)
assignments = [line for line in rendered["sessionText"].splitlines() if line.startswith("export FIGARO_RUNTIME_DIR=")]
assert len(assignments) == 1
assignment = assignments[0]
service = rendered["service"]
instance = service["RuntimeDirectory"]
assert assignment == 'export FIGARO_RUNTIME_DIR="${XDG_RUNTIME_DIR}/' + instance + '"'
service_runtime = [value.removeprefix("FIGARO_RUNTIME_DIR=") for value in service["Environment"] if value.startswith("FIGARO_RUNTIME_DIR=")]
assert service_runtime == ["%t/" + instance]
assert "FIGARO_ARIA" in service["UnsetEnvironment"]
for directory in ["/run/user/1000", "/run/user/2187"]:
    output = subprocess.run(
        [shutil.which("bash"), "-euc", assignment + '; printf "%s" "$FIGARO_RUNTIME_DIR"'],
        env={"XDG_RUNTIME_DIR": directory}, capture_output=True, text=True, check=True,
    ).stdout
    assert output == service_runtime[0].replace("%t", directory)
print("Rendered CLI runtime export expands at login and matches the user service for both UIDs.")
