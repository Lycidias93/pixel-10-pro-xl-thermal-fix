from pathlib import Path
import subprocess

ROOT = Path.cwd()


def update(path: str, old: str, new: str) -> None:
    file_path = ROOT / path
    text = file_path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one match, found {count}")
    file_path.write_text(text.replace(old, new, 1))


update(
    "tools/zram/apply-zram-100p.sh",
    '  method=aosp_reinit\n  "$SETPROP_BIN" lmkd.reinit 1 2>/dev/null || true\n  if wait_reinit_ack; then\n',
    '  method=aosp_reinit\n  if "$SETPROP_BIN" lmkd.reinit 1 2>/dev/null && wait_reinit_ack; then\n',
)
update(
    "tools/zram/apply-zram-100p.sh",
    '  fi\n\n  method=ctl_restart\n',
    '  fi\n\n  log \'LMKD_RELOAD reinit=failed_or_unacknowledged fallback=ctl_restart\'\n  method=ctl_restart\n',
)
update(
    "service.sh",
    "  printf '%s SERVICE_ZRAM action=apply mode=boot_early resetprop=required mmd_restart=skip eh=deferred lmk=stock\\n' \"$(date -Is 2>/dev/null || date)\" >> \"$L\"\n",
    "  printf '%s SERVICE_ZRAM action=apply mode=boot_early resetprop=required mmd_restart=skip eh=deferred lmk_reload=%s\\n' \\\n    \"$(date -Is 2>/dev/null || date)\" \"${LMKD_SWAP_LOW_RELOAD:-0}\" >> \"$L\"\n",
)
update(
    "service.sh",
    "# Android may rewrite selected ZRAM properties after early service startup.\n# Reapply exactly once after verified boot. This path never mutates the LMKD\n# property; the optional experiment is restricted to post-fs-data.\n",
    "# Android may rewrite selected ZRAM properties after early service startup.\n# Reapply exactly once after verified boot. The consolidated ZRAM helper also\n# applies the opt-in LMKD policy and skips a reload already verified this boot.\n",
)
update(
    "tests/test-dev19-lmkd-early-test.sh",
    ': > "$tmp/reinit"\n',
    ': > "$tmp/reinit"\n: > "$tmp/reinit_fail"\n',
)
update(
    "tests/test-dev19-lmkd-early-test.sh",
    "'  lmkd.reinit) printf \"%s\\\\n\" \"$value\" > \"$REINIT_FILE\"; : > \"$REINIT_FILE\" ;;'",
    "'  lmkd.reinit) if [ -s \"$REINIT_FAIL_FILE\" ]; then exit 1; fi; printf \"%s\\\\n\" \"$value\" > \"$REINIT_FILE\"; : > \"$REINIT_FILE\" ;;'",
)
update(
    "tests/test-dev19-lmkd-early-test.sh",
    '  PROP_FILE="$tmp/property" SERVICE_FILE="$tmp/service" REINIT_FILE="$tmp/reinit" PID_FILE="$tmp/pid" \\\n',
    '  PROP_FILE="$tmp/property" SERVICE_FILE="$tmp/service" REINIT_FILE="$tmp/reinit" REINIT_FAIL_FILE="$tmp/reinit_fail" PID_FILE="$tmp/pid" \\\n',
)
update(
    "tests/test-dev19-lmkd-early-test.sh",
    "grep -Fxq 'LMKD_SWAP_LOW_ORIGINAL_VALUE=100p' \"$tmp/config.env\"\n\n",
    "grep -Fxq 'LMKD_SWAP_LOW_ORIGINAL_VALUE=100p' \"$tmp/config.env\"\n"
    "grep -Fq 'if \"$SETPROP_BIN\" lmkd.reinit 1 2>/dev/null && wait_reinit_ack; then' \"$apply\"\n\n"
    "printf '%s\\n' fail > \"$tmp/reinit_fail\"\n"
    "printf '%s\\n' 100 > \"$tmp/pid\"\n"
    "printf '%s\\n' 10 > \"$tmp/property\"\n"
    "run_apply manual > \"$tmp/fallback.log\"\n"
    "grep -Fq 'LMKD_RELOAD reinit=failed_or_unacknowledged fallback=ctl_restart' \"$tmp/fallback.log\"\n"
    "grep -Fq 'LMKD_RELOAD result=success method=ctl_restart' \"$tmp/fallback.log\"\n"
    "grep -Fxq 'reload_method=ctl_restart' \"$tmp/lmkd-reload.env\"\n"
    "grep -Fxq 'lmkd_pid_before=100' \"$tmp/lmkd-reload.env\"\n"
    "grep -Fxq 'lmkd_pid_after=200' \"$tmp/lmkd-reload.env\"\n"
    ": > \"$tmp/reinit_fail\"\n\n",
)
update(
    "tests/test-dev19-lmkd-early-test.sh",
    "printf '%s\\n' 'PASS dev20_aosp_reinit_first_with_restart_fallback'\n",
    "printf '%s\\n' 'PASS dev20_aosp_reinit_trigger_must_succeed'\n"
    "printf '%s\\n' 'PASS dev20_failed_reinit_uses_verified_restart_fallback'\n",
)
notes = ROOT / "release-notes/2.0.0-alpha.3-dev.20.md"
notes_text = notes.read_text()
needle = "- Uses AOSP `lmkd.reinit` first and a verified daemon restart only as fallback.\n"
replacement = needle + "- Accepts reinit only when the trigger write succeeds and is acknowledged; otherwise it immediately uses the verified restart fallback.\n"
if notes_text.count(needle) != 1:
    raise SystemExit("release notes anchor mismatch")
notes.write_text(notes_text.replace(needle, replacement, 1))

for path in [
    "tools/zram/apply-zram-100p.sh",
    "service.sh",
    "tests/test-dev19-lmkd-early-test.sh",
]:
    subprocess.run(["bash", "-n", path], check=True)
subprocess.run(["bash", "tests/test-dev19-lmkd-early-test.sh"], check=True)
subprocess.run(["bash", "tests/test-release-package-exclusions.sh"], check=True)
print("RESULT: DEV20_REINIT_ACK_HOTFIX_PASS")
