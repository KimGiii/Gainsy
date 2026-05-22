package com.healthcare.domain.diet.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;

import java.time.OffsetDateTime;

@Entity
@Table(name = "food_catalog")
@SQLRestriction("deleted_at IS NULL")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
@AllArgsConstructor
public class FoodCatalog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(name = "name_ko", length = 150)
    private String nameKo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private FoodCategory category;

    @Column(name = "calories_per_100g", nullable = false)
    private Double caloriesPer100g;

    @Column(name = "protein_per_100g")
    private Double proteinPer100g;

    @Column(name = "carbs_per_100g")
    private Double carbsPer100g;

    @Column(name = "fat_per_100g")
    private Double fatPer100g;

    @Column(name = "sugars_per_100g")
    private Double sugarsPer100g;

    @Column(name = "dietary_fiber_per_100g")
    private Double dietaryFiberPer100g;

    @Column(name = "saturated_fat_per_100g")
    private Double saturatedFatPer100g;

    @Column(name = "trans_fat_per_100g")
    private Double transFatPer100g;

    @Column(name = "cholesterol_per_100g_mg")
    private Double cholesterolPer100gMg;

    @Column(name = "sodium_per_100g_mg")
    private Double sodiumPer100gMg;

    @Column(name = "is_custom", nullable = false)
    private Boolean isCustom;

    @Column(name = "usage_count", nullable = false)
    @Builder.Default
    private Long usageCount = 0L;

    @Column(name = "created_by_user_id")
    private Long createdByUserId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    public void softDelete() {
        this.deletedAt = OffsetDateTime.now();
    }

    public void incrementUsage() {
        this.usageCount = (this.usageCount == null ? 0L : this.usageCount) + 1;
    }

    public void decrementUsage() {
        this.usageCount = Math.max((this.usageCount == null ? 0L : this.usageCount) - 1, 0L);
    }

    public enum FoodCategory {
        GRAIN, PROTEIN_SOURCE, VEGETABLE, FRUIT, DAIRY, FAT, BEVERAGE, PROCESSED, OTHER
    }
}
