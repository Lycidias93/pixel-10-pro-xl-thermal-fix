import os
import subprocess

paths = [
    r"C:\Program Files\Git\bin\sh.exe",
    r"C:\Program Files\Git\bin\bash.exe",
    r"C:\Program Files\Git\usr\bin\sh.exe",
    r"C:\Program Files\Git\usr\bin\bash.exe",
    os.path.expandvars(r"%USERPROFILE%\AppData\Local\Programs\Git\bin\sh.exe"),
]

shell_exe = None
for p in paths:
    if os.path.exists(p):
        shell_exe = p
        break

if not shell_exe:
    import shutil
    shell_exe = shutil.which("sh") or shutil.which("bash")

if not shell_exe:
    print("Error: Could not find sh.exe or bash.exe on the system.")
    exit(1)

print(f"Using shell: {shell_exe}")

os.makedirs("scratch/originals", exist_ok=True)
os.makedirs("scratch/output", exist_ok=True)

# Run test-patch.sh using the POSIX shell
cmd = [shell_exe, "scratch/test-patch.sh", "mod", "outdoor-plus"]
res = subprocess.run(cmd, capture_output=True, text=True)

print("STDOUT:")
print(res.stdout)
print("STDERR:")
print(res.stderr)
print(f"Exit code: {res.returncode}")
