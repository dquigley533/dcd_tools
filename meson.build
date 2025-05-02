# meson.build for dcd_tools
# D. Quigley - University of Warwick

project(
	'dcd_tools',       # The name of the project
	['fortran', 'c'],  # The languages that Meson should initialize

	# Keyword arguments:
	version : '0.1.1',
	default_options : ['optimization=2', 'debug=false', 'warning_level=3'],
)

# List of options to pass to fortran compiler
#add_project_arguments(['-fbacktrace', '-fbounds-check, '-ld_classic']) 
#add_project_arguments(['-ld_classic'], language:'fortran')

# Use swig to generate wrapper code
swig = find_program('swig')

# Need Python headers to compile the wrapper code
pydep = dependency('python3', version : '>=3.0.0')

# We'll link using gcc so need to specify some fortran dependencies
fc = meson.get_compiler('fortran')
libgfortran_dep = fc.find_library('gfortran', required: true)
libquadmath_dep = fc.find_library('quadmath', required: true)

# I have issues on MacOS if the Apple-provided clang compiler is used. 
cc = meson.get_compiler('c')
if cc.get_id() != fc.get_id()
  message('Selected C compiler does not have same ID as Fortran compiler.')
  message('This can cause problems with linking.')
  message('Set CC and FC environment variables to compatible compilers before building')
  error()
endif


# Get a handle to the python installation
py = import('python').find_installation(pure: false)

# NumPy include directory - needed in all submodules
incdir_numpy = run_command(py,
  [
    '-c',
    'import numpy; print(numpy.get_include())'
  ],
  check: false
).stdout().strip()

# List of include directories
incdir = include_directories('dcd_writer')

wrapper_code = custom_target('wrapper_code',
	     input : ['dcd_writer/vis_module.i'],
	     output : ['vis_module_wrap.c', 'vis_module.py'],
	     command : [swig, '-python', '-I../include/', '-outcurrentdir', '@INPUT@'],
	     )

# Source files for fortran library
vis_src = ['dcd_writer/vis_module.f90']
	      
# Build fortran source and wrapper code into extension module
py.extension_module(
  '_vis_module',
  [vis_src, wrapper_code],
  install: true,
  include_directories : [incdir, incdir_numpy],
  subdir: 'dcd_tools',
  dependencies: [libgfortran_dep, libquadmath_dep],
)

# Finally define and install python sources
python_sources = [
  '__init__.py',
]
py.install_sources(python_sources, subdir : 'dcd_tools')
