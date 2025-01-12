//
//  main.swift
//  Example-Command
//
//  Created by Plumk on 2022/6/2.
//  Copyright © 2022 Plumk. All rights reserved.
//

import Foundation
import PKit
#if canImport(RxRelay)
import RxRelay
#endif

enum AnimalType: String, PKJsonEnum {
    case cat = "cat"
    case dog = "dog"
    case bird = "bird"
}

struct Job: PKJson {
    @JsonKey var name = ""
    @JsonKey var salary = 0 {
        didSet {
            print("new value")
        }
    }
}

struct Person: PKJson {
    
#if canImport(RxRelay)
    @JsonKey var name: BehaviorRelay<String>?
#else
    @JsonKey var name: String?
#endif
    @JsonKey var age: Int?
    @JsonKey var tags: Set<Int>?
    @JsonKey var job: [Job]?
    @JsonKey var pet: [AnimalType?]?
    
    @JsonKey var birthday: Date? = nil
    
}

let json = """
{
  "result": {
    "name": "张三",
    "age": "18",
    "tags": [
      "1",
      "2",
      "3"
    ],
    "pet": [
      "dog", "cat"
    ],
    "birthday": "2000-01-01",
    "job": [
      {
        "name": "工人1",
        "salary": 10000
      },
      {
        "name": "工人2",
        "salary": 10000
      }
    ]
  }
}
"""


let person = Person()
person.update(from: json, designatedPath: "result")
print(person)

if let jsonStr = person.toJsonString() {
    print(jsonStr)
}


RunLoop.main.run()
