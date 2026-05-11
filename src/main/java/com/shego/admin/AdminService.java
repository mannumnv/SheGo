package com.shego.admin;

import com.shego.driver.DriverProfileRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AdminService {
    private static final Logger log = LoggerFactory.getLogger(AdminService.class);

    private final DriverProfileRepository driverProfiles;

    public AdminService(DriverProfileRepository driverProfiles) {
        this.driverProfiles = driverProfiles;
    }

    public List<AdminDtos.PendingDriverVerificationResponse> pendingDriverVerifications() {
        log.debug("AdminService pending driver verification flow started");
        var pendingRows = driverProfiles.findPendingVerificationRows();
        log.debug("Pending driver repository result count: {}", pendingRows.size());
        log.debug("Pending driver DTO mapping started");
        var response = pendingRows.stream()
                .map(AdminDtos.PendingDriverVerificationResponse::from)
                .toList();
        log.debug("Pending driver DTO mapping completed: {}", response.size());
        return response;
    }
}
