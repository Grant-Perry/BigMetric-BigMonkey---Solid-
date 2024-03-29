////   newMapView.swift
////   BigMetric
////
////   Created by: Grant Perry on 1/10/24 at 5:13 PM
////     Modified: 
////
////  From: https://github.com/ludocourbin/SweatSpots/tree/31ea0e0fe56cf7db2285e42d6468ecccbeca5f37
////
//
//import CoreLocation
//import MapKit
//import SwiftUI
//
//struct newMapView: View {
//	@ObservedObject var mapViewModel = MapViewModel()
//	@StateObject var network = Network()
//	private let locationManager = CLLocationManager()
//	let geocoder = CLGocoder()
//
//	// Map properties
//	@State private var cameraPosition: MapCameraPosition = .userLocation(followsHeading: true, fallback: .region(.paris))
//	@State private var mapSelection: MKMapItem?
//	@Namespace private var locationSpace
//	@State private var viewingRegion: MKCoordinateRegion?
//
//	// Map Selection Detail Properties
//	@State private var showDetails: Bool = false
//	@State private var lookAroundScene: MKLookAroundScene?
//
//	// Direction properties
//	@State private var showConfirmationDialog = false
//
//	var body: some View {
//		ZStack {
//			Map(position: $cameraPosition, selection: $mapSelection, scope: locationSpace) {
//				ForEach(mapViewModel.searchResults, id: \.self) { mapItem in
//					let placemark = mapItem.placemark
//					Marker(placemark.name ?? "Place", coordinate: placemark.coordinate)
//						.tint(.blue)
//				}
//				UserAnnotation()
//			}
//			.mapStyle(.standard(elevation: .realistic))
//			.onMapCameraChange { ctx in
//				viewingRegion = ctx.region
//			}
//			.mapControls {
//				MapUserLocationButton()
//				MapCompass()
//				MapScaleView()
//			}
//			.toolbarBackground(.visible, for: .navigationBar)
//			.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
//			.sheet(isPresented: $showDetails, content: {
//				MapDetailsView(
//					lookAroundScene: $lookAroundScene,
//					showDetails: $showDetails,
//					mapSelection: $mapSelection,
//					showConfirmationDialog: $showConfirmationDialog
//				)
//			})
//			.onChange(of: mapSelection) { _, newValue in
//				guard network.connected else {
//					showConfirmationDialog = true
//					return
//				}
//				showDetails = newValue != nil
//				fetchLookAroundPreview()
//			}
//			.onAppear {
//				locationManager.requestWhenInUseAuthorization()
//			}
//			VStack {
//				Button(action: {
//					mapViewModel.searchSpots(viewingRegion: viewingRegion)
//				}) {
//					Text("Search this area")
//						.foregroundColor(.blue)
//						.padding(.horizontal, 16)
//						.padding(.vertical, 8)
//						.background(Color.white)
//						.cornerRadius(8)
//						.shadow(radius: 10)
//				}
//				.padding(.top, 16)
//
//				Spacer()
//			}
//		}
//		.confirmationDialog("Get Directions", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
//			DirectionsConfirmationDialogButtons(destinationCoordinate: mapSelection?.placemark.coordinate)
//		}
//	}
//
//	func fetchLookAroundPreview() {
//		if let mapSelection = mapSelection {
//			lookAroundScene = nil
//			Task.detached(priority: .background) {
//				do {
//					let latitude = mapSelection.placemark.coordinate.latitude
//					let longitude = mapSelection.placemark.coordinate.longitude
//					let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//
//					let request = MKLookAroundSceneRequest(coordinate: coordinate)
//					let scene = try await request.scene
//					DispatchQueue.main.async {
//						self.lookAroundScene = scene
//					}
//				} catch {
//					print("Failed to fetch Look Around preview: \(error.localizedDescription)")
//				}
//			}
//		}
//	}
//}
