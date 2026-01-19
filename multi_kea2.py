import subprocess
import os
from datetime import datetime
from concurrent.futures import ProcessPoolExecutor, as_completed


def get_connected_devices():
    result = subprocess.run("adb devices", shell=True, capture_output=True, text=True)
    devices = [line.split('\t')[0].strip() for line in result.stdout.splitlines() if '\tdevice' in line]
    return devices


def run_kea2_on_device(device_serial, package="com.vivago.ai",
                       running_minutes=1, throttle=200):
    """在独立目录运行 kea2，保留原生 HTML 报告"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    device_dir = f"kea2_run_{device_serial.replace(':', '_')}_{timestamp}"
    os.makedirs(device_dir, exist_ok=True)

    cmd = [
        "kea2", "run",
        "-p", package,
        "--running-minutes", str(running_minutes),
        "--throttle", str(throttle),
        "--serial", device_serial
    ]

    print(f"[{device_serial}] 启动测试，工作目录：{device_dir}")
    print(f"[{device_serial}] 报告将生成在：{device_dir}/report.html (或类似)")

    # 切换到设备目录运行，确保报告文件落在该目录
    try:
        result = subprocess.run(
            cmd,
            cwd=device_dir,  # 关键：指定工作目录
            capture_output=True,
            text=True,
            check=True
        )
        print(f"[{device_serial}] 测试完成，报告已生成")
        return True, device_dir
    except subprocess.CalledProcessError as e:
        print(f"[{device_serial}] 测试失败：{e}")
        return False, device_dir


def main():
    devices = get_connected_devices()
    if not devices:
        print("没有检测到任何设备")
        return

    print(f"发现 {len(devices)} 台设备：{', '.join(devices)}")
    print("开始多设备并发压力测试...")

    with ProcessPoolExecutor(max_workers=None) as executor:  # None = 使用所有CPU核心
        future_to_device = {
            executor.submit(run_kea2_on_device, dev): dev
            for dev in devices
        }

        for future in as_completed(future_to_device):
            device = future_to_device[future]
            success, log_dir = future.result()
            status = "成功" if success else "失败"
            print(f"设备 {device} 测试结束：{status}，日志目录：{log_dir}")


if __name__ == "__main__":
    main()