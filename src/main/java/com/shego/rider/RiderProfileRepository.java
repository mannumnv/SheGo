package com.shego.rider;

import com.shego.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RiderProfileRepository extends JpaRepository<RiderProfile, UUID> {
    Optional<RiderProfile> findByUser(User user);
    List<RiderProfile> findByRiderAgeLessThan(int age);
    List<RiderProfile> findByVerificationTypeAndKycStatus(com.shego.common.VerificationType verificationType, com.shego.common.KycStatus kycStatus);

    @Query("""
            select r
            from RiderProfile r
            join fetch r.user u
            where r.id = :id
            """)
    Optional<RiderProfile> findByIdWithUser(UUID id);

    @Query(value = """
            select
                rp.id as id,
                rp.user_id as userId,
                rp.kyc_status as kycStatus,
                u.account_status as accountStatus,
                rp.verification_type as verificationType
            from rider_profile rp
            join users u on rp.user_id = u.id
            where rp.id = :id
            """, nativeQuery = true)
    Optional<RiderApprovalRow> findApprovalRow(@Param("id") UUID id);

    @Modifying
    @Query(value = "update rider_profile set kyc_status = 'APPROVED', updated_at = now() where id = :id", nativeQuery = true)
    int approveRiderKyc(@Param("id") UUID id);

    interface RiderApprovalRow {
        UUID getId();
        UUID getUserId();
        String getKycStatus();
        String getAccountStatus();
        String getVerificationType();
    }
}
