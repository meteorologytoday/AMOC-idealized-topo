import f90nml
import numpy as np
import argparse


print("""
This program read the data namelist that contains
""")

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('integers', metavar='N', type=int, nargs='+',
                    help='an integer for the accumulator')
parser.add_argument('--sum', dest='accumulate', action='store_const',
                    const=sum, default=max,
                    help='sum the integers (default: find the max)')

parser = f90nml.Parser()
parser.comment_tokens += '#'

data = parser.read("data_template.nml")

print("Namelist read:")
print(data)


p_vec = np.linspace(0.0, -10e-7, 11)

print()
