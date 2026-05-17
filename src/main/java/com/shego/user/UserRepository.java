package com.shego.user;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.List;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    @EntityGraph(attributePaths = "roles")
    Optional<User> findByMobileNumber(String mobileNumber);

    @EntityGraph(attributePaths = "roles")
    Optional<User> findByEmail(String email);

    boolean existsByMobileNumber(String mobileNumber);

    @Query("""
            select distinct u
            from User u
            join u.roles r
            where r = :role
            """)
    List<User> findByRole(@Param("role") com.shego.common.Role role);

    @Query("""
            select count(u) > 0
            from User u
            join u.roles r
            where r = com.shego.common.Role.ADMIN
            """)
    boolean existsAdminUser();

    @Modifying
    @Query(value = "update users set account_status = 'ACTIVE', updated_at = now() where id = :id", nativeQuery = true)
    int activateUser(@Param("id") UUID id);
}
