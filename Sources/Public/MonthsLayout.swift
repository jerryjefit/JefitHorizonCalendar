// Created by Bryan Keller on 9/18/19.
// Copyright © 2020 Airbnb Inc. All rights reserved.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import CoreGraphics
import Foundation

// MARK: - MonthsLayout

/// The layout of months displayed in `CalendarView`.
public enum MonthsLayout: Hashable {

  /// Calendar months will be arranged in a single column, and scroll on the vertical axis.
  ///
  /// - `options`: Additional options to adjust the layout of the vertically-scrolling calendar.
  case vertical(options: VerticalMonthsLayoutOptions)

  /// Calendar months will be arranged in a single row, and scroll on the horizontal axis.
  ///
  /// - `options`: Additional options to adjust the layout of the horizontally-scrolling calendar.
  case horizontal(options: HorizontalMonthsLayoutOptions)

  // MARK: Public

  public static var vertical: MonthsLayout {
    .vertical(options: .init())
  }

  public static var horizontal: MonthsLayout {
    .horizontal(options: .init())
  }

  // MARK: Internal

  var isHorizontal: Bool {
    switch self {
    case .vertical: return false
    case .horizontal: return true
    }
  }

  var pinDaysOfWeekToTop: Bool {
    switch self {
    case .vertical(let options): return options.pinDaysOfWeekToTop
    case .horizontal: return false
    }
  }

  var alwaysShowCompleteBoundaryMonths: Bool {
    switch self {
    case .vertical(let options): return options.alwaysShowCompleteBoundaryMonths
    case .horizontal: return true
    }
  }

  var isPaginationEnabled: Bool {
    guard
      case .horizontal(let options) = self,
      case .paginatedScrolling = options.scrollingBehavior
    else {
      return false
    }

    return true
  }

    var scrollsToFirstMonthOnStatusBarTap: Date? {
    switch self {
    case .vertical(let options): return options.scrollsToFirstMonthOnStatusBarTap
    case .horizontal: return nil
    }
  }
}

// MARK: - VerticalMonthsLayoutOptions

/// Layout options for a vertically-scrolling calendar.
public struct VerticalMonthsLayoutOptions: Hashable {

  // MARK: Lifecycle

  /// Initializes a new instance of `VerticalMonthsLayoutOptions`.
  ///
  /// - Parameters:
  ///   - pinDaysOfWeekToTop: Whether the days of the week will appear once, pinned at the top, or repeatedly in each month.
  ///   The default value is `false`.
  ///   - alwaysShowCompleteBoundaryMonths: Whether the calendar will always show complete months, even if the visible
  ///   date range does not start on the first date or end on the last date of a month. The default value is `true`.
  ///   - scrollsToFirstMonthOnStatusBarTap: Whether the calendar should scroll to the first month when the system
  ///   status bar is tapped. The default value is `false`.
  public init(
    pinDaysOfWeekToTop: Bool = false,
    alwaysShowCompleteBoundaryMonths: Bool = true,
    scrollsToFirstMonthOnStatusBarTap: Date? = nil)
  {
    self.pinDaysOfWeekToTop = pinDaysOfWeekToTop
    self.alwaysShowCompleteBoundaryMonths = alwaysShowCompleteBoundaryMonths
    self.scrollsToFirstMonthOnStatusBarTap = scrollsToFirstMonthOnStatusBarTap
  }

  // MARK: Public

  /// Whether the days of the week will appear once, pinned at the top, or repeatedly in each month.
  public let pinDaysOfWeekToTop: Bool

  /// Whether the calendar will always show complete months at the calendar's boundaries, even if the visible date range does not start
  /// on the first date or end on the last date of a month.
  public let alwaysShowCompleteBoundaryMonths: Bool

  /// Whether the calendar should scroll to the first month when the system status bar is tapped.
    public let scrollsToFirstMonthOnStatusBarTap: Date?

}

// MARK: - HorizontalMonthsLayoutOptions

/// Layout options for a horizontally-scrolling calendar.
public struct HorizontalMonthsLayoutOptions: Hashable {

  // MARK: Lifecycle

