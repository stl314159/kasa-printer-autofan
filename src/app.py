import asyncio
import os
import time
from kasa import Discover, Credentials

async def main():
    kasa_username = os.environ.get("KASA_USERNAME")
    kasa_password = os.environ.get("KASA_PASSWORD")
    printer_alias = os.environ.get("PRINTER_ALIAS")
    fan_alias = os.environ.get("FAN_ALIAS")

    devices = await Discover.discover(
        credentials=Credentials(kasa_username, kasa_password),
        discovery_timeout=10
    )

    printer_device = None
    fan_device = None
    for ip, device in devices.items():
        print(f"IP: {ip}, device: {device}")
        await device.update()
        if device.alias == printer_alias:
            printer_device = device
        elif device.alias == fan_alias:
            fan_device = device

    if printer_device is None or fan_device is None:
        print("Printer or fan device not found.")
        return

    last_low_power_time = None
    while True:
        await printer_device.update()
        power = printer_device.emeter_realtime.power

        if power > 20:
            last_low_power_time = None
            if fan_device.is_off:
                await fan_device.turn_on()
                print("Turning on the fan.")
        else:
            if last_low_power_time is None:
                last_low_power_time = time.time()
            elif time.time() - last_low_power_time >= 300:  # 5 minutes
                if fan_device.is_on:
                    await fan_device.turn_off()
                    print("Turning off the fan.")

        await asyncio.sleep(5)

if __name__ == "__main__":
    asyncio.run(main())
