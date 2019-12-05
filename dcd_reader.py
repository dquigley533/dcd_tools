#!/usr/bin/env python

import sys
import os
import numpy as np


class Error(Exception):
    """Base class for exceptions in this module."""
    pass

class FortranRecordError(Error):
    """Exception raised when the number of bytes flagged before and after
    an unformatted binary record are mismatched."""

    def __init__(self, record, pre_len, post_len):
        print("Error reading unformatted record ",record)
        print("Record length mismatch")

class dcd_trajectory:
    """A class representing a trajectory inside a dcd file."""

    num_atoms = np.int32()     # Number of atoms in each snapshot
    num_snapshots = np.int32() # Number of snapshots in DCD
    dcd_title = str()          # DCD title string
    has_unit_cell = bool()     # Unit cell information present

    current_record = 0         # Last 

    def __init__(self, dcdfile):
        """Define initial state."""

        # Sanity check before going any further. Does this file have enough
        # bytes to hold a dcd header, let alone any snapshots
        file_size = os.path.getsize(dcdfile.name)
        min_num_dcd_hdr_bytes = 84

        tot_num_hdr_bytes = 0

        # Read the dcd header as a sequence of FORTRAN records

        # Record 1 should be 4 characters "CORD" + 20 32-bit integers as icntrl array
        hdr_bytes = self.read_next_fortran_record(dcdfile)
        tot_num_hdr_bytes += len(hdr_bytes)+8
        hdr = hdr_bytes[0:4].decode('utf-8')

        # icntrl array
        icntrl_bytes = hdr_bytes[4:len(hdr_bytes)]  
        icntrl = np.frombuffer(icntrl_bytes, dtype=np.int32, count=20)

        # set unit cell & number of snapshots
        self.has_unit_cell = bool(icntrl[10]==1)
        self.num_snapshots = icntrl[0]

        # Record 2 is the dcd title (80 bytes)
        hdr_bytes = self.read_next_fortran_record(dcdfile)
        tot_num_hdr_bytes += len(hdr_bytes)+8
        self.dcd_title = hdr_bytes.decode()

        # Record 3 is the number of atoms in each snapshot
        hdr_bytes = self.read_next_fortran_record(dcdfile)
        tot_num_hdr_bytes += len(hdr_bytes)+8
        self.num_atoms = np.frombuffer(hdr_bytes, dtype=np.int32, count=1)[0]

        # Report on contents of header
        print("=============================================================")
        print("Processed header of :", dcdfile.name)
        print("=============================================================")
        print("Number of snapshots reported in dcd file : ", icntrl[0])
        print("Number of timesteps between snapshots    : ", icntrl[2])
        print("Total number of snapshots in dcd file    : ", icntrl[3])
        print("DCD in format for Charmm version number  : ", icntrl[19]/10.0)
        print("Number of atoms in each snapshot         : ", self.num_atoms)
        if icntrl[10] == 1:
            print("Header reports presence of unit cell information")
        print("DCD Title :", self.dcd_title)

        print("Number of bytes in header = ",tot_num_hdr_bytes)

        # Calculate expected size of each snapshot and check if this
        # tallies with the number of bytes remaining in the file.
        bytes_per_snapshot = 3*8 + 3*self.num_atoms*4 # 3 records of N floats
        if self.has_unit_cell:
            bytes_per_snapshot += 8 + 8*6  # one record of 6 doubles 

        expected_file_size = bytes_per_snapshot*self.num_snapshots + tot_num_hdr_bytes

        print(expected_file_size, file_size)


    def read_next_fortran_record(self, dcdfile):
        """Reads the next fortran record from dcd file"""

        # Add error checking...

        # Number of bytes in next record
        inbuffer = dcdfile.read(4)  
        pre_len = int()
        pre_len = pre_len.from_bytes(inbuffer, sys.byteorder)
        
        #print("Length of next record :", pre_len)

        # Read that many bytes
        record_bytes = dcdfile.read(pre_len) 
        #print("record_bytes:", record_bytes)

        # Check that was the correct number of bytes
        inbuffer = dcdfile.read(4)  
        post_len = int()
        post_len = post_len.from_bytes(inbuffer, sys.byteorder)
        print("Length of record just read :", post_len)  

        if pre_len != post_len :
            raise FortranRecordError(self.current_record, pre_len, post_len)

        self.current_record += 1

        return record_bytes

# Test 
input_file = open("test.dcd", "rb")

my_dcd = dcd_trajectory(input_file)

print(my_dcd.has_unit_cell)
print(my_dcd.dcd_title)