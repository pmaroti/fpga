import serial

def read_serial_data(port, baudrate):
    try:
        # Open the serial port
        ser = serial.Serial(port, baudrate, timeout=1)
        print(f"Connected to {port} at {baudrate} baudrate.")
        
        while True:
            if ser.in_waiting > 0:
                # Read data from the serial port
                data = ser.read(ser.in_waiting)
                
                # Convert the data to hexadecimal format and print
                hex_data = data.hex().upper()
                print(f"Received data (hex): {hex_data}")
                
    except serial.SerialException as e:
        print(f"Serial exception: {e}")
    except KeyboardInterrupt:
        print("Program interrupted. Exiting...")
    finally:
        if ser.is_open:
            ser.close()
            print("Serial port closed.")

# Replace 'COM3' and 9600 with your actual serial port and baud rate
read_serial_data('/dev/tty.usbserial-2101', 115200)
