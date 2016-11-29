import Foundation
import MapboxDirections

public enum AlertLevel: Int {
    case none
    case depart
    case low
    case medium
    case high
    case arrive
}

/*
 `routeProgress` contains all progress information of user along the route, leg and step.
 */
open class RouteProgress {
    public let route: Route
    public var legIndex: Int {
        didSet {
            assert(legIndex >= 0 && legIndex < route.legs.endIndex)
            // TODO: Set stepIndex to 0 or last index based on whether leg index was incremented or decremented.
            currentLegProgress = RouteLegProgress(leg: currentLeg)
        }
    }
    
    /*
     If waypoints are provided in the `Route`, this will contain which leg the user is on.
     */
    public var currentLeg: RouteLeg {
        return route.legs[legIndex]
    }
    
    
    /*
     Total distance traveled by user along all legs.
     */
    public var distanceTraveled: CLLocationDistance {
        return route.legs.prefix(upTo: legIndex).map { $0.distance }.reduce(0, +) + currentLegProgress.distanceTraveled
    }
    
    /*
     Total seconds remaining on all legs
     */
    public var durationRemaining: CLLocationDistance {
        return route.legs.suffix(from: legIndex + 1).map { $0.expectedTravelTime }.reduce(0, +) + currentLegProgress.durationRemaining
    }
    
    /*
     Number between 0 and 1 representing how far along the `Route` the user has traveled.
     */
    public var fractionTraveled: Double {
        return distanceTraveled / route.distance
    }
    
    /*
     Total distance remaining in meters along route.
     */
    public var distanceRemaining: CLLocationDistance {
        return route.distance - distanceTraveled
    }
    
    public var currentLegProgress: RouteLegProgress!
    
    public init(route: Route, legIndex: Int = 0) {
        self.route = route
        self.legIndex = legIndex
        currentLegProgress = RouteLegProgress(leg: currentLeg)
    }
}

open class RouteLegProgress {
    public let leg: RouteLeg
    public var stepIndex: Int {
        didSet {
            assert(stepIndex >= 0 && stepIndex < leg.steps.endIndex)
            currentStepProgress = RouteStepProgress(step: currentStep)
        }
    }
    
    /*
     Total distance traveled in meters along current leg
     */
    public var distanceTraveled: CLLocationDistance {
        return leg.steps.prefix(upTo: stepIndex).map { $0.distance }.reduce(0, +) + currentStepProgress.distanceTraveled
    }
    
    
    /*
     Duration remaining in seconds on current leg
     */
    public var durationRemaining: TimeInterval {
        return leg.steps.suffix(from: stepIndex + 1).map { $0.expectedTravelTime }.reduce(0, +) + currentStepProgress.durationRemaining
    }
    
    /*
    Number between 0 and 1 representing how far along the current leg the user has traveled.
    */
    public var fractionTraveled: Double {
        return distanceTraveled / leg.distance
    }
    
    public var alertUserLevel: AlertLevel = .none
    
    
    /*
     Returns number representing current `Step` for the leg the user is on.
     */
    public var currentStep: RouteStep {
        return leg.steps[stepIndex]
    }
    
    /*
     Returns the upcoming `Step`.
     
     If there is no upcoming step, nil is returned.
     */
    public var upComingStep: RouteStep? {
        guard stepIndex + 1 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 1]
    }
    
    public var followOnStep: RouteStep? {
        guard stepIndex + 2 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 2]
    }
    
    public func stepBefore(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.index(of: step) else {
            return nil
        }
        if index > 0 {
            return leg.steps[index-1]
        }
        return nil
    }
    
    public func stepAfter(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.index(of: step) else {
            return nil
        }
        if index+1 < leg.steps.endIndex {
            return leg.steps[index+1]
        }
        return nil
    }
    
    /*
     Return bool whether step provided is the current `Step` the user is on.
    */
    public func isCurrentStep(_ step: RouteStep) -> Bool {
        return leg.steps.index(of: step) == stepIndex
    }
    
    public var currentStepProgress: RouteStepProgress
    
    public init(leg: RouteLeg, stepIndex: Int = 0) {
        self.leg = leg
        self.stepIndex = stepIndex
        currentStepProgress = RouteStepProgress(step: leg.steps[stepIndex])
    }
}

open class RouteStepProgress {
    
    public let step: RouteStep
    
    /*
     Returns distance user has traveled along current step.
    */
    public var distanceTraveled: CLLocationDistance = 0
    
    
    /*
     Returns distance from user to end of step.
    */
    public var userDistanceToManeuverLocation: CLLocationDistance? = nil
    
    
    public var distanceRemaining: CLLocationDistance {
        return step.distance - distanceTraveled
    }
    
    public var fractionTraveled: Double {
        return distanceTraveled / step.distance
    }
    
    public var durationRemaining: TimeInterval {
        return (1 - fractionTraveled) * step.expectedTravelTime
    }
    
    public init(step: RouteStep) {
        self.step = step
    }
}