  /// Initializes a new instance of `HorizontalMonthsLayoutOptions`.
  ///
  /// - Parameters:
  ///   - maximumFullyVisibleMonths: The maximum number of fully visible months for any scroll offset. The default value is
  ///   `1`.
  ///   - scrollingBehavior: The scrolling behavior of the horizontally-scrolling calendar: either paginated-scrolling or
  ///   free-scrolling. The default value is paginated-scrolling by month.
  public init(
    maximumFullyVisibleMonths: Double = 1,
    scrollingBehavior: ScrollingBehavior = .paginatedScrolling(
      .init(
        restingPosition: .atLeadingEdgeOfEachMonth,
        restingAffinity: .atPositionsAdjacentToPrevious)))
  {
    assert(maximumFullyVisibleMonths >= 1, "`maximumFullyVisibleMonths` must be greater than 1.")
    self.maximumFullyVisibleMonths = maximumFullyVisibleMonths
    self.scrollingBehavior = scrollingBehavior
  }

  // MARK: Public

  /// The maximum number of fully visible months for any scroll offset.
  public let maximumFullyVisibleMonths: Double

  /// The scrolling behavior of the horizontally-scrolling calendar: either paginated-scrolling or free-scrolling.
  public let scrollingBehavior: ScrollingBehavior

  // MARK: Internal

  func monthWidth(calendarWidth: CGFloat, interMonthSpacing: CGFloat) -> CGFloat {
    let visibleInterMonthSpacing = CGFloat(maximumFullyVisibleMonths) * interMonthSpacing
    return (calendarWidth - visibleInterMonthSpacing) / CGFloat(maximumFullyVisibleMonths)
  }

  func pageSize(calendarWidth: CGFloat, interMonthSpacing: CGFloat) -> CGFloat {
    guard case .paginatedScrolling(let configuration) = scrollingBehavior else {
      preconditionFailure(
        "Cannot get a page size for a calendar that does not have horizontal pagination enabled.")
    }

    switch configuration.restingPosition {
    case .atIncrementsOfCalendarWidth:
      return calendarWidth
    case .atLeadingEdgeOfEachMonth:
      let monthWidth = monthWidth(
        calendarWidth: calendarWidth,
        interMonthSpacing: interMonthSpacing)
      return monthWidth + interMonthSpacing
    }
  }

}

// MARK: HorizontalMonthsLayoutOptions.ScrollingBehavior

extension HorizontalMonthsLayoutOptions {

  /// The scrolling behavior of the horizontally-scrolling calendar: either paginated-scrolling or free-scrolling.
  public enum ScrollingBehavior: Hashable {

    /// The calendar will come to a rest at specific scroll positions, defined by the `PaginationConfiguration`.
    case paginatedScrolling(PaginationConfiguration)

    /// The calendar will come to a rest at any scroll position.
    case freeScrolling
  }

}

// MARK: HorizontalMonthsLayoutOptions.PaginationConfiguration

extension HorizontalMonthsLayoutOptions {

  /// The pagination behavior's configurable options.
  public struct PaginationConfiguration: Hashable {

    // MARK: Lifecycle

    public init(restingPosition: RestingPosition, restingAffinity: RestingAffinity) {
      self.restingPosition = restingPosition
      self.restingAffinity = restingAffinity
    }

    // MARK: Public

    /// The position at which the calendar will come to a rest when paginating.
    public let restingPosition: RestingPosition

    /// The calendar's affinity for stopping at a resting position.
    public let restingAffinity: RestingAffinity

  }

}

extension HorizontalMonthsLayoutOptions.PaginationConfiguration {

  // MARK: - HorizontalMonthsLayoutOptions.PaginationConfiguration.RestingPosition

  /// The position at which the calendar will come to a rest when paginating.
  public enum RestingPosition: Hashable {

    /// The calendar will come to a rest at the leading edge of each month.
    case atLeadingEdgeOfEachMonth

    /// The calendar will come to a rest at increments equal to the calendar's width.
    case atIncrementsOfCalendarWidth

  }

  // MARK: - HorizontalMonthsLayoutOptions.PaginationConfiguration.RestingAffinity

  /// The calendar's affinity for stopping at a resting position.
  public enum RestingAffinity: Hashable {

    /// The calendar will come to a rest at the position adjacent to the previous resting position, regardless of how fast the user
    /// swipes.
    case atPositionsAdjacentToPrevious

    /// The calendar will come to a rest at the closest position to the target scroll offset, potentially skipping over many valid resting
    /// positions depending on how fast the user swipes.
    case atPositionsClosestToTargetOffset

  }

}
