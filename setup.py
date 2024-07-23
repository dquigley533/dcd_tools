##############################
# Setup script for dcd_tools #
##############################
#!/usr/bin/env python

def configuration():

    from numpy.distutils.misc_util import Configuration

    config = Configuration('dcd_tools', parent_name=None, top_path=None)


    vis_src = ['dcd_writer/vis_module.f90']
    vis_inc = ['dcd_write/vis_module.h']
    
    config.add_library('vis_module', sources=vis_src,
                       extra_f90_compile_args=['-g','-fbounds-check','-fbacktrace']
#                       extra_f90_compile_args=['-O3']
                      )

    config.add_extension('_dcd_tools',
        sources      = ['dcd_writer/alkane.i','dcd_reader/dcd_reader.py'],
        libraries    = ['vis_module'],
#        include_dirs = ['./include'],
        depends      = ['dcd_writer/vis_module.i'] + vis_inc + vis_src,
    )

    config.version = "0.1.1"

    return config

if __name__ == "__main__":

    from numpy.distutils.core import setup

    setup(configuration=configuration,
          author       = "David Quigley",
          author_email = "d.quigley@warwick.ac.uk",
          description  = "Tools for reading and writing psf+dcd files for vmd",
          url          = "https://github.com/dquigley533/dcd_tools")



