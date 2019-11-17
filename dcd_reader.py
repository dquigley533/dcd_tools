#!/usr/bin/env python

import sys
import numpy as np

class dcd_trajectory:
    """A class representing a trajectory inside a dcd file."""

    def __init__(self, dcdfile):
        """Define initial state."""

        # Read the dcd header as a sequence of FORTRAN records

        # 1. Should be 4 characters "CORD" + 20 32-bit integers as icntrl array
        hdr_bytes = self.read_next_fortran_record(dcdfile)
        hdr = hdr_bytes[0:4].decode('utf-8')

        # icntrl array
        icntrl_bytes = hdr_bytes[4:len(hdr_bytes)]  
        icntrl = np.frombuffer(icntrl_bytes, dtype=np.int32, count=20)

        # Report on contents of header
        print("=============================================================")
        print("Processed header of :", dcdfile.name)
        print("=============================================================")
        print("Number of snapshots reported in dcd file : ", icntrl[0])
        print("Number of timesteps between snapshots    : ", icntrl[2])
        print("Total number of snapshots in dcd file    : ", icntrl[3])
        print("DCD in format for Charmm version number  : ", icntrl[19]/10.0)
        if icntrl[10] == 1:
            print("Header reports presence of unit cell information")


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
        #print("Length of record just read :", post_len)  

        if pre_len != post_len :
            sys.exit("Error reading record. Size mismatch.")

        return record_bytes

# Test 
input_file = open("test.dcd", "rb")

my_dcd = dcd_trajectory(input_file)
