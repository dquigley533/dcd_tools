/* Header file for C-compatible variables/functions in vis_module.f90 */


/* Write a psf file (topology) */
void write_psf(int nchains, int nbeads);

/* Write charmm-style dcd files */
void write_dcd_header(int nchains, int nbeads);
void write_dcd_snapshot(int nchains, int nbeads, int nchains, ????, double cell_matrix[3][3] );

