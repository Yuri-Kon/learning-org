def task(name, n):
    for i in range(1, n + 1):
        print(name, i)
        yield

tasks = [
    task("A", 3),
    task("B", 5),
    task("C", 2)
]

while tasks:
    alive = []
    for task in tasks:
        try:
            next(task)
            alive.append(task)
        except StopIteration:
            pass
    tasks = alive
