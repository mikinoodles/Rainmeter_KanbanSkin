MIN = 1
MAX = 30

for i in range(MIN - 1, MAX + 1):
    print(f"""
    [TaskBg{i}]
    Meter=Shape
    Hidden=1
    DynamicVariables=1
    Group=Tasks

    [TaskSummary{i}]
    Meter=String
    Hidden=1
    DynamicVariables=1
    Group=Tasks

    [TaskProjectBackground{i}]
    Meter=Shape
    Hidden=1
    DynamicVariables=1
    Group=Tasks

    [TaskProject{i}]
    Meter=String
    Hidden=1
    DynamicVariables=1
    Group=Tasks
    """)
