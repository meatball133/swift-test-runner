import Foundation


let pipe = Pipe()

print("Hi")

do {
let data = try pipe.fileHandleForReading.read(upToCount:1)
print(data)
}catch{
    print("åh nej")
}