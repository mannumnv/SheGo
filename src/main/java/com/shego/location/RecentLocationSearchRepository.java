package com.shego.location;

import com.shego.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RecentLocationSearchRepository extends JpaRepository<RecentLocationSearch, UUID> {
    List<RecentLocationSearch> findTop10ByUserOrderByCreatedAtDesc(User user);
}
