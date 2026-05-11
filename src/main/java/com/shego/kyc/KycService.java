package com.shego.kyc;

import com.shego.common.AccountStatus;
import com.shego.common.KycStatus;
import com.shego.driver.DriverProfileRepository;
import com.shego.exception.BusinessException;
import com.shego.rider.RiderProfileRepository;
import com.shego.user.User;
import com.shego.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class KycService {
    private static final Logger log = LoggerFactory.getLogger(KycService.class);

    private final KycDocumentRepository documents;
    private final RiderProfileRepository riders;
    private final DriverProfileRepository drivers;
    private final UserRepository users;

    public KycService(KycDocumentRepository documents, RiderProfileRepository riders, DriverProfileRepository drivers, UserRepository users) {
        this.documents = documents;
        this.riders = riders;
        this.drivers = drivers;
        this.users = users;
    }

    public KycDocument upload(User user, KycDtos.UploadRequest request) {
        KycDocument document = new KycDocument();
        document.setUser(user);
        document.setDocumentType(request.documentType());
        document.setPrivateStorageKey(request.privateStorageKey());
        document.setMaskedDocumentNumber(request.maskedDocumentNumber());
        return documents.save(document);
    }

    public List<KycDocument> status(User user) {
        return documents.findByUser(user);
    }

    public List<KycDocument> pending() {
        return documents.findByStatus(KycStatus.PENDING);
    }

    @Transactional
    public KycDocument approve(UUID id) {
        log.debug("KYC approve flow started: kycDocumentId={}", id);
        KycDocument document = documents.findById(id)
                .orElseThrow(() -> new BusinessException("KYC document not found", HttpStatus.NOT_FOUND));
        log.debug("KYC document found: kycDocumentId={}, userId={}, status={}, documentType={}",
                document.getId(), document.getUser().getId(), document.getStatus(), document.getDocumentType());
        document.setStatus(KycStatus.APPROVED);
        User user = document.getUser();
        user.setFemaleVerified(true);
        user.setAccountStatus(AccountStatus.ACTIVE);
        riders.findByUser(user).ifPresent(r -> {
            log.debug("Approving linked rider profile from KYC document: riderId={}", r.getId());
            r.setKycStatus(KycStatus.APPROVED);
            riders.save(r);
        });
        drivers.findByUser(user).ifPresent(d -> {
            log.debug("Approving linked driver KYC from KYC document: driverId={}", d.getId());
            d.setKycStatus(KycStatus.APPROVED);
            drivers.save(d);
        });
        users.save(user);
        var saved = documents.save(document);
        log.debug("KYC approve flow completed: kycDocumentId={}, status={}", saved.getId(), saved.getStatus());
        return saved;
    }

    @Transactional
    public KycDocument reject(UUID id, String reason) {
        log.debug("KYC reject flow started: kycDocumentId={}", id);
        KycDocument document = documents.findById(id)
                .orElseThrow(() -> new BusinessException("KYC document not found", HttpStatus.NOT_FOUND));
        document.setStatus(KycStatus.REJECTED);
        document.setRejectionReason(reason);
        var saved = documents.save(document);
        log.debug("KYC reject flow completed: kycDocumentId={}, status={}", saved.getId(), saved.getStatus());
        return saved;
    }
}
