package com.shego.location;

public interface DirectionsService {
    LocationDtos.DirectionsResponse route(LocationDtos.DirectionsRequest request);
}
