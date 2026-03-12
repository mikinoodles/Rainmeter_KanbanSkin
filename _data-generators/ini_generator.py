MIN = 21
MAX = 30

for i in range(MIN - 1, MAX + 1):
    print(f"""
    [TaskBg{i}]
    Meter=Shape
    MeterStyle=StyleCardBackground
    X=0
    Y=0
    Hidden=1
    DynamicVariables=1
    LeftMouseDownAction=[!CommandMeasure MeasureScript "PickUpTask({i})"]

    [TaskSummary{i}]
    Meter=String
    MeterStyle=StyleCardSummary
    Text=
    X=0
    Y=0
    Hidden=1
    DynamicVariables=1

    [TaskProjectBackground{i}]
    Meter=Shape
    MeterStyle=StyleCardProjectBackground
    Shape=Rectangle 0,0,([TaskProject{i}:W] + 10),22,6 | Extend ProjectBgModifiers
    X=0
    Y=0
    Hidden=1
    DynamicVariables=1

    [TaskProject{i}]
    Meter=String
    MeterStyle=StyleCardProject
    Text=
    X=0
    Y=0
    Hidden=1
    DynamicVariables=1
    """)
