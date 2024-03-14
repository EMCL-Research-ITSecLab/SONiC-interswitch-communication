import matplotlib.pyplot as plt
import pandas as pd
import os

# Define the log file paths
log_files = [
    "load/load_kali2.log",
    "load/load_spine.log",
    "load/load_leaf1.log",
    "load/load_kali1.log",
    "load/load_leaf2.log",
]

data = {}

for log_file in log_files:
    device_name = os.path.basename(log_file).replace(".log", "")
    readable_label = device_name.replace("_", " ").capitalize()
    timestamps = []
    cpu_usages = []

    # Read and parse the log file
    with open(log_file, "r") as file:
        for line in file:
            time, usage = line.split(" - ")
            usage = float(usage.replace("% system", ""))
            timestamps.append(time)
            cpu_usages.append(usage)

    # Store the parsed data
    data[readable_label] = pd.DataFrame(
        {
            "Timestamp": pd.to_datetime(timestamps, format="%H:%M:%S"),
            "CPU Usage": cpu_usages,
        }
    )

# Plotting
plt.figure(figsize=(10, 6))

for label, df in data.items():
    plt.plot(df["Timestamp"], df["CPU Usage"], label=label)

plt.xlabel("Time")
plt.ylabel("CPU Usage (%)")
plt.title("CPU Usage Over Time")
plt.legend()
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig("load.png")

# Show the plot
plt.show()
