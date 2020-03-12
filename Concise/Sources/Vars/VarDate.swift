//
//  VarDate.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation


public class VarDate: Var<Date> {
    public struct Interval: RawRepresentable, Hashable {
        public let rawValue: Int
        
        public static let second = Interval(rawValue: 1)
        public static let minute = Interval(rawValue: Interval.second.rawValue * 60)
        public static let hour = Interval(rawValue: Interval.minute.rawValue * 60)
        public static let day = Interval(rawValue: Interval.hour.rawValue * 24)
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    public let interval: Interval
    
    private func scheduleNextUpdate() {
        let now = Date()
        let midnight: Date = {
            let c = Calendar.current
            return c.date(from: c.dateComponents([.month, .day, .year], from: now))!
        }()
        
        let deadline: DispatchTime = {
            // need to validate that timezone logic is correct here
            // for interval .day we should fire at midnight
            let tz = TimeZone.current
            let nowInterval = now.timeIntervalSince1970 + Double(tz.secondsFromGMT(for: now))
            let midnightInterval = midnight.timeIntervalSince1970 + Double(tz.secondsFromGMT(for: midnight))
            
            let nextInterval = (midnightInterval + TimeInterval((Int(nowInterval - midnightInterval) / interval.rawValue + 1) * interval.rawValue))
            let nextSecs = nextInterval - nowInterval
            
            // convert to dispatch time
            return  DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + UInt64(nextSecs * Double(NSEC_PER_SEC)))
        }()
        
        // todo: switch to a timer so we can cancel?
        
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            // note: when we are dealloced this block will eventually run one more time with a nil self which will do nothing.
            // sadly you can't cancel dispatchAsync.
            self?.setNeedsUpdate()
            self?.scheduleNextUpdate()
        }
    }
    
    override public func updateValue() -> Bool {
        self.setValue(Date())
        return true
    }
    
    private struct WeakWrapper {
        weak var item: VarDate?
    }
    
    private static var _currentItems: [Interval: WeakWrapper] = [:]
    
    private init(_ interval: Interval) {
        self.interval = interval
        super.init(Domain.current, Date())
        
        scheduleNextUpdate()
    }
    
    static public func every(_ interval: Interval) -> VarDate {
        
        // if we have created an instance already, return it...
        
        if let item = VarDate._currentItems[interval]?.item {
            return item
        }
        
        // otherwise create a new one and cache it (and maintain a weak reference)...

        let item = VarDate(interval)
        _currentItems[interval] = WeakWrapper(item: item)
        
        return item
    }
    
    static public var everySecond: Date {
        return every(.second).value
    }
    
    static public var everyMinute: Date {
        every(.minute).value
    }
    
    static public var everyHour: Date {
        every(.hour).value
    }
    
    static public var everyDay: Date {
        every(.day).value
    }
}

