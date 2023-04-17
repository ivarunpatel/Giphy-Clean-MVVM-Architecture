//
//  SharedTestHelpers.swift
//  GiphyTests
//
//  Created by Varun on 17/04/23.
//

import Foundation

func anyURL() -> URL {
    URL(string: "http://any-url.com")!
}

func anyNSError() -> NSError {
    NSError(domain: "an error", code: -1)
}
