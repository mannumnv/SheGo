package com.shego.kyc;

import com.shego.common.KycStatus;
import com.shego.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface KycDocumentRepository extends JpaRepository<KycDocument, UUID> {
    List<KycDocument> findByUser(User user);
    List<KycDocument> findByStatus(KycStatus status);
}
