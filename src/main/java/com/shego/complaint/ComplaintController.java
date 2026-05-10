package com.shego.complaint;

import com.shego.common.ApiResponse;
import com.shego.common.ComplaintStatus;
import com.shego.ride.RideRepository;
import com.shego.user.CurrentUserService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class ComplaintController {
    private final ComplaintRepository complaints;
    private final RideRepository rides;
    private final CurrentUserService currentUserService;

    public ComplaintController(ComplaintRepository complaints, RideRepository rides, CurrentUserService currentUserService) {
        this.complaints = complaints;
        this.rides = rides;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/complaints")
    ApiResponse<Complaint> create(@RequestBody ComplaintDtos.ComplaintRequest request) {
        Complaint complaint = new Complaint();
        complaint.setRaisedBy(currentUserService.current());
        complaint.setRide(request.rideId() == null ? null : rides.findById(request.rideId()).orElseThrow());
        complaint.setCategory(request.category());
        complaint.setDescription(request.description());
        return ApiResponse.ok("Complaint raised", complaints.save(complaint));
    }

    @GetMapping("/api/complaints/me")
    ApiResponse<List<Complaint>> mine() {
        return ApiResponse.ok("My complaints", complaints.findByRaisedByOrderByCreatedAtDesc(currentUserService.current()));
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @GetMapping("/api/admin/complaints")
    ApiResponse<List<Complaint>> all() {
        return ApiResponse.ok("Complaints", complaints.findAll());
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @PostMapping("/api/admin/complaints/{id}/resolve")
    ApiResponse<Complaint> resolve(@PathVariable UUID id, @RequestBody ComplaintDtos.ResolveRequest request) {
        Complaint complaint = complaints.findById(id).orElseThrow();
        complaint.setStatus(ComplaintStatus.RESOLVED);
        complaint.setResolution(request.resolution());
        return ApiResponse.ok("Complaint resolved", complaints.save(complaint));
    }
}
