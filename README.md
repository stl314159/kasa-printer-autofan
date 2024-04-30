# Kasa Smart Plug Power Monitor

This project monitors the power consumption of a Kasa smart plug connected to a printer and controls a fan based on the printer's power usage.

## Prerequisites

- Docker
- Docker Compose

## Setup

1. Clone this repository:
`git clone https://github.com/stl314159/printer-fan-automation.git`

2. Navigate to the project directory:
`cd printer-fan-automation`

3. Create a `.env` file in the project directory with the following content:
```
KASA_USERNAME=your_kasa_username
KASA_PASSWORD=your_kasa_password
PRINTER_ALIAS=your_printer_alias
FAN_ALIAS=your_fan_alias
POWER_THRESHOLD=your_power_threshold
```

Replace `your_kasa_username`, `your_kasa_password`, `your_printer_alias`, `your_fan_alias`, and `your_power_threshold` with your actual values.

## Usage

1. Build and run the application using Docker Compose:
`docker-compose up --build` This command will build the Docker image and start the container.

2. The application will continuously monitor the power consumption of the printer smart plug and control the fan smart plug based on the following logic:
- If the printer's power consumption is over the power threshold, the fan will be turned on.
- If the printer's power consumption has been less than the power threshold for at least 5 minutes, the fan will be turned off.

3. To stop the application, press `Ctrl+C` in the terminal where the containers are running, or run the following command in a separate terminal: `docker-compose down` This will stop and remove the containers.

## Project Structure

- `Dockerfile`: Defines the multi-stage build process for the Docker image.
- `docker-compose.yml`: Defines the services and their configuration for Docker Compose.
- `requirements.txt`: Lists the Python dependencies required for the project.
- `src/app.sh`: Contains the main shell script that monitors the printer's power consumption and controls the fan.
- `.env`: Stores the environment variables required for the project (not version-controlled).

## Dependencies

- Python 3.9
- Rust (for building Python dependencies)
- Python packages:
- python-kasa[shell]

## License

This project is licensed under the [MIT License](LICENSE).