package com.shego.location;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class LocalDirectionsServiceTest {
    @Test
    void routeReturnsMockProviderFareAndPolylineWhenGoogleKeyIsMissing() {
        LocalDirectionsService service = new LocalDirectionsService("");

        LocationDtos.DirectionsResponse response = service.route(new LocationDtos.DirectionsRequest(
                28.6139, 77.2090, 28.5355, 77.3910, "Connaught Place", "Noida Sector 18"));

        assertThat(response.provider()).isEqualTo("LOCAL_MOCK");
        assertThat(response.distanceKm()).isGreaterThan(0);
        assertThat(response.etaMinutes()).isGreaterThan(0);
        assertThat(response.encodedPolyline()).contains("|");
        assertThat(response.fareBreakdown().totalFare()).isPositive();
    }
}
