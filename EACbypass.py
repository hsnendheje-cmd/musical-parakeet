import os
import sys
import subprocess
import time
import ctypes

try:
    import psutil
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psutil", "--quiet"])
    import psutil

GAME_DIR = r"C:\Program Files (x86)\Steam\steamapps\common\Animal Company"
BRIDGE_SCRIPT = "ac_bridge.js"
BYPASS_SCRIPT = "bypass.js"

PURPLE = "\033[38;5;242m"
LPURPLE = "\033[38;5;250m"
DPURPLE = "\033[38;5;236m"
WHITE = "\033[97m"
GRAY = "\033[90m"
RESET = "\033[0m"
BOLD = "\033[1m"

def enable_ansi():
    try:
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except:
        pass

def spin_msg(msg, duration=1.0):
    frames = ["/", "-", "\\", "|"]
    end_time = time.time() + duration
    i = 0
    while time.time() < end_time:
        c = frames[i % 4]
        sys.stdout.write(f"\r\033[2K{GRAY}   [{c}]{RESET} {msg}")
        sys.stdout.flush()
        time.sleep(0.1)
        i += 1
    sys.stdout.write(f"\r\033[2K")
    sys.stdout.flush()

def replace_ini():
    ini_path = os.path.join(GAME_DIR, INI_FILE)
    try:
        if os.path.exists(ini_path):
            os.remove(ini_path)
        with open(ini_path, 'w') as f:
            f.write("ApplicationPath=AnimalCompany.exe\n")
            f.write("WorkingDirectory=\n")
            f.write("WaitForExit=0\n")
            f.write("NoOperation=false\n")
        print(f"{LPURPLE}   [+] {RESET}Launcher INI replaced")
        return True
    except Exception as e:
        print(f"{LPURPLE}   [x] {RESET}Failed: {e}")
        return False

def start_frida_wait():
    script_path = os.path.join(os.path.dirname(os.path.abspath(sys.argv[0])), BYPASS_SCRIPT)
    if not os.path.exists(script_path):
        print(f"{LPURPLE}   [x] {RESET}{BYPASS_SCRIPT} not found!")
        return False
    try:
        spin_msg("Checking frida installation...")
        check = subprocess.run(['frida', '--version'], capture_output=True, text=True)
        if check.returncode != 0:
            print(f"{LPURPLE}   [x] {RESET}Frida not found!")
            return False
        print(f"{LPURPLE}   [+] {RESET}Frida {check.stdout.strip()} ready")
        return True
    except FileNotFoundError:
        print(f"{LPURPLE}   [x] {RESET}Frida not found! Install: pip install frida-tools")
        return False
    except Exception as e:
        print(f"{LPURPLE}   [x] {RESET}Failed: {e}")
        return False

def restore_launcher():
    bak_path = os.path.join(GAME_DIR, "EACLauncher.exe.bak")
    exe_path = os.path.join(GAME_DIR, "EACLauncher.exe")
    try:
        if os.path.exists(bak_path):
            import shutil
            shutil.copy2(bak_path, exe_path)
            os.remove(bak_path)
    except:
        pass

def build_dummy_launcher():
    print(f"{LPURPLE}   [~] {RESET}Checking launcher...")
    try:
        import tempfile
        import shutil

        eac_path = os.path.join(GAME_DIR, "EACLauncher.exe")
        backup_path = os.path.join(GAME_DIR, "EACLauncher.exe.bak")
        game_path = os.path.join(GAME_DIR, "AnimalCompany.exe")

        if os.path.exists(backup_path):
            print(f"{LPURPLE}   [+] {RESET}Launcher ready")
            return True

        if not os.path.exists(eac_path):
            print(f"{LPURPLE}   [x] {RESET}EACLauncher.exe not found!")
            return False

        try:
            check_py = subprocess.run([sys.executable, '-c', 'import PyInstaller'], capture_output=True)
            if check_py.returncode != 0:
                print(f"{LPURPLE}   [~] {RESET}Installing pyinstaller...")
                subprocess.check_call([sys.executable, "-m", "pip", "install", "pyinstaller", "--quiet"])
        except:
            pass

        tmp_dir = tempfile.mkdtemp()
        launcher_py = os.path.join(tmp_dir, "make_launcher.py")
        with open(launcher_py, "w") as f:
            f.write('import subprocess, os, sys\n')
            f.write('game_dir = os.path.dirname(os.path.abspath(sys.argv[0]))\n')
            f.write('game_exe = os.path.join(game_dir, "AnimalCompany.exe")\n')
            f.write('subprocess.Popen([game_exe], cwd=game_dir)\n')

        shutil.copy2(eac_path, backup_path)

        result = subprocess.run(
            ['pyinstaller', '--onefile', '--noconsole', '--name', 'EACLauncher', launcher_py],
            capture_output=True, text=True, cwd=tmp_dir
        )

        if result.returncode != 0:
            print(f"{LPURPLE}   [x] {RESET}PyInstaller failed")
            if os.path.exists(backup_path):
                os.remove(backup_path)
            shutil.rmtree(tmp_dir, ignore_errors=True)
            return False

        dummy_path = os.path.join(tmp_dir, "dist", "EACLauncher.exe")
        if os.path.exists(dummy_path):
            shutil.copy2(dummy_path, eac_path)
            shutil.rmtree(tmp_dir, ignore_errors=True)
            print(f"{LPURPLE}   [+] {RESET}Dummy launcher built")
            return True
        else:
            print(f"{LPURPLE}   [x] {RESET}Build output not found")
            if os.path.exists(backup_path):
                os.remove(backup_path)
            shutil.rmtree(tmp_dir, ignore_errors=True)
            return False
    except Exception as e:
        print(f"{LPURPLE}   [x] {RESET}Failed: {e}")
        return False

