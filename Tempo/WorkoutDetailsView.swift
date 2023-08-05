//
//  WorkoutDetailsView.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/2/23.
//

import HealthKit
import MapKit
import SwiftUI

struct MapFoo: UIViewRepresentable {
    
    private let spanPadding = 0.002
    
    let route: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        
        guard !route.isEmpty else { return }
        
        let minLatitude = route.min(by: { $0.latitude < $1.latitude })!.latitude
        let maxLatitude = route.max(by: { $0.latitude < $1.latitude })!.latitude
        let minLongitude = route.min(by: { $0.longitude < $1.longitude })!.longitude
        let maxLongitude = route.max(by: { $0.longitude < $1.longitude })!.longitude
        let span = MKCoordinateSpan(
            latitudeDelta: maxLatitude - minLatitude + spanPadding,
            longitudeDelta: maxLongitude - minLongitude + spanPadding
        )
        
        let center = CLLocationCoordinate2D(
            latitude: (maxLatitude - span.latitudeDelta / 2) + spanPadding / 2,
            longitude: (maxLongitude - span.longitudeDelta / 2) + spanPadding / 2
        )
                
        mapView.region = .init(center: center, span: span)
        
        let polyline = MKPolyline(coordinates: route, count: route.count)
        mapView.addOverlay(polyline)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
}

extension MapFoo {
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let overlay = overlay as? MKPolyline else { return MKOverlayRenderer() }
            
            let renderer = MKPolylineRenderer(polyline: overlay)
            renderer.strokeColor = .red
            renderer.lineWidth = 5
            
            return renderer
        }
    }
    
}

struct WorkoutDetailsView: View {

    let workout: HKWorkout
    
    @Environment(\.workoutRoute) private var workoutRoute
    
    @State private var route: [CLLocation]?

    var body: some View {
        VStack {
            Text("Morning Run")
                .font(.title)
                .padding(.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let route {
                MapFoo(route: route.map(\.coordinate))
                    .aspectRatio(1.5, contentMode: .fit)
            }

            Section {

                Grid(horizontalSpacing: 80, verticalSpacing: 20) {
                    GridRow {
                        if let distance = workout.totalDistanceWalkingRunning {
                            VStack {
                                Text("Distance")
                                    .font(.caption)
                                Text(distance.formatted(.measurement(width: .abbreviated)))
                                    .font(.headline)
                            }
                        }

                        if let speed = workout.averageRunningSpeed {
                            VStack {
                                Text("Avg Pace")
                                    .font(.caption)
                                Text(speed.formatted(.measurement(width: .abbreviated)))
                                    .font(.headline)
                            }
                        }
                    }

                    GridRow {
                        VStack {
                            Text("Moving Time")
                                .font(.caption)
                            Text(workout.totalTime.formatted(.measurement(width: .abbreviated)))
                                .font(.headline)
                        }

                        VStack {
                            Text("Elevation Gain")
                                .font(.caption)
                            Text("???")
                                .font(.headline)
                        }
                    }

                    GridRow {
                        VStack {
                            Text("Avg Power")
                                .font(.caption)
                            Text("221 W")
                                .font(.headline)
                        }

                        if let heartRate = workout.averageHeartRate {
                            VStack {
                                Text("Avg Heart Rate")
                                    .font(.caption)
                                Text(heartRate.formatted(.measurement(width: .abbreviated)))
                                    .font(.headline)
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal)
        .task {
            do {
                route = try await workoutRoute(workout: workout)
            } catch {
                print("Failed to get workout route: \(error)")
            }
        }
    }
}

private extension HKWorkout {

    var totalDistanceWalkingRunning: Measurement<UnitLength>? {
        statistics(for: .init(.distanceWalkingRunning))?
            .sumQuantity()
            .map {
                Measurement(
                    value: $0.doubleValue(for: .meter()),
                    unit: UnitLength.meters)
            }
    }

    var averageRunningSpeed: Measurement<UnitSpeed>? {
        guard let distance = totalDistanceWalkingRunning else { return nil }

        return Measurement(value: distance.converted(to: .meters).value / totalTime.converted(to: .seconds).value, unit: UnitSpeed.metersPerSecond)

//        statistics(for: .init(.runningSpeed))?
//            .averageQuantity()
//            .map {
//                Measurement(
//                    value: $0.doubleValue(for: .meter().unitDivided(by: .second())),
//                    unit: UnitSpeed.metersPerSecond)
//            }
    }

    var totalTime: Measurement<UnitDuration> {
        Measurement(value: duration, unit: UnitDuration.seconds)
    }

    var averageHeartRate: Measurement<UnitFrequency>? {
        statistics(for: .init(.heartRate))?
            .averageQuantity()
            .map {
                Measurement(
                    value: $0.doubleValue(for: .count().unitDivided(by: .second())),
                    unit: UnitFrequency(symbol: "bpm"))
            }
    }

}

//struct WorkoutDetailsView_Previews: PreviewProvider {
//    static var previews: some View {
//        WorkoutDetailsView(workout: .init)
//    }
//}
