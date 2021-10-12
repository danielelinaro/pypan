
__all__ = ['get_vars_list', 'load_vars']

def get_vars_list(filename):
    """
    Get a list of variable names contained in a raw file.

    Parameters
    ----------
    filename : string
        The path of the file to read.

    Returns
    -------
    variables : list
        The names of the variables contained in the file.
    units : list
        The units of the variables.

    """

    variables = []
    units = []
    info = {}
    header = True
    with open(filename, 'rb') as fid:
        for binary_line in fid:
            try:
                line = binary_line.decode('ascii').rstrip()
            except:
                line = binary_line.decode('ISO-8859-1').rstrip()
            if header:
                if line == 'Variables:':
                    header = False
                elif 'Flags:' in line:
                    info['datatype'] = line.split(' ')[-1]
                elif 'No. Variables:' in line:
                    info['num_vars'] = int(line.split(' ')[-1])
                elif 'No. Points:' in line:
                    info['num_samples'] = int(line.split(' ')[-1])
            else:
                if line == 'Binary:':
                    break
                ss = line.split('\t\t')
                variables.append(ss[1])
                units.append(ss[2])

    return variables,units,info


def load_vars(filename, variables, mode='whole'):
    """
    Load data contained in a raw file.

    Parameters
    ----------
    filename : string
        The path of the file to read.
    variables : list
        The list of variables to read. This can be either a list of
        strings or of indices.
    mode : string (either 'whole' or 'chunk')
        The strategy to employ in reading the file: if 'whole', the whole
        file is read and stored in memory, otherwise one sample point is
        read at a time and only the required variables are saved.

    Returns
    -------
    data :
        The data read from the file. It is a numpy.array of size (MxN) if
        the variables to load are specified by a list of indices, where M
        is len(variables) and N is the number of samples. Otherwise, it is
        a dictionary with keys equal to the variable names and with values
        made up of (1xN) numpy.array's.

    """

    import numpy as np

    if not mode in ('whole','chunk'):
        raise Exception('"mode" must be either "whole" or "chunk"')
    reading_mode = mode

    if np.all(list(map(lambda s: type(s) == str, variables))):
        indexing_mode = 'keys'
    elif np.all(list(map(np.isscalar, variables))):
        indexing_mode = 'indices'
    else:
        raise Exception('"variables" must be either a list of strings or a list of integers')

    vars_in_file,_,info = get_vars_list(filename)

    if indexing_mode == 'keys':
        for var in variables:
            if not var in vars_in_file:
                raise Exception('Variable "{}" not contained in file "{}"' \
                                .format(var, filename))
    else:
        if np.max(variables) >= info['num_vars']:
            raise Exception('Index of variable is out of bounds')

    num_vars = info['num_vars']
    num_samples = info['num_samples']

    if indexing_mode == 'keys':
        vars_indices = np.array([vars_in_file.index(var) for var in variables])
    elif type(variables) != np.array:
        vars_indices = np.array(variables)

    header = True
    with open(filename, 'rb') as fid:
        for binary_line in fid:
            try:
                line = binary_line.decode('ascii').rstrip()
            except:
                line = binary_line.decode('ISO-8859-1').rstrip()
            if line == 'Binary:':
                break

        if reading_mode == 'whole':
            blob = np.fromfile(fid, np.float64)
            if info['datatype'] == 'real':
                blob = np.reshape(blob, (num_samples, num_vars), 'C').T
            else:
                re = np.reshape(blob[0::2], (num_samples, num_vars), 'C').T
                im = np.reshape(blob[1::2], (num_samples, num_vars), 'C').T
                blob = np.tile(np.complex(0,0), (num_vars, num_samples))
                for i in range(num_vars):
                    for j in range(num_samples):
                        blob[i,j] = np.complex(re[i,j], im[i,j])
        else:
            if info['datatype'] == 'real':
                blob = np.zeros((len(vars_indices),info['num_samples']))
            else:
                blob = np.complex(0,0) * np.zeros((len(vars_indices),info['num_samples']))
            for i in range(info['num_samples']):
                if info['datatype'] == 'real':
                    tmp = np.fromfile(fid, np.float64, count=info['num_vars'])
                else:
                    tmp = np.fromfile(fid, np.float64, count=2*info['num_vars'])
                    tmp = np.array([np.complex(r,i) for r,i in zip(tmp[0::2],tmp[1::2])])
                blob[:,i] = tmp[vars_indices]
            vars_indices = np.arange(len(vars_indices))

    if indexing_mode == 'keys':
        data = {var: blob[i, :] for var,i in zip(variables,vars_indices)}
    else:
        data = blob[vars_indices, :]

    return data


if __name__ == '__main__':
    import os
    import sys

    if len(sys.argv) > 1:
        filename = sys.argv[1]
    else:
        filename = 'ShPf'
    if not os.path.isfile(filename):
        print('{}: {}: no such file.'.format(os.path.basename(sys.argv[0]), filename))
        sys.exit(1)

    import numpy as np
    import matplotlib.pyplot as plt

    variables,units,info = get_vars_list(filename)
    print(info)
    a = int(np.ceil(np.log10(len(variables))))
    b = max(map(len, variables))
    c = max(map(len, units))
    fmt = '{:0' + str(a) +'d}  {:' + str(b+2) + '} {:' + str(c+2) + 's}'

    data = load_vars(filename, ['time', 'Fdr8.a2', 'Fdr8.a8'], mode='chunk')
    plt.subplot(2,1,1)
    plt.plot(data['time'], data['Fdr8.a2'], 'k')
    plt.plot(data['time'], data['Fdr8.a8'], 'r')

    data = load_vars(filename, [0, 1, 2, 100, 80, 200], mode='whole')
    plt.subplot(2,1,2)
    for i in range(1, data.shape[0]):
        plt.plot(data[0], data[i])
    plt.show()
