/* -*- mode: C */

%define DOCSTRING
"Fortran2003 code (with C/Python bindings) for write psf and dcd files for systems of
 linear chain molecules."
%enddef

/* alkane.i */
/* N.B. Implementing module docstring using the method described 
at http://swig.org/Doc1.3/Python.html#Python_nn66 stops distutils
from recognising the module name.... 
%module(docstrig=DOCSTRING) alkane
*/
%module vis_module
%{
#define SWIG_FILE_WITH_INIT

/* These will be included in the wrapper code */
#include "vis_module.h"
%}

/* Standard typemaps */
%include "typemaps.i"

/* Numpy array typemap */
%include "numpy.i"


%init %{
  import_array();
%}

/* Map array array onto arguments used in the C interface */


/* Matrix of cell vectors */
%apply(double IN_ARRAY2[ANY][ANY]) {(double cell_matrix[3][3])};

/* Chains */
%apply(int* DIM1, int* DIM2, double** ARGOUTVIEW_ARRAY2) {(int *nbeads_out,int *d_out, double **rchain_ptr)};


/* Docstring information for write_psf */
%feature("autodoc", "write_psf()") write_psf;
%define vis_wrt_psf
"
    Creates a protein structure file (psf) for the purposes of
    defining the bond toplogy of the simulation when read into
    VMD. Filename will be chain.psf.

    Parameters
    ----------

    nchains :  Number of linear chain molecules in the system
    nbeads  :  Number of beads comprising each linear chain

"
%enddef
%feature("docstring", vis_wrt_psf) write_psf;

/* Docstring information for write_dcd_header */
%feature("autodoc", "write_dcd_header()") write_dcd_header;
%define vis_wrt_dcd_hd
"
    Writes the header at the start of the dcd file. Most of this
    header is ignored by VMD and so just containers placeholder
    values. Filename will be chain.dcd. 

    Parameters
    ----------

    nchains :  Number of linear chain molecules in the system
    nbeads  :  Number of beads comprising each linear chain

"
%enddef
%feature("docstring", vis_wrt_dcd_hd) write_dcd_header;

/* Docstring information for write_dcd_snapshot */
%feature("autodoc", "write_dcd_snapshot()") write_dcd_snapshot;
%define vis_wrt_dcd_sh
"
    Writes the header at the start of the dcd file. Most of this
    header is ignored by VMD and so just containers placeholder
    values. Filename will be chain.dcd. 

    Parameters
    ----------

    rchain   :  3D Numpy array containing bead coordinates
    hmatrix  :  3x3 Numpy array contain matrix of cell vectors 
        
"
%enddef
%feature("docstring", vis_wrt_dcd_sh) write_dcd_snapshot;

/* This will be parsed to generate the wrapper */
%include "vis_module.h"
