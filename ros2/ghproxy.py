import os

for  path, folders, files  in os.walk("./src"):
    for file in files:
        if(file == "CMakeLists.txt" or file =="CMakeLists"):
            print(os.path.join(path,file))
            os.system('sed -i "s/https\:\/\/github.com/https\:\/\/ghproxy.com\/https\:\/\/github.com/g " '+os.path.join(path,file))
            os.system('sed -i "s/https\:\/\/raw.githubusercontent.com/https\:\/\/ghproxy.com\/https\:\/\/raw.githubusercontent.com/g " '+os.path.join(path,file))