def is_process_running(process_name):
    for proc in psutil.process_iter(['name']):
        try:
            if proc.info['name'].lower() == process_name.lower():
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    return False

def inject_frida():
    bridge_path = os.path.join(os.path.dirname(os.path.abspath(sys.argv[0])), BRIDGE_SCRIPT)
    script_path = os.path.join(os.path.dirname(os.path.abspath(sys.argv[0])), BYPASS_SCRIPT)
    try:
        print(f"{LPURPLE}   [!] {RESET}Game detected! Injecting bypass...")
        print()
        time.sleep(1.0)
        subprocess.Popen(
            ['cmd', '/k', 'frida', '-l', bridge_path, '-l', script_path, '-l', quest_path, 'AnimalCompany.exe'],
            creationflags=subprocess.CREATE_NEW_CONSOLE,
            cwd=os.path.dirname(os.path.abspath(sys.argv[0]))
        )
        return True
    except Exception as e:
        print(f"{LPURPLE}   [x] {RESET}Injection failed: {e}")
        return False

def monitor_frida():
    print()
    print(f"{GRAY}   ────────────────────────────────────────────────────{RESET}")
    print(f"{WHITE}{BOLD}        Looking For Animal Company...{RESET}")
    print(f"{GRAY}   ────────────────────────────────────────────────────{RESET}")
    print()
    print()
    print(f"{WHITE}   Launch Animal Company from Steam{RESET}")
    print()
    print(f"{GRAY}   Keep this window open!{RESET}")
    print()
    injected = False
    try:
        while True:
            if not injected and is_process_running("AnimalCompany.exe"):
                if inject_frida():
                    injected = True
                    print(f"{LPURPLE}   [+] {RESET}Bypass injected!")
                    print()
                    print(f"{GRAY}   ────────────────────────────────────────────────────{RESET}")
                    print(f"{WHITE}{BOLD}                    BYPASSED{RESET}")
                    print(f"{GRAY}   ────────────────────────────────────────────────────{RESET}")
                    print()
                    print(f"{GRAY}   Waiting for game to close...{RESET}")
                    print()
            if injected and not is_process_running("AnimalCompany.exe"):
                print(f"{DPURPLE}   Game closed. Exiting...{RESET}")
                print()
                break
            time.sleep(0.5)
    except KeyboardInterrupt:
        print()
        print(f"{DPURPLE}   Exiting...{RESET}")
        print()

def main():
    enable_ansi()
    os.system("cls")
    restore_launcher()
    print()
    print(f"{DPURPLE}{BOLD}            ███████ ██    ██ ████████ ███████ {RESET}")
    print(f"{DPURPLE}{BOLD}            ██       ██  ██     ██    ██      {RESET}")
    print(f"{PURPLE}{BOLD}            ███████   ████      ██    █████   {RESET}")
    print(f"{PURPLE}{BOLD}                 ██    ██       ██    ██      {RESET}")
    print(f"{LPURPLE}{BOLD}            ███████    ██       ██    ███████ {RESET}")
    print()
    print(f"{GRAY}   ────────────────────────────────────────────────────{RESET}")
    print()
    print(f"{LPURPLE}                Complete EAC Bypass{RESET}")
    print(f"{GRAY}                     Made by Byte!{RESET}")
    print(f"{GRAY}                     discord.gg/syte{RESET}")
    print()
    print(f"{GRAY}   ────────────────────────────────────────────────────{RESET}")
    print()
    if not build_dummy_launcher():
        print()
        input(f"{GRAY}   Press Enter to exit...{RESET}")
        return 1
    print()
    if not start_frida_wait():
        print()
        input(f"{GRAY}   Press Enter to exit...{RESET}")
        return 1
    print()
    monitor_frida()
    print()
    print(f"{DPURPLE}   Session ended.{RESET}")
    print()
    return 0

if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print(f"\n\n{LPURPLE}   [!] {RESET}Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n{LPURPLE}   [x] {RESET}Error: {e}")
        print()
        input(f"{GRAY}   Press Enter to exit...{RESET}")
        sys.exit(1)
