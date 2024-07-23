import dcd_tools as dcd
import numpy as np

nchains = 10
nbeads  = 4

dcd.write_psf(nchains, nbeads)
dcd.write_dcd_header(nchains, nbeads)

rchains = np.empty([nchains, nbeads, 3], dtype=np.float64)
hmatrix = np.array([[11,0,0], [0,12,0], [0,0,13]])

for ichain, chain in enumerate(rchains):
    for ibead, bead in enumerate(chain):
        rchains[ichain][ibead] = [ichain*100+ibead*10+1,ichain*100+ibead*10+2,ichain*100+ibead*10+3]


dcd.write_dcd_snapshot(rchains, hmatrix)


input_file = open("chain.dcd", "rb")

#my_dcd = dcd.dcd_reader.dcd_trajectory(input_file)
#print(my_dcd.has_unit_cell)
#print(my_dcd.dcd_title)
