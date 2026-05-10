package com.shego.location;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

@Controller
public class LocationWebSocketController {
    private final LocationService locationService;

    public LocationWebSocketController(LocationService locationService) {
        this.locationService = locationService;
    }

    @MessageMapping("/location/update")
    @SendTo("/topic/rides/location")
    public LocationDtos.LiveLocationMessage location(LocationDtos.LiveLocationMessage message) {
        locationService.save(message);
        return message;
    }
}
