//
//  AppSettingRepositoryProtocol.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/18.
//

import Foundation

protocol AppSettingRepositoryProtocol {
    func load<T: Any>(key: String) -> T?
    func save<T: Any>(key: String, value: T)
}
