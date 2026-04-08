import csv
import os
import sys
import time
from datetime import datetime

import serial


PORT = "COM3"          
BAUDRATE = 115200
TIMEOUT_S = 1.0
OUTPUT_DIR = "logs"

CSV_HEADER = "t,r,y_raw,y_avg,ym,e,e_ad,u,theta1,theta2,theta3,y_pb,Ts,vent"


def make_output_path() -> str:
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    return os.path.join(OUTPUT_DIR, f"experiment_{timestamp}.csv")


def print_red(text: str) -> None:
    print(f"\033[31m{text}\033[0m")


def main() -> None:
    output_path = make_output_path()

    print(f"Opening serial port: {PORT} @ {BAUDRATE}")
    print(f"Output file: {output_path}")

    try:
        with serial.Serial(PORT, BAUDRATE, timeout=TIMEOUT_S) as ser:
            # Let Arduino reset after opening the port
            time.sleep(2.0)

            print("Waiting for READY...")

            while True:
                raw_line = ser.readline()
                if not raw_line:
                    continue

                line = raw_line.decode("utf-8", errors="replace").strip()
                if not line:
                    continue

                print(f"RX: {line}")
                if line == "READY":
                    break

            with open(output_path, "w", newline="", encoding="utf-8") as csv_file:
                writer = csv.writer(csv_file)

                print("Sending START...")
                ser.write(b"START\n")
                ser.flush()

                header_received = False

                while True:
                    raw_line = ser.readline()
                    if not raw_line:
                        continue

                    line = raw_line.decode("utf-8", errors="replace").strip()
                    if not line:
                        continue

                    if line == "DONE":
                        print("Experiment finished.")
                        break

                    if line == "STOPPED":
                        print("Experiment stopped.")
                        break

                    if not header_received:
                        if line == CSV_HEADER:
                            writer.writerow(line.split(","))
                            csv_file.flush()
                            header_received = True
                            print("CSV header received. Logging started.")
                        else:
                            print(f"Skipping: {line}")
                        continue

                    parts = [part.strip() for part in line.split(",")]
                    writer.writerow(parts)
                    csv_file.flush()

                    warn_ts = len(parts) >= 11 and parts[10] == "1"
                    if warn_ts:
                        print_red(line)
                    else:
                        print(line)

    except serial.SerialException as exc:
        print(f"Serial error: {exc}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nInterrupted by user.")


if __name__ == "__main__":
    main()