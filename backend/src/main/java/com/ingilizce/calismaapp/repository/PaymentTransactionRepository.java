package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.PaymentTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, Long> {
    Optional<PaymentTransaction> findByTransactionId(String transactionId);

    @Query("""
            SELECT pt
            FROM PaymentTransaction pt
            JOIN FETCH pt.user
            JOIN FETCH pt.plan
            WHERE pt.transactionId = :transactionId
            """)
    Optional<PaymentTransaction> findByTransactionIdWithUserAndPlan(@Param("transactionId") String transactionId);
}
