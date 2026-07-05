#!/usr/bin/env python3
"""Read system stats from /proc and /sys instead of spawning top/nvidia-smi.

Outputs tab-separated lines for QML parsing:
CPU <usage_pct>
MEM <used_mb> <total_mb>
CPUT <temp_celsius>
DISK <total> <used> <free>
PROC <pid> <name> <cpu_pct> [...]

Single subprocess call, zero fork overhead.
"""
import os, json

def read_int(path):
    try:
        with open(path) as f:
            return int(f.read().strip())
    except (IOError, ValueError):
        return None

def cpu_usage():
    try:
        _prefix = os.environ.get("APP_ENV_PREFIX", "AURA_OS")
        _app_name = os.environ.get("APP_NAME", "aura-os")
        cache_dir = os.environ.get(_prefix + "_CACHE_DIR", os.path.expanduser("~/.cache/" + _app_name))
        state_file = os.path.join(cache_dir, "cpu_stat.txt")
        with open("/proc/stat") as f:
            line = f.readline()
        parts = line.strip().split()
        if len(parts) < 5:
            return 0
        user = int(parts[1])
        nice = int(parts[2])
        sys = int(parts[3])
        idle = int(parts[4])
        total = user + nice + sys + idle
        try:
            with open(state_file) as f:
                prev_total, prev_idle = f.read().strip().split()
                prev_total = int(prev_total)
                prev_idle = int(prev_idle)
            dtotal = total - prev_total
            didle = idle - prev_idle
            if dtotal > 0:
                with open(state_file, "w") as f:
                    f.write(f"{total} {idle}")
                return round((dtotal - didle) / dtotal * 100)
        except (IOError, ValueError):
            pass
        os.makedirs(os.path.dirname(state_file), exist_ok=True)
        with open(state_file, "w") as f:
            f.write(f"{total} {idle}")
        return 0
    except:
        return 0

def memory():
    try:
        with open("/proc/meminfo") as f:
            data = f.read()
        total = int([l for l in data.split("\n") if "MemTotal" in l][0].split()[1]) // 1024
        free = int([l for l in data.split("\n") if "MemAvailable" in l][0].split()[1]) // 1024
        return (total - free, total)
    except:
        return (0, 0)

def cpu_temp():
    base = "/sys/class/thermal"
    if not os.path.isdir(base):
        return None
    for entry in sorted(os.listdir(base)):
        tpath = os.path.join(base, entry, "temp")
        val = read_int(tpath)
        if val and val > 0:
            return round(val / 1000)
    return None

def disk():
    try:
        stat = os.statvfs("/")
        total = stat.f_frsize * stat.f_blocks
        free = stat.f_frsize * stat.f_bavail
        used = total - free
        for unit, divisor in [("T", 1<<40), ("G", 1<<30)]:
            if total >= divisor * 100:
                return (f"{total/divisor:.1f}", f"{used/divisor:.1f}", f"{free/divisor:.1f}")
        return (f"{total/(1<<30):.1f}", f"{used/(1<<30):.1f}", f"{free/(1<<30):.1f}")
    except:
        return ("0", "0", "0")

def top_cpu_procs(count=5):
    try:
        import subprocess
        result = subprocess.run(
            ["ps", "-eo", "pid,comm,%cpu", "--sort=-%cpu", "--no-headers"],
            capture_output=True, text=True, timeout=2
        )
        lines = result.stdout.strip().split("\n")[:count]
        procs = []
        for line in lines:
            p = line.strip().split(None, 2)
            if len(p) >= 3:
                procs.append((p[0], p[1], p[2]))
        return procs
    except:
        return [("0", "none", "0")]

def top_mem_procs(count=5):
    try:
        import subprocess
        result = subprocess.run(
            ["ps", "-eo", "pid,comm,rss", "--sort=-rss", "--no-headers"],
            capture_output=True, text=True, timeout=2
        )
        lines = result.stdout.strip().split("\n")[:count]
        procs = []
        for line in lines:
            p = line.strip().split(None, 2)
            if len(p) >= 3:
                mem_mb = round(int(p[2]) / 1024, 1)
                procs.append((p[0], p[1], str(mem_mb)))
        return procs
    except:
        return [("0", "none", "0")]

cpu = cpu_usage()
mem_used, mem_total = memory()
cput = cpu_temp()
d_total, d_used, d_free = disk()
cpu_procs = top_cpu_procs()
mem_procs = top_mem_procs()

def uptime_str():
    try:
        with open("/proc/uptime") as f:
            secs = int(float(f.read().split()[0]))
        d, rem = divmod(secs, 86400)
        h, rem = divmod(rem, 3600)
        m = rem // 60
        if d > 0:
            return f"{d}d {h}h {m}m"
        if h > 0:
            return f"{h}h {m}m"
        return f"{m}m"
    except (IOError, ValueError):
        return ""

print(f"CPU {cpu}")
print(f"UPTIME {uptime_str()}")
print(f"MEM {mem_used} {mem_total}")
print(f"CPUT {cput if cput else 'N/A'}")
print(f"DISK {d_total} {d_used} {d_free}")
print("PROC_START")
for pid, cmd, pct in cpu_procs:
    print(f"{pid} {cmd} {pct}")
print("PROC_END")
print("MEM_PROC_START")
for pid, cmd, mb in mem_procs:
    print(f"{pid} {cmd} {mb}")
print("MEM_PROC_END")
