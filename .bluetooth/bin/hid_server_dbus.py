#!/usr/bin/env python3
"""
Bluetooth HID Gamepad Server using BlueZ D-Bus API
This creates a virtual Bluetooth HID device that acts as a gamepad
"""

import os
import sys
import dbus
import dbus.service
import dbus.mainloop.glib
import time
import struct
from gi.repository import GLib

# HID Report Descriptor for a standard gamepad
# Defines: 2 analog sticks (X, Y, Z, Rz), D-pad (Hat), 16 buttons
HID_DESCRIPTOR = bytes.fromhex(
    "05010905a1010501"  # Usage Page (Generic Desktop), Usage (Gamepad), Collection (Application)
    "a1000509300931"    # Collection (Physical), Usage (X), Usage (Y)
    "1500250101751095"  # Logical Min/Max, Report Size, Report Count
    "02810205010932"    # Input (Data,Var,Abs), Usage (Z)
    "09351500250101"    # Usage (Rz), Logical Min/Max
    "751095028102c0"    # Report Size, Report Count, Input
    "05091901092915"    # Usage Page (Buttons), Usage Min/Max (1-16)
    "01250175019510"    # Logical Min/Max, Report Size, Report Count
    "8102c0"            # Input, End Collection
)

# Simplified descriptor (works better with most systems)
HID_DESCRIPTOR_SIMPLE = (
    "05010905a101"          # Usage Page (Generic Desktop), Usage (Gamepad), Collection (Application)
    "a10005091901"          # Collection (Physical), Usage Page (Buttons), Usage Min (1)
    "29101500"              # Usage Max (16), Logical Min (0)
    "25017501"              # Logical Max (1), Report Size (1)
    "950181020509"          # Report Count (16), Input (Data,Var,Abs), Usage Page (Generic Desktop)
    "30093109321500"        # Usage (X,Y,Z), Logical Min (0)
    "26ff007510"            # Logical Max (255), Report Size (16)
    "950381020939"          # Report Count (3), Input, Usage (Hat Switch)
    "150025073500"          # Logical Min (0), Max (7), Physical Min (0)
    "46000075089501"        # Physical Max (0), Report Size (8), Report Count (1)
    "81420600ff09"          # Input (Data,Var,Abs,Null), Vendor Defined
    "0175089506"            # Report Size (8), Report Count (6)
    "8103c0c0"              # Input, End Collection, End Collection
)

SERVICE_NAME = "org.muos.hidserver"
PROFILE_PATH = "/org/muos/hid"
INTERFACE_NAME = "org.bluez.ProfileManager1"


class HIDProfile(dbus.service.Object):
    """BlueZ HID Profile"""

    fd = -1

    def __init__(self, bus, path):
        dbus.service.Object.__init__(self, bus, path)
        self.fd = -1

    @dbus.service.method("org.bluez.Profile1", in_signature="", out_signature="")
    def Release(self):
        print("Release")

    @dbus.service.method("org.bluez.Profile1", in_signature="oha{sv}", out_signature="")
    def NewConnection(self, path, fd, properties):
        self.fd = fd.take()
        print(f"NewConnection({path}, {self.fd})")
        for key in properties.keys():
            print(f"  {key} = {properties[key]}")

    @dbus.service.method("org.bluez.Profile1", in_signature="o", out_signature="")
    def RequestDisconnection(self, path):
        print(f"RequestDisconnection({path})")
        if self.fd > 0:
            os.close(self.fd)
            self.fd = -1


