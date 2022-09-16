//
//  DynamicFetchRequest.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/6/22.
//
//  Used for FetchRequests with a dynamic predicate
//  iOS 14 compatible view
//

import CoreData
import SwiftUI

struct DynamicFetchRequest<T: NSManagedObject, Content: View>: View {
    @FetchRequest var fetchRequest: FetchedResults<T>

    let content: (FetchedResults<T>) -> Content

    var body: some View {
        content(fetchRequest)
    }

    init(predicate: NSPredicate?,
         @ViewBuilder content: @escaping (FetchedResults<T>) -> Content)
    {
        _fetchRequest = FetchRequest<T>(sortDescriptors: [], predicate: predicate)
        self.content = content
    }
}
