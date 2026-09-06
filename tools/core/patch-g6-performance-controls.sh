#!/system/bin/sh
# Tensor G6 performance-control patcher for thermal_info_config_common.json.
# Changes only the explicitly admitted Pixel 11 recovery/passive fields.
set -eu
LC_ALL=C
export LC_ALL

SOURCE_FILE="${1:-}"
OUTPUT_FILE="${2:-}"
RECOVERY_MODE="${3:-stock}"
PASSIVE_MODE="${4:-stock}"
METRICS_FILE="${5:-}"

[ -s "$SOURCE_FILE" ] || exit 2
[ -n "$OUTPUT_FILE" ] || exit 3
[ -n "$METRICS_FILE" ] || exit 4
case "$RECOVERY_MODE" in stock|mod) ;; *) exit 5 ;; esac
case "$PASSIVE_MODE" in stock|mod) ;; *) exit 6 ;; esac

awk -v recovery_mode="$RECOVERY_MODE" -v passive_mode="$PASSIVE_MODE" -v metrics="$METRICS_FILE" '
  function sensor_name(line, name) {
    if (!match(line, /"Name"[[:space:]]*:[[:space:]]*"[^"]+"/)) return ""
    name=substr(line,RSTART,RLENGTH)
    sub(/^.*:[[:space:]]*"/,"",name); sub(/"$/,"",name)
    return name
  }
  function is_target(name) {
    return name=="VIRTUAL-SKIN" ||
      name=="VIRTUAL-SKIN-HINT" ||
      name=="VIRTUAL-SKIN-CPU-LIGHT-ODPM" ||
      name=="VIRTUAL-SKIN-CPU-MID" ||
      name=="VIRTUAL-SKIN-CPU-ODPM" ||
      name=="VIRTUAL-SKIN-CPU-HIGH" ||
      name=="VIRTUAL-SKIN-SOC"
  }
  function is_cpu_target(name) {
    return name=="VIRTUAL-SKIN-CPU-LIGHT-ODPM" ||
      name=="VIRTUAL-SKIN-CPU-MID" ||
      name=="VIRTUAL-SKIN-CPU-ODPM" ||
      name=="VIRTUAL-SKIN-CPU-HIGH"
  }
  function is_mrs_target(name) { return is_cpu_target(name) || name=="VIRTUAL-SKIN-SOC" }
  function expected_hys(name, idx) {
    if (name=="VIRTUAL-SKIN" || name=="VIRTUAL-SKIN-HINT") {
      if (idx==1) return "0"
      if (idx==2 || idx==3 || idx==4) return "1.9"
      if (idx==5) return "1.4"
      if (idx==6 || idx==7) return "1.9"
    }
    if (is_cpu_target(name)) {
      if (idx==1 || idx==2 || idx==4 || idx==5 || idx==6 || idx==7) return "0"
      if (idx==3) return "1.9"
    }
    if (name=="VIRTUAL-SKIN-SOC") {
      if (idx==1 || idx==2) return "0"
      if (idx==3 || idx==4 || idx==5) return "1.9"
      if (idx==6) return "1.4"
      if (idx==7) return "1.9"
    }
    return "__invalid__"
  }
  function mod_hys(name, idx) {
    if (name=="VIRTUAL-SKIN" || name=="VIRTUAL-SKIN-HINT") return idx>=2 && idx<=5
    if (is_cpu_target(name)) return idx==3
    if (name=="VIRTUAL-SKIN-SOC") return idx>=3 && idx<=5
    return 0
  }
  function process_hys_text(text, name, out, tok, expected) {
    out=""
    while (match(text, /[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)/)) {
      tok=substr(text,RSTART,RLENGTH)
      hys_idx++
      expected=expected_hys(name,hys_idx)
      if (expected=="__invalid__" || (tok+0)!=(expected+0)) bad=1
      if (recovery_mode=="mod" && mod_hys(name,hys_idx)) {
        out=out substr(text,1,RSTART-1) "1.0"
        if ((tok+0)!=1.0) hys_changes++
      } else {
        out=out substr(text,1,RSTART-1) tok
      }
      text=substr(text,RSTART+RLENGTH)
    }
    return out text
  }
  function patch_scalar(line, key, expected, replacement, enabled, token, val) {
    scalar_pattern="\"" key "\"[[:space:]]*:[[:space:]]*[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)"
    if (!match(line, scalar_pattern)) return line
    token=substr(line,RSTART,RLENGTH)
    val=token
    sub(/^.*:[[:space:]]*/,"",val)
    if ((val+0)!=(expected+0)) { bad=1; return line }
    if (!enabled) return line
    sub(/[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$/, replacement, token)
    return substr(line,1,RSTART-1) token substr(line,RSTART+RLENGTH)
  }
  BEGIN {
    current=""
    in_hys=0
    hys_idx=0
    hys_seen=0
    mrs_seen=0
    passive_seen=0
    hys_changes=0
    mrs_changes=0
    passive_changes=0
    bad=0
  }
  {
    line=$0
    name=sensor_name(line)
    if (name!="") current=name

    if (in_hys) {
      closing=index(line,"]")
      if (closing>0) {
        line=process_hys_text(substr(line,1,closing-1),hys_name) substr(line,closing)
        if (hys_idx!=7) bad=1
        in_hys=0
        hys_idx=0
        hys_name=""
      } else {
        line=process_hys_text(line,hys_name)
      }
    } else if (is_target(current) && line ~ /"HotHysteresis"[[:space:]]*:/) {
      if (seen_hys[current]++) bad=1
      hys_seen++
      hys_name=current
      hys_idx=0
      open=index(line,"[")
      if (open<1) {
        bad=1
      } else {
        rest=substr(line,open+1)
        closing=index(rest,"]")
        if (closing>0) {
          line=substr(line,1,open) process_hys_text(substr(rest,1,closing-1),current) substr(rest,closing)
          if (hys_idx!=7) bad=1
          hys_idx=0
          hys_name=""
        } else {
          line=substr(line,1,open) process_hys_text(rest,current)
          in_hys=1
        }
      }
    }

    if (is_mrs_target(current) && line ~ /"MaxReleaseStep"[[:space:]]*:/) {
      if (seen_mrs[current]++) bad=1
      mrs_seen++
      before=line
      line=patch_scalar(line,"MaxReleaseStep",1,2,recovery_mode=="mod")
      if (recovery_mode=="mod" && line!=before) mrs_changes++
    }

    if (is_target(current) && line ~ /"PassiveDelay"[[:space:]]*:/) {
      if (seen_passive[current]++) bad=1
      passive_seen++
      before=line
      line=patch_scalar(line,"PassiveDelay",7000,5000,passive_mode=="mod")
      if (passive_mode=="mod" && line!=before) passive_changes++
    }

    print line
  }
  END {
    if (in_hys) bad=1
    if (hys_seen!=7 || mrs_seen!=5 || passive_seen!=7) bad=1
    if (recovery_mode=="mod" && (hys_changes<1 || mrs_changes!=5)) bad=1
    if (recovery_mode=="stock" && (hys_changes!=0 || mrs_changes!=0)) bad=1
    if (passive_mode=="mod" && passive_changes!=7) bad=1
    if (passive_mode=="stock" && passive_changes!=0) bad=1
    if (bad) exit 40
    printf "PIXEL11_HYSTERESIS_ARRAYS=%d\n", hys_seen > metrics
    printf "PIXEL11_MRS_TARGETS=%d\n", mrs_seen >> metrics
    printf "PIXEL11_PASSIVE_TARGETS=%d\n", passive_seen >> metrics
    printf "PIXEL11_HYSTERESIS_CHANGES=%d\n", hys_changes >> metrics
    printf "PIXEL11_MRS_CHANGES=%d\n", mrs_changes >> metrics
    printf "PIXEL11_PASSIVE_CHANGES=%d\n", passive_changes >> metrics
  }
' "$SOURCE_FILE" > "$OUTPUT_FILE"
