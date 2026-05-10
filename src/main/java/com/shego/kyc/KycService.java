package com.shego.kyc;

import com.shego.common.AccountStatus;
import com.shego.common.KycStatus;
import com.shego.driver.DriverProfileRepository;
import com.shego.rider.RiderProfileRepository;
import com.shego.user.User;
import com.shego.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class KycService {
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
        KycDocument document = documents.findById(id).orElseThrow();
        document.setStatus(KycStatus.APPROVED);
        User user = document.getUser();
        user.setFemaleVerified(true);
        user.setAccountStatus(AccountStatus.ACTIVE);
        riders.findByUser(user).ifPresent(r -> {
            r.setKycStatus(KycStatus.APPROVED);
            riders.save(r);
        });
        drivers.findByUser(user).ifPresent(d -> {
            d.setKycStatus(KycStatus.APPROVED);
            drivers.save(d);
        });
        users.save(user);
        return documents.save(document);
    }

    public KycDocument reject(UUID id, String reason) {
        KycDocument document = documents.findById(id).orElseThrow();
        document.setStatus(KycStatus.REJECTED);
        document.setRejectionReason(reason);
        return documents.save(document);
    }
}
