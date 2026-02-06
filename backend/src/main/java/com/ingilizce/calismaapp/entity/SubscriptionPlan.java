package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "subscription_plans")
public class SubscriptionPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name; // e.g., "FREE", "PRO_MONTHLY", "IELTS_PREMIUM"

    @Column(nullable = false)
    private BigDecimal price;

    @Column(nullable = false)
    private String currency = "TRY";

    @Column(nullable = false)
    private Integer durationDays;

    @Column(columnDefinition = "TEXT")
    private String features; // JSON or comma-separated list of perks

    public SubscriptionPlan() {
    }

    public SubscriptionPlan(String name, BigDecimal price, Integer durationDays) {
        this.name = name;
        this.price = price;
        this.durationDays = durationDays;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public Integer getDurationDays() {
        return durationDays;
    }

    public void setDurationDays(Integer durationDays) {
        this.durationDays = durationDays;
    }

    public String getFeatures() {
        return features;
    }

    public void setFeatures(String features) {
        this.features = features;
    }
}
