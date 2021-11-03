import f90nml
import numpy as np
import argparse


"""
This program modifies namelist. It only modifies string, integer, float.
It does not support modifying array.
"""

ap = argparse.ArgumentParser(description='Process some integers.')
ap.add_argument('--file', type=str, help='The namelist file that needs modification')
ap.add_argument('--grp', type=str, help='The namelist that needs modification')
ap.add_argument('--key',   type=str, help='The key in the namelist that needs modification')
ap.add_argument('--val', type=str, help='The value in the namelist that needs modification')
ap.add_argument('--sort', action="store_true", help='If set then output namelist is sorted')
ap.add_argument('--verbose', action="store_true", help='If set then be verbose')
args = ap.parse_args()

parser = f90nml.Parser()
parser.comment_tokens += '#'

data = parser.read(args.file)

if args.verbose:
    print("Namelist read:")
    print(data)

if (not (args.grp in data)):
    raise Error("Group %s does not exist in the namelist." % (args.grp,))

if (not (args.key in data[args.grp])):
    raise Error("Key %s does not exist in the group %s." % (args.key, args.grp,))


_type = type(data[args.grp][args.key])
data[args.grp][args.key] = _type(args.val)

data.write(args.file, force=True, sort=args.sort)

if args.verbose:
    data = parser.read(args.file)
    print("Updated namelist:")
    print(data)
