import time

def cpu_load():
    while True:
        x = 0
        for i in range(10**6):
            x += i*i
        time.sleep(0.1)

if __name__ == "__main__":
    cpu_load()
