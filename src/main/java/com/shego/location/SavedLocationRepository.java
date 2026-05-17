package com.shego.location;

import com.shego.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SavedLocationRepository extends JpaRepository<SavedLocation, UUID> {
    List<SavedLocation> findByUserOrderByUpdatedAtDesc(User user);
}
