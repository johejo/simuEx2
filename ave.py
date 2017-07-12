import sys
s = 0
n = 0
for l in sys.stdin.readlines():
    s += float(l)
    n += 1
print(s / n)
