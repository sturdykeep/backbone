call flutter test --coverage
call C:\Strawberry\perl\bin\perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml -o coverage\html coverage\lcov.info
start coverage/html/index.html