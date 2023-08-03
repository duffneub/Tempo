//
//  SequenceExtensions.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/2/23.
//

import Foundation

extension Sequence {
    
    func grouping<T>(by: (Element) -> T) -> [T: [Element]] {
        [T: [Element]](grouping: self, by: by)
    }
    
}