class BTHIDDevice:
    """Bluetooth HID Device Manager"""

    def __init__(self):
        print("Initializing Bluetooth HID Server...")

        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SystemBus()
        self.mainloop = GLib.MainLoop()

        self.profile = HIDProfile(self.bus, PROFILE_PATH)
        self.device_path = None

        # Setup HID profile
        self.setup_profile()

        # Setup FIFO for receiving input reports
        self.fifo_path = "/tmp/hid_report_fifo"
        if not os.path.exists(self.fifo_path):
            os.mkfifo(self.fifo_path)

        # Poll FIFO for input data
        GLib.timeout_add(16, self.read_and_send_report)  # ~60Hz

        print("HID Server initialized successfully")
        print(f"Device name: MuOS Gamepad")
        print(f"Waiting for connections...")

    def setup_profile(self):
        """Register HID profile with BlueZ"""
        try:
            manager = dbus.Interface(
                self.bus.get_object("org.bluez", "/org/bluez"),
                "org.bluez.ProfileManager1"
            )

            opts = {
                "ServiceRecord": self.get_sdp_record(),
                "Role": "server",
                "RequireAuthentication": False,
                "RequireAuthorization": False,
            }

            manager.RegisterProfile(PROFILE_PATH, "00001124-0000-1000-8000-00805f9b34fb", opts)
            print("HID Profile registered")

        except dbus.exceptions.DBusException as e:
            print(f"Failed to register profile: {e}")
            sys.exit(1)

    def get_sdp_record(self):
        """Generate SDP (Service Discovery Protocol) record for HID"""
        # This is a simplified SDP record for a HID device
        # In a production system, you'd want a complete SDP record
        return """<?xml version="1.0" encoding="UTF-8" ?>
<record>
    <attribute id="0x0001">
        <sequence>
            <uuid value="0x1124"/>
        </sequence>
    </attribute>
    <attribute id="0x0004">
        <sequence>
            <sequence>
                <uuid value="0x0100"/>
                <uint16 value="0x0011"/>
            </sequence>
            <sequence>
                <uuid value="0x0011"/>
            </sequence>
        </sequence>
    </attribute>
    <attribute id="0x0005">
        <sequence>
            <uuid value="0x1002"/>
        </sequence>
    </attribute>
    <attribute id="0x0006">
        <sequence>
            <uint16 value="0x656e"/>
            <uint16 value="0x006a"/>
            <uint16 value="0x0100"/>
        </sequence>
    </attribute>
    <attribute id="0x0009">
        <sequence>
            <sequence>
                <uuid value="0x1124"/>
                <uint16 value="0x0100"/>
            </sequence>
        </sequence>
    </attribute>
    <attribute id="0x000d">
        <sequence>
            <sequence>
                <sequence>
                    <uuid value="0x0100"/>
                    <uint16 value="0x0013"/>
                </sequence>
                <sequence>
                    <uuid value="0x0011"/>
                </sequence>
            </sequence>
        </sequence>
    </attribute>
    <attribute id="0x0100">
        <text value="MuOS Gamepad"/>
    </attribute>
    <attribute id="0x0101">
        <text value="Bluetooth Gamepad"/>
    </attribute>
    <attribute id="0x0102">
        <text value="MuOS"/>
    </attribute>
    <attribute id="0x0200">
        <uint16 value="0x0100"/>
    </attribute>
    <attribute id="0x0201">
        <uint16 value="0x0111"/>
    </attribute>
    <attribute id="0x0202">
        <uint8 value="0x40"/>
    </attribute>
    <attribute id="0x0203">
        <uint8 value="0x00"/>
    </attribute>
    <attribute id="0x0204">
        <boolean value="true"/>
    </attribute>
    <attribute id="0x0205">
        <boolean value="false"/>
    </attribute>
    <attribute id="0x0206">
        <sequence>
            <sequence>
                <uint8 value="0x22"/>
                <text encoding="hex" value="05010905a1010901a10005091901291015002501750195108102c00509300931093209351500260000751095048102c0c0"/>
            </sequence>
        </sequence>
    </attribute>
    <attribute id="0x0207">
        <sequence>
            <sequence>
                <uint16 value="0x0409"/>
                <uint16 value="0x0100"/>
            </sequence>
        </sequence>
    </attribute>
</record>"""

    def read_and_send_report(self):
        """Read HID report from FIFO and send over Bluetooth"""
        try:
            # Non-blocking read
            if os.path.exists(self.fifo_path):
                fifo = os.open(self.fifo_path, os.O_RDONLY | os.O_NONBLOCK)
                try:
                    data = os.read(fifo, 1024)
                    if data:
                        # Parse comma-separated values
                        values = data.decode('utf-8').strip().split(',')
                        if len(values) >= 7:
                            # Convert to bytes
                            report = bytes([int(v) for v in values[:7]])
                            self.send_report(report)
                finally:
                    os.close(fifo)
        except (OSError, ValueError) as e:
            # FIFO might not be ready or no data available
            pass

        return True  # Continue polling

    def send_report(self, report):
        """Send HID report to connected host"""
        if self.profile.fd > 0:
            try:
                # HID report format: 0xA1 (Input Report) + Report ID + Data
                os.write(self.profile.fd, b'\xa1' + report)
            except OSError:
                print("Failed to send report, connection may be closed")

    def run(self):
        """Start the main loop"""
        try:
            self.mainloop.run()
        except KeyboardInterrupt:
            print("\nShutting down...")
            self.cleanup()

    def cleanup(self):
        """Cleanup resources"""
        if os.path.exists(self.fifo_path):
            os.remove(self.fifo_path)
        self.mainloop.quit()


if __name__ == "__main__":
    device = BTHIDDevice()
    device.run()
