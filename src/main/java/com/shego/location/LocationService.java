package com.shego.location;

import com.shego.exception.BusinessException;
import com.shego.ride.Ride;
import com.shego.ride.RideRepository;
import com.shego.user.CurrentUserService;
import com.shego.user.User;
import com.shego.user.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.List;
import java.util.UUID;

@Service
public class LocationService {
    private static final Duration LIVE_LOCATION_TTL = Duration.ofMinutes(30);
    private final RideLocationRepository locations;
    private final RideRepository rides;
    private final UserRepository users;
    private final SavedLocationRepository savedLocations;
    private final RecentLocationSearchRepository recentSearches;
    private final RideRouteSnapshotRepository routeSnapshots;
    private final DirectionsService directions;
    private final StringRedisTemplate redis;

    public LocationService(RideLocationRepository locations, RideRepository rides, UserRepository users,
                           SavedLocationRepository savedLocations, RecentLocationSearchRepository recentSearches,
                           RideRouteSnapshotRepository routeSnapshots, DirectionsService directions,
                           StringRedisTemplate redis) {
        this.locations = locations;
        this.rides = rides;
        this.users = users;
        this.savedLocations = savedLocations;
        this.recentSearches = recentSearches;
        this.routeSnapshots = routeSnapshots;
        this.directions = directions;
        this.redis = redis;
    }

    public RideLocation save(LocationDtos.LiveLocationMessage message) {
        RideLocation location = new RideLocation();
        location.setRide(rides.findById(message.rideId())
                .orElseThrow(() -> new BusinessException("Ride not found", HttpStatus.NOT_FOUND)));
        location.setUser(users.findById(message.userId())
                .orElseThrow(() -> new BusinessException("User not found", HttpStatus.NOT_FOUND)));
        location.setLatitude(message.latitude());
        location.setLongitude(message.longitude());
        location.setSpeedKmph(message.speedKmph());
        location.setBearing(message.bearing());
        redis.opsForValue().set("ride:live-location:" + message.rideId() + ":" + message.userId(),
                message.latitude() + "," + message.longitude() + "," + message.speedKmph() + "," + message.bearing(),
                LIVE_LOCATION_TTL);
        return locations.save(location);
    }

    public List<RideLocation> history(UUID rideId) {
        return locations.findByRideOrderByCreatedAtAsc(rides.findById(rideId)
                .orElseThrow(() -> new BusinessException("Ride not found", HttpStatus.NOT_FOUND)));
    }

    public List<LocationDtos.LocationResponse> saved(User user) {
        return savedLocations.findByUserOrderByUpdatedAtDesc(user).stream().map(LocationDtos.LocationResponse::from).toList();
    }

    public LocationDtos.LocationResponse saveLocation(User user, LocationDtos.SavedLocationRequest request) {
        SavedLocation location = new SavedLocation();
        location.setUser(user);
        location.setType(request.type() == null ? com.shego.common.SavedLocationType.OTHER : request.type());
        location.setLabel(required(request.label(), "Location label is required"));
        location.setAddress(required(request.address(), "Location address is required"));
        location.setLatitude(request.latitude());
        location.setLongitude(request.longitude());
        return LocationDtos.LocationResponse.from(savedLocations.save(location));
    }

    public List<LocationDtos.LocationResponse> recent(User user) {
        return recentSearches.findTop10ByUserOrderByCreatedAtDesc(user).stream().map(LocationDtos.LocationResponse::from).toList();
    }

    public LocationDtos.LocationResponse saveRecent(User user, LocationDtos.RecentLocationRequest request) {
        RecentLocationSearch location = new RecentLocationSearch();
        location.setUser(user);
        location.setQueryText(required(request.queryText(), "Search text is required"));
        location.setAddress(required(request.address(), "Location address is required"));
        location.setLatitude(request.latitude());
        location.setLongitude(request.longitude());
        return LocationDtos.LocationResponse.from(recentSearches.save(location));
    }

    public LocationDtos.DirectionsResponse route(LocationDtos.DirectionsRequest request) {
        return directions.route(request);
    }

    public RideRouteSnapshot snapshot(Ride ride, LocationDtos.DirectionsResponse route) {
        RideRouteSnapshot snapshot = routeSnapshots.findByRide(ride).orElseGet(RideRouteSnapshot::new);
        snapshot.setRide(ride);
        snapshot.setProvider(route.provider());
        snapshot.setDistanceKm(BigDecimal.valueOf(route.distanceKm()));
        snapshot.setEtaMinutes(route.etaMinutes());
        snapshot.setEncodedPolyline(route.encodedPolyline());
        snapshot.setRouteMetadataJson("{\"provider\":\"" + route.provider() + "\",\"points\":" + route.polylinePoints().size() + "}");
        return routeSnapshots.save(snapshot);
    }

    public LocationDtos.RouteSnapshotResponse routeSnapshot(UUID rideId) {
        Ride ride = rides.findById(rideId)
                .orElseThrow(() -> new BusinessException("Ride not found", HttpStatus.NOT_FOUND));
        return routeSnapshots.findByRide(ride)
                .map(LocationDtos.RouteSnapshotResponse::from)
                .orElseThrow(() -> new BusinessException("Ride route snapshot not found", HttpStatus.NOT_FOUND));
    }

    private String required(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new BusinessException(message);
        }
        return value.trim();
    }
}
