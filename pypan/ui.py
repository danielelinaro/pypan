
import os
from os import RTLD_LAZY
import ctypes
from ctypes import CDLL, RTLD_GLOBAL, POINTER, create_string_buffer, byref
from ctypes.util import find_library
import numpy as np

PAN_LIB_PATH = os.getenv('PYPAN_SO')

__all__ = ['load_libs', 'close_libs', 'load_netlist', 'exec_cmd', 'get_var', \
           'tran', 'shooting', 'alter', 'envelope', 'DC', 'PZ']

VERBOSE = False


def load_libs(pan_lib_path):
    """
    Load the shared libraries necessary for the correct functioning of PAN's Python interface

    Parameters
    ----------
    pan_lib_path : string
        The path of the 'pan.so' shared library

    Returns
    -------
    libs : dict
        A dictionary containing the open libraries

    """

    lib_names = ('c','m','z','bz2','history','gfortran')
    libs = {}
    for name in lib_names:
        path = find_library(name)
        if path is not None:
            try:
                libs[name] = CDLL(path, mode=RTLD_GLOBAL)
                if VERBOSE:
                    print('Successfully loaded "{}" library from {}'.format(name, path))
            except:
                print('Cannot load "{}" library from {}'.format(name, path))
        else:
            print('Cannot find {} library'.format(name))
    libs['pan'] = CDLL(pan_lib_path, mode=RTLD_LAZY | RTLD_GLOBAL)
    return libs



def load_netlist(filename, libs=None):
    """
    Load (and run) a PAN netlist

    Parameters
    ----------
    filename : string
        The path of the file containing the netlist
    libs : dict
        A dictionary containing the open libraries

    Returns
    -------
    flag : boolean
        True if the netlist was loaded successfully, False otherwise
    libs : dict
        A dictionary containing the open libraries

    """

    if not os.path.isfile(filename):
        print('{}: no such file'.format(filename))
        return False

    if libs is None:
        got_libs = False
        libs = load_libs(PAN_LIB_PATH)
    else:
        got_libs = True

    ok = libs['pan'].InitialiseGlobals(None)
    if VERBOSE:
        print('InitialiseGlobals() returned {}.'.format(ok))

    if not ok:
        if got_libs:
            return False
        return False, libs

    print_fun = libs['c'].printf
    args = ['pan', filename]
    argc = len(args)
    argv = (POINTER(ctypes.c_char) * argc)()
    for i,arg in enumerate(args):
        argv[i] = create_string_buffer(bytes(arg, 'utf-8'))
    err = libs['pan'].PythonPanInit(argc, argv, libs['c'].printf)

    if got_libs:
        return err == 0

    return err == 0, libs


def exec_cmd(cmd, libs=None):
    """
    Execute a command on the netlist currently in memory

    Parameters
    ----------
    cmd : string
        A string containing the command to execute
    libs : dict
        A dictionary containing the open libraries

    Returns
    -------
    flag : boolean
        True if the command was executed successfully, False otherwise

    """
    if libs is None:
        libs = load_libs(PAN_LIB_PATH)
    string = create_string_buffer(bytes(cmd, 'utf-8'))
    return libs['pan'].PanPythonExecuteCommand(string)



def get_var(varname, libs=None):
    """
    Get a variable from PAN memory

    Parameters
    ----------
    varname : string
        A string containing the name of the string to load from memory
    libs : dict
        A dictionary containing the open libraries

    Returns
    -------
    data : array
        A Numpy array containing the loaded data

    """

    if libs is None:
        libs = load_libs(PAN_LIB_PATH)
    rows = ctypes.c_int()
    cols = ctypes.c_int()
    real_part = (POINTER(ctypes.c_double) * 1)()
    imag_part = (POINTER(ctypes.c_double) * 1)()
    ok = libs['pan'].PanPythonGet(create_string_buffer(bytes(varname, 'utf-8')),
                                  byref(real_part),
                                  byref(imag_part),
                                  byref(rows),
                                  byref(cols))

    if not ok:
        raise KeyError('{}: no such variable'.format(varname))
    
    rows = rows.value
    cols = cols.value
    
    if cols == 1:
        shape = (rows,)
    elif rows == 1:
        shape = (cols,)
    else:
        shape = (rows,cols)

    # the real part
    A = np.ctypeslib.as_array(real_part[0], shape)
    try:
        # the imaginary part
        B = np.ctypeslib.as_array(imag_part[0], shape)
    except:
        # there is no imaginary part
        B = None

    if B is None:
        return A

    return A + 1j * B


def _get_vars(analysis_name, mem_vars, libs):
    data = [get_var(analysis_name + '.' + mem_var, libs) for mem_var in mem_vars]
    if len(data) == 1 or (len(data) > 0 and np.all([len(x) for x in data] == len(data[0]))):
        return np.array(data)
    return data


def _run_cmd_with_return_data(base_cmd, mem_vars=None, libs=None, **kwargs):
    if libs is None:
        libs = load_libs(PAN_LIB_PATH)
    ss = base_cmd.split(' ')
    analysis_name = ss[0]
    analysis_type = ss[1]
    if mem_vars is not None:
        base_cmd += ' mem=["' + '", "'.join(mem_vars) + '"]'
    for k,v in kwargs.items():
        base_cmd += ' {}={}'.format(k,v)
    ok = exec_cmd(base_cmd, libs)
    if not ok:
        raise Exception('{} analysis {} failed'.format(analysis_type, analysis_name))
    if mem_vars is not None:
        return _get_vars(analysis_name, mem_vars, libs)
    return None


def tran(name, tstop, mem_vars=None, libs=None, **kwargs):
    base_cmd = '{} tran tstop={}'.format(name, tstop)
    return _run_cmd_with_return_data(base_cmd, mem_vars, libs, **kwargs)


def shooting(name, period, mem_vars=None, libs=None, **kwargs):
    base_cmd = '{} shooting period={}'.format(name, period)
    return _run_cmd_with_return_data(base_cmd, mem_vars, libs, **kwargs)


def envelope(name, tstop, period, mem_vars=None, libs=None, **kwargs):
    base_cmd = '{} envelope tstop={} period={}'.format(name, tstop, period)
    return _run_cmd_with_return_data(base_cmd, mem_vars, libs, **kwargs)


def DC(name, mem_vars=None, libs=None, **kwargs):
    base_cmd = '{} dc'.format(name)
    return _run_cmd_with_return_data(base_cmd, mem_vars, libs, **kwargs)


def PZ(name, mem_vars=None, libs=None, **kwargs):
    base_cmd = '{} pz'.format(name)
    return _run_cmd_with_return_data(base_cmd, mem_vars, libs, **kwargs)


def alter(name, param, value, libs=None, **kwargs):
    if libs is None:
        libs = load_libs(PAN_LIB_PATH)
    cmd = '{} alter param="{}" value={}'.format(name, param, value)
    for k,v in kwargs.items():
        if k in ('model',):
            cmd += ' {}="{}"'.format(k,v)
        else:
            cmd += ' {}={}'.format(k,v)
    return exec_cmd(cmd, libs)

