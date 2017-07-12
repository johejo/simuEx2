import statistics
import sys

data =[]
for l in sys.stdin.readlines():
    data.append(float(l))

print(statistics.stdev(data))